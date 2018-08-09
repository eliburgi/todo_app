import 'package:flutter/material.dart';
import 'package:todo_app/home_page.dart';
import 'package:todo_app/strings.dart';
import 'package:todo_app/styles.dart';
import 'package:todo_app/todo.dart';

void main() async {
  await TodoStore.create(
      persistor: FileTodoStorePersistor('todo_app.json'),
  );
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/empty': (context) => EmptyHomePage(),
        '/data': (context) => DataHomePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

