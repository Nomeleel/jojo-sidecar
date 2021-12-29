import 'package:flutter/material.dart';

import 'clean/clean_page.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JoJo Sidecar',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const CleanPage(),
    );
  }
}