import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'home_screen.dart'; // This is where the magic happens now

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures home_widget and sharing plugins start correctly
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Initializing HomeWidget global settings
    HomeWidget.setAppGroupId("group.homeScreenApp");

    return MaterialApp(
      debugShowCheckedModeBanner: false, // smooth gui appearance
      title: 'InstaChecker',
      
      // Global Theme - Matching your navy/dark blue design
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Your standard background
        primaryColor: const Color(0xFF1E293B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B), // Card colors
        ),
        useMaterial3: true,
      ),

      // Landing straight onto your functional home screen
      home: const HomeScreen(), 
    );
  }
}