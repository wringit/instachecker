import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'result_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late StreamSubscription _intentDataStreamSubscription;
  bool _isAnalyzing = false;

  List<Map<String, dynamic>> searchHistory = [
    {
      "user": "alpha_traveler",
      "profilePic": "https://i.pravatar.cc/150?u=alpha",
      "score": 0.85,
      "date": "2 mins ago",
      "status": "Safe",
      "reason": "Account shows consistent travel content with no flagged misinformation.",
      "transcript": "Check out these hidden gems in Italy! Make sure to book early.",
      "sources": ["https://reuters.com", "https://apnews.com"]
    },
  ];

@override
  void initState() {
    super.initState();

    // Try the "Legacy Static" approach first
    // If this shows red, hover over it to see what the IDE suggests
    ReceiveSharingIntent.getInitialText().then((String? value) {
      if (value != null) {
        _handleAnalyze(value);
      }
    });

    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      _handleAnalyze(value);
    }, onError: (err) {
      debugPrint("getLinkStream error: $err");
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String? _extractUsername(String url) {
    final RegExp regExp = RegExp(r"instagram\.com\/([a-zA-Z0-9_.]+)");
    final match = regExp.firstMatch(url);
    return (match != null && match.groupCount >= 1) ? match.group(1) : null;
  }

  void _handleAnalyze(String input) async {
    String? targetUser = input.contains("instagram.com") 
        ? _extractUsername(input) 
        : input.replaceAll("@", "");

    if (targetUser == null || targetUser.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Instagram link or username")),
      );
      return;
    }

    setState(() { _isAnalyzing = true; });

    // simulating backend process
    await Future.delayed(const Duration(seconds: 4));

    setState(() { _isAnalyzing = false; });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          username: targetUser,
          profilePic: "https://unavatar.io/instagram/$targetUser",
          score: 0.78,
          status: "Likely Credible",
          reason: "The AI cross-referenced the video transcript with verified news databases.",
          transcript: "Extracted: 'The new environmental policy will begin in 2026...'",
          sources: const [
            "https://reuters.com",
            "https://apnews.com",
            "https://factcheck.org",
            "https://snopes.com",
            "https://nytimes.com",
            "https://wikipedia.org"
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("InstaChecker", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // search bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Paste link or type @username",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Colors.blueAccent),
                      onPressed: () => _handleAnalyze(_searchController.text),
                    ),
                  ),
                  onSubmitted: _handleAnalyze,
                ),
                const SizedBox(height: 30),
                const Text("RECENT HISTORY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                // history list
                Expanded(
                  child: ListView.builder(
                    itemCount: searchHistory.length,
                    itemBuilder: (context, index) {
                      final item = searchHistory[index];
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage(item['profilePic'])),
                          title: Text("@${item['user']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text("Score: ${(item['score'] * 100).toInt()}% • ${item['date']}", style: const TextStyle(color: Colors.white70)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                          onTap: () => _handleAnalyze(item['user']),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // scanning overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.86),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 5),
                    SizedBox(height: 20),
                    Text("ANALYZING TRANSCRIPT...", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}