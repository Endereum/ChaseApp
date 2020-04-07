import 'package:flutter/material.dart';
import 'package:chaseclient/screens/web.dart';

void main() async {
  // Ensure the Initialization
  WidgetsFlutterBinding.ensureInitialized();

  runApp(new ChaseClientApp());
}

class ChaseClientApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
            primaryColor: Colors.blueGrey, accentColor: Colors.blueAccent),
        title: 'Chase Auto Parts',
        debugShowCheckedModeBanner: false,
        home: Container(
            margin: const EdgeInsets.only(top: 0.0),
            child: SafeArea(
              top: true,
              child: WebContainer("https://cc.endereum.com"),
            )));
  }
}
