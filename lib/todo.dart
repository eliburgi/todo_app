import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todo_app/animated_checkbox.dart';
import 'package:todo_app/animated_text.dart';
import 'package:todo_app/styles.dart';
import 'package:todo_app/utils.dart';
import 'dart:convert';

// models
class Todo {
  Todo._(this.id, this.title, {this.completed = false});

  final int id;
  final String title;
  final bool completed;

  Todo _toggle() => Todo._(id, title, completed: !completed);

  @override
  bool operator ==(other) {
    if (other is Todo) return id == other.id;
    return false;
  }

  Todo._fromJson(Map<String, dynamic> json)
      : this._(
          json['id'],
          json['title'],
          completed: json['completed'],
        );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
      };
}

class TodoState {
  TodoState({
    @required this.today,
    @required this.todos,
    @required this.nextId,
  });

  final DateTime today;
  final List<Todo> todos;
  final int nextId;

  TodoState copyWith({
    DateTime today,
    List<Todo> todos,
    int nextId,
  }) =>
      TodoState(
        today: today ?? this.today,
        todos: todos ?? this.todos,
        nextId: nextId ?? this.nextId,
      );

  TodoState.fromJson(Map<String, dynamic> json)
      : this(
          today: DateTime.parse(json['today']),
          todos: (json['todos'] as List<dynamic>)
              .map((todoJson) => Todo._fromJson(todoJson))
              .toList(),
          nextId: json['nextId'],
        );

  Map<String, dynamic> toJson() => {
        'today': today.toIso8601String(),
        'todos': todos,
        'nextId': nextId,
      };
}

// store
class TodoStore {
  static TodoStore _instance;

  // should be called before app startup (in main method)
  static Future<void> create({TodoStorePersistor persistor}) async {
    TodoState initialState;
    try {
      if (persistor == null) {
        throw Exception("Start with default state (enters catch block).");
      }
      // try loading a previously persisted state
      initialState = await persistor.revive();
    } catch (error) {
      // if no persisted state exists, start with a default state
      initialState = TodoState(
        today: DateTime.now(),
        todos: [],
        nextId: 0,
      );
    }
    // create a store with the initial state
    _instance = TodoStore._(initialState, persistor);
  }

  TodoStore._(this._state, [this._persistor]);

  factory TodoStore() => _instance;

  TodoState _state;
  List<VoidCallback> _listeners = [];
  TodoStorePersistor _persistor;

  TodoState get state {
    // check if the state is up-to-date (for today)
    if (_isNewDay()) {
      // a new day has begun, so delete all to-dos from the old day
      _setState(
        _state.copyWith(
          today: DateTime.now(),
          todos: [],
          nextId: 0,
        ),
      );
    }
    return _state;
  }

  void addTodo(String title) {
    if (_isNewDay()) {
      // a new day has begun, so delete all to-dos from the old day
      _setState(
        _state.copyWith(
          today: DateTime.now(),
          todos: [],
          nextId: 0,
        ),
      );
    }
    // add the new to-do to the list
    var todo = Todo._(_state.nextId, title);
    _setState(
      _state.copyWith(
        todos: _state.todos.toList()..add(todo),
        nextId: _state.nextId + 1,
      ),
    );
  }

  void toggleTodo(Todo todo) {
    _setState(
      _state.copyWith(
        todos: _state.todos.map((t) => t == todo ? t._toggle() : t).toList(),
      ),
    );
  }

  void removeTodo(Todo todo) {
    _setState(_state.copyWith(
      todos: _state.todos.toList()..remove(todo),
    ));
  }

  VoidCallback register(VoidCallback listener) {
    _listeners.add(listener);
    listener();
    return () {
      _listeners.remove(listener);
    };
  }

  void _setState(TodoState state) {
    _state = state;
    _notifyListeners();
    _persistState();
  }

  _notifyListeners() {
    _listeners.forEach((listener) => listener());
  }

  _persistState() {
    if (_persistor == null) return;
    // a real world application would handle any error here and
    // undo the failed state changes ...
    _persistor.persist(_state).then((obj) {
      print('State successfully persisted!');
    }, onError: (error) {
      print('Error persisting the state: $error');
      throw error;
    });
  }

  bool _isNewDay() {
    var currentDate = DateTime.now();
    return currentDate.day != _state.today.day ||
        currentDate.month != _state.today.month ||
        currentDate.year != _state.today.year;
  }
}

// persistence
abstract class TodoStorePersistor {
  Future<dynamic> persist(TodoState state);

  Future<TodoState> revive();
}

class FileTodoStorePersistor implements TodoStorePersistor {
  FileTodoStorePersistor(this._fileName);

  final String _fileName;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  @override
  Future<File> persist(TodoState state) async {
    final file = await _localFile;
    return file.writeAsString(
      json.encode(state),
      flush: true,
    );
  }

  @override
  Future<TodoState> revive() async {
    try {
      final file = await _localFile;
      final fileJson = await file.readAsString();
      return TodoState.fromJson(json.decode(fileJson));
    } catch (error) {
      print(error);
      return error;
    }
  }
}

// widgets
typedef void TodoTapCallback(Todo todo);

class AnimatedTodoList extends StatefulWidget {
  AnimatedTodoList({
    Key key,
    @required this.todos,
    @required this.onTap,
    this.addAnimDuration = const Duration(milliseconds: 300),
    this.removeAnimDuration = const Duration(milliseconds: 600),
  }) : super(key: key);

  final List<Todo> todos;
  final TodoTapCallback onTap;
  final Duration addAnimDuration;
  final Duration removeAnimDuration;

  @override
  AnimatedTodoListState createState() => AnimatedTodoListState();
}

class AnimatedTodoListState extends State<AnimatedTodoList> {
  final _animatedList = GlobalKey<AnimatedListState>();

  void insertItem(int index) {
    _animatedList.currentState.insertItem(
      index,
      duration: widget.addAnimDuration,
    );
  }

  void removeItem(int index) {
    final Todo removedTodo = widget.todos[index];
    _animatedList.currentState.removeItem(
      index,
      (context, animation) =>
          _buildRemovedItem(removedTodo, context, animation),
      duration: widget.removeAnimDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _animatedList,
      itemBuilder: (context, index, animation) => _AnimatedTodoListItem(
            todo: widget.todos[index],
            onTap: widget.onTap,
            animation: animation,
          ),
      initialItemCount: widget.todos.length,
      physics: BouncingScrollPhysics(),
    );
  }

  Widget _buildRemovedItem(
      Todo todo, BuildContext context, Animation<double> animation) {
    // the argument animation goes from one to zero
    // (passed that way from AnimatedList, nothing we can do here)
    // reversing makes it go from zero to one, which is easier to work with
    final fromZeroToOneAnim = ReverseAnimation(animation);
    return Column(
      children: <Widget>[
        FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(
              parent: fromZeroToOneAnim,
              curve: Interval(
                0.8,
                1.0,
                curve: Curves.easeInOut,
              ),
            ),
          ),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Padding(
                  padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
                  child: Row(
                    children: <Widget>[
                      OneShotCheckbox(
                        animation: CurvedAnimation(
                          parent: fromZeroToOneAnim,
                          curve: Curves.easeOut,
                        ),
                      ),
                      Margin(
                        right: 16.0,
                      ),
                      Expanded(
                        child: OneShotAnimatedText(
                          animation: CurvedAnimation(
                            parent: fromZeroToOneAnim,
                            curve: Curves.decelerate,
                          ),
                          text: Text(
                            todo.title,
                            style: textStyleBody,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
        /*AnimatedBuilder(
          animation: animation,
          builder: (context, widget) => HorizontalLine(
                width: animation.value * 100,
                color: separatorColor,
                height: 1.5,
              ),
        ),*/
      ],
    );
  }
}

class _AnimatedTodoListItem extends StatelessWidget {
  _AnimatedTodoListItem({
    @required this.todo,
    @required this.onTap,
    @required this.animation,
  });

  final Todo todo;
  final TodoTapCallback onTap;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curvedAnim = CurvedAnimation(
      parent: animation,
      curve: Overshoot(),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(todo),
      child: Column(
        children: <Widget>[
          AnimatedBuilder(
            animation: curvedAnim,
            builder: (context, child) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      curvedAnim.value * 24.0, 16.0, 24.0, 16.0),
                  child: Row(
                    children: <Widget>[
                      /*AnimatedCheckBox(
                        value: todo.completed,
                        onValueChanged: (checked) => onTap(todo),
                      ),*/
                      OneShotCheckbox(
                        animation: Tween<double>(begin: 0.0, end: 0.0)
                            .animate(animation),
                      ),
                      Margin(
                        right: 16.0,
                      ),
                      Expanded(
                        child: Text(
                          todo.title,
                          style: textStyleBody,
                          maxLines: 2,
                          softWrap: true,
                        ),
                      ),
                      /*AnimatedText(
                        value: todo.completed,
                        text: Text(
                          todo.title,
                          style: textStyleBody,
                        ),
                      ),*/
                    ],
                  ),
                ),
          ),
          /*AnimatedBuilder(
            animation: animation,
            builder: (context, widget) => HorizontalLine(
                  width: animation.value * 100,
                  color: separatorColor,
                  height: 1.5,
                ),
          ),*/
        ],
      ),
    );
  }
}

/*class TodoList extends StatelessWidget {
  TodoList({@required this.todos, @required this.onTodoClicked});

  final List<Todo> todos;
  final TodoTapCallback onTodoClicked;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) => _buildRow(index),
      itemCount: todos.length,
    );
  }

  _buildRow(int index) {
    final todo = todos[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTodoClicked(todo),
      child: Column(
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Row(
              children: <Widget>[
                AnimatedCheckBox(
                  value: todo.completed,
                  onValueChanged: (checked) => onTodoClicked(todo),
                ),
                Margin(
                  right: 16.0,
                ),
                AnimatedText(
                  value: todo.completed,
                  text: Text(
                    todo.title,
                    style: textStyleBody,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 80.0),
            child: HorizontalLine(
              color: separatorColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}*/
