import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import the file I gave you previously

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InstaChecker',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      // This launches the screen that handles sharing and history
      home: const HomeScreen(), 
    );
  }
}

