import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'result_screen.dart'; // <--- Add this line!
import 'dart:async';
import 'dart:convert';
import 'package:html/parser.dart' show parse;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:dart_sentiment/dart_sentiment.dart';
import 'result_screen.dart'; 
import 'home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // smooth gui appearance
      title: 'InstaChecker',
      theme: ThemeData(
        // matching your navy theme globally
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0A0E21),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
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

  void _incrementCounter() async{
    setState(() {
      _counter++;
    });

    // save widget data
    String data = "Count = $_counter";
    await HomeWidget.saveWidgetData(dataKey, data);

    // updata widget data
    await HomeWidget.updateWidget(
      iOSName: iOSWidgetName,
      androidName: androidWidgetName
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // keep centered
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            const Icon(Icons.analytics_outlined, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text('Welcome to InstaChecker', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            
            // "Go to Results" button
            const SizedBox(height: 30), // spacing
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(
                      username: "test_user",
                      score: 0.5,
                      profilePic: "https://i.pravatar.cc/150?u=test",
                      status: "Pending",
                      reason: "This is a manual test from the home page.",
                      sources: ["https://google.com"],
                    ),
                  ),
                );
              },
              child: const Text('Test Results Page'),
            ),
          ],
        ),
      ),
    );
  }
}