import 'package:flutter/material.dart';
import 'home_screen.dart'; 
import 'people_database.dart';

Future<void> main() async {
  // 1. Ensures Flutter is ready before we touch the database
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Pre-initialize the database so it's ready for the incoming share
  await DatabaseHelper.instance.database;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InstaChecker',
      // Combined your theme styles here
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent, 
          brightness: Brightness.dark
        ),
        useMaterial3: true,
      ),
      // 3. FIXES the "Failed to handle route" error by catching the incoming URL
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      },
      home: const HomeScreen(), 
    );
  }
}