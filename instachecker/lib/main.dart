import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:home_widget/home_widget.dart';
import 'result_screen.dart'; // <--- Add this line!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaChecker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ResultScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // home widget stuff
  String appGroupId = "group.homeScreenApp";
  String iOSWidgetName = "MyHomeWidget";
  String androidWidgetName = "MyHomeWidget";
  String dataKey = "text_from_flutter_app";

  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId(appGroupId);
  }

  void _incrementCounter() async {
    setState(() {
      _counter++;
    });
    String data = "Count = $_counter";
    await HomeWidget.saveWidgetData(dataKey, data);
    await HomeWidget.updateWidget(
      iOSName: iOSWidgetName,
      androidName: androidWidgetName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // 1. This keeps everything in the middle of the screen
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            // 2. This is your "Go to Results" button
            const SizedBox(height: 30), // Spacing
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResultScreen()),
                );
              },
              child: const Text('Go to Results Page'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}