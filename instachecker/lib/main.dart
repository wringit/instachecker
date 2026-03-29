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
import 'background_search.dart';
import 'test_search.dart';
import 'home_screen.dart'; 

void main() {
  // Critical for background processes and plugins
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initializing HomeWidget global settings for your future widget
    HomeWidget.setAppGroupId("group.homeScreenApp");

    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'InstaChecker',
      
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), 
        primaryColor: const Color(0xFF1E293B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B), 
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      //  home: const FactCheckTestPage(), 

      // We go straight to your functional home screen.
      // No need for MyHomePage anymore!
      home: const HomeScreen(), 
    );
  }
}