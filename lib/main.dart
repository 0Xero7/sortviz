import 'package:flutter/material.dart';
import 'package:sortviz/testpage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoSort',
      theme: ThemeData.dark(),
      home: TestPage(),
    );
  }
}