import 'dart:async';
import 'package:todo_app/strings.dart';
import 'package:todo_app/todo.dart';
import 'utils.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/animated_add_button.dart';
import 'package:todo_app/styles.dart';
import 'package:intl/intl.dart' show DateFormat;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TodoStore _todoStore;
  VoidCallback _unsubscribeFromStore;

  @override
  void initState() {
    super.initState();
    _todoStore = TodoStore();
    _unsubscribeFromStore = _todoStore.register(() {
      if (_todoStore.state.todos.isNotEmpty) {
        _navigateToPage('/data');
      } else {
        _navigateToPage('/empty');
      }
    });
  }

  @override
  void dispose() {
    _unsubscribeFromStore();
    super.dispose();
  }

  _navigateToPage(String route) {
    // calling Navigator.pushReplacement(...) in initState() resulted in an error
    // delaying the method call by some minimal amount of time fixes this problem
    Timer(Duration(microseconds: 1), () {
      Navigator.pushReplacementNamed(
          context,
          route
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // HomePage widget won´t render anything particular, it´s just here to decide
    // what page to navigate to based on today´s to-do list -> see initState()
    return Container();
  }
}

class EmptyHomePage extends StatefulWidget {
  @override
  _EmptyHomePageState createState() => _EmptyHomePageState();
}

class _EmptyHomePageState extends State<EmptyHomePage> {
  TodoStore _todoStore;
  VoidCallback _unsubscribeFromStore;
  DateTime _today;

  @override
  void initState() {
    super.initState();
    _todoStore = TodoStore();
    _unsubscribeFromStore = _todoStore.register(_onStateChanged);
  }

  @override
  void dispose() {
    _unsubscribeFromStore();
    super.dispose();
  }

  void _onStateChanged() {
    _today = _todoStore.state.today;
  }

  void _onAddTodoClicked(String title) {
    _todoStore.addTodo(title);
    // Navigator.pushReplacement(...) does not work with hero animations
    // therefore push and pop need to be used if hero animation should be played
    Navigator.pushNamed(context, '/data');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Center(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  _buildHeader(),
                  _buildFooter(),
                ],
              ),
              _buildAddButton(),
            ],
          ),
        ),
      ),
    );
  }

  _buildHeader() {
    return Expanded(
      flex: 1,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            buildHeroText(
              tag: 'titleHero',
              text: Text(appTitle, style: textStyleTitle),
            ),
            Margin(top: 16.0),
            buildHeroText(
              tag: 'dayTitleHero',
              text: Text(
                _formatDate(_today),
                style: textStyleSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildFooter() {
    return Expanded(
      flex: 1,
      child: Container(
        color: colorPrimarySuperLight,
        child: Center(
          child: Text(
            emptyHomePageDescription,
            style: textStyleSecondary,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  _buildAddButton() {
    return Center(
      child: Hero(
        tag: 'addButtonHero',
        child: AnimatedAddButton(
          onSubmit: _onAddTodoClicked,
        ),
      ),
    );
  }
}

class DataHomePage extends StatefulWidget {
  @override
  __DataHomePageState createState() => __DataHomePageState();
}

class __DataHomePageState extends State<DataHomePage> {
  static const addAnimDuration = const Duration(milliseconds: 150);
  static const removeAnimDuration = const Duration(milliseconds: 600);

  final _animatedTodoList = GlobalKey<AnimatedTodoListState>();
  TodoStore _todoStore;
  VoidCallback _unsubscribeFromStore;
  List<Todo> _todos;
  DateTime _today;

  @override
  void initState() {
    super.initState();
    // register at store
    _todoStore = TodoStore();
    _unsubscribeFromStore = _todoStore.register(_onStateChanged);
  }

  @override
  void dispose() {
    _unsubscribeFromStore();
    super.dispose();
  }

  _onTodoClicked(Todo todo) {
    _todoStore.removeTodo(todo);
  }

  _addTodo(String title) {
    _todoStore.addTodo(title);
  }

  _onStateChanged() {
    _animateTodoListChange(_todoStore.state.todos);
    setState(() {
      _todos = _todoStore.state.todos;
      _today = _todoStore.state.today;

      if (_todos.isEmpty) {
        // there are no more to-dos, so navigate to empty page
        // delay this navigation in order to finish rendering any
        // to-do list remove animations
        Timer(
          removeAnimDuration,
          _navigateToEmptyPage,
        );
      }
    });
  }
  
  _navigateToEmptyPage() {
    if(Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.popAndPushNamed(context, '/empty');
    }
  }

  _animateTodoListChange(List<Todo> newTodos) {
    if (_todos == null) return;

    if (newTodos.length > _todos.length) {
      // a new to-do item was added to the list
      _animateAddItem(newTodos.last);
    } else if (newTodos.length < _todos.length) {
      // a to-do item was removed from the list
      final removedTodo = _todos.firstWhere((t) => !newTodos.contains(t));
      _animateRemoveItem(removedTodo);
    }
  }

  _animateAddItem(Todo todo) {
    _animatedTodoList.currentState.insertItem(_todos.length);
  }

  _animateRemoveItem(Todo todo) {
    final index = _todos.indexOf(todo);
    _animatedTodoList.currentState.removeItem(index);
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope prevents the device specific back button
    // from popping the navigation stack
    // https://stackoverflow.com/questions/45916658/de-activate-system-back-button-in-flutter-app-toddler-navigation
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildHeader(),
                  _buildHeaderSeparator(),
                  _buildDayTitle(),
                  _buildTodoList(),
                ],
              ),
              _buildAddButton(),
            ],
          ),
        ),
      ),
    );
  }

  _buildHeader() {
    return Container(
      width: double.infinity,
      height: 90.0,
      child: Center(
        child: buildHeroText(
          tag: 'titleHero',
          text: Text(appTitle, style: textStyleTitle),
        ),
      ),
    );
  }

  _buildHeaderSeparator() {
    return HorizontalLine(
      color: separatorColor,
      height: 1.5,
    );
  }

  _buildDayTitle() {
    return Container(
      padding: const EdgeInsets.only(
          top: 24.0, right: 24.0, bottom: 8.0, left: 24.0),
      child: buildHeroText(
        tag: 'dayTitleHero',
        text: Text(
          _formatDate(_today),
          style: textStyleSubtitle,
        ),
      ),
    );
  }

  _buildTodoList() {
    // when using a ListView inside a Column it is necessary to wrap
    // the ListView inside a Expanded widget.
    // Otherwise, flutter will complain that it can´t calculate the
    // list´s size on screen.
    return Expanded(
      child: AnimatedTodoList(
        key: _animatedTodoList,
        todos: _todos,
        onTap: _onTodoClicked,
        addAnimDuration: addAnimDuration,
        removeAnimDuration: removeAnimDuration,
      ),
    );
  }

  _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Hero(
          tag: 'addButtonHero',
          child: AnimatedAddButton(
            onSubmit: _addTodo,
          ),
        ),
      ),
    );
  }
}

final _dateFormat = DateFormat('EEEE dd LLL yyyy');

String _formatDate(DateTime date) {
  return _dateFormat.format(date);
}
