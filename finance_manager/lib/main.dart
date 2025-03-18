import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   title: 'Flutter Demo',
    //   theme: ThemeData(
    //     colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    //   ),
    //   home: const MyHomePage(title: 'Flutter Demo Home Page'),
    // );
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: DefaultTabController(length: 2, child: Scaffold(
        appBar: AppBar(
          title: Center(child: Text('CashFlow')),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Logs'),
              Tab(text: 'Graphs'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Center(child: Text('Tab 1 Content')),
            LogsPage(title: 'Logs'),
            GraphsPage(title: 'Graphs'),
          ],
        ),
      )),
    );
  }
}

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, required this.title});

  final String title;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('Logs');
  }
}



class GraphsPage extends StatefulWidget {
  const GraphsPage({super.key, required this.title});

  final String title;

  @override
  State<GraphsPage> createState() => _GraphsPageState();
}

class _GraphsPageState extends State<GraphsPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('Greetings from Graphs');
  }
}
