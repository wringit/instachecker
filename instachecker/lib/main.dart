import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'result_screen.dart'; // This is the file you just showed me

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InstaChecker',
      // This forces the dark theme you had in your ResultScreen
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    // This listens for the "teleport" while the app is open
    _appLinks.uriLinkStream.listen((uri) => _handleIncomingLink(uri));

    // This catches the "teleport" if the app was totally closed
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleIncomingLink(initialUri);
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.scheme == 'instachecker' && uri.queryParameters.containsKey('url')) {
      String sharedUrl = uri.queryParameters['url']!;
      
      // Navigate to your ResultScreen with the data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            username: "Checking...", 
            profilePic: "https://www.w3schools.com/howto/img_avatar.png", 
            score: 0.0, // You'll eventually replace this with real API data
            status: "Processing",
            reason: "Analyzing Reel: $sharedUrl",
            transcript: "Fetching transcript...",
            sources: const [],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your original Home Screen UI goes here
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text("InstaChecker", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Share a Reel to analyze its credibility"),
          ],
        ),
      ),
    );
  }
}