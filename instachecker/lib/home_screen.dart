import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'people_database.dart';
import 'result_screen.dart'; 
import 'background_search.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late StreamSubscription _intentDataStreamSubscription;
  bool _isAnalyzing = false;
  final AutoVerificationService _searchService = AutoVerificationService();
  
  // Dynamic list loaded from SQLite
  List<Map<String, dynamic>> searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    
    ReceiveSharingIntent.getInitialText().then((value) {
      if (value != null) _handleAnalyze(value);
    });

    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream().listen((value) {
      _handleAnalyze(value);
    }, onError: (err) => debugPrint("Intent error: $err"));
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadHistory() async {
    final data = await DatabaseHelper.instance.fetchAllReels();
    setState(() => searchHistory = data);
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

    if (targetUser == null || targetUser.isEmpty) return;

    setState(() => _isAnalyzing = true);
    await _searchService.startAutomatedScan("Is Instagram user @$targetUser reliable?");
    final report = _searchService.getFinalReport(targetUser);
    setState(() => _isAnalyzing = false);

    // Save to Database
    final double finalScore = report['position'] == "Supported" ? 0.92 : 0.25;
    final List<String> finalSources = _searchService.verifiedResults.map((r) => r['url']!).toList();

    await DatabaseHelper.instance.addReelWithSources({
      'user': targetUser,
      'profilePic': "https://unavatar.io",
      'score': finalScore,
      'date': "${DateTime.now().hour}:${DateTime.now().minute}",
      'status': report['position'], 
      'reason': report['summary'],
      'transcript': "Analyzed ${finalSources.length} sources.",
    }, finalSources);

    _loadHistory(); // Update UI list

    if (!mounted) return;
    _navigateToResult(targetUser, finalScore, report['position'], report['summary'], finalSources);
  }

  void _navigateToResult(String user, double score, String status, String reason, List<String> sources) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          username: user,
          profilePic: "https://unavatar.io",
          score: score,
          status: status, 
          reason: reason,
          transcript: "Loaded from analysis.",
          sources: sources,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text("InstaChecker"), backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Paste link or @username",
                    fillColor: const Color(0xFF1E293B),
                    filled: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search), 
                      onPressed: () => _handleAnalyze(_searchController.text)
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: searchHistory.length,
                    itemBuilder: (context, index) {
                      final item = searchHistory[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: NetworkImage(item['profilePic'] ?? "")),
                        title: Text("@${item['user']}", style: const TextStyle(color: Colors.white)),
                        onTap: () => _navigateToResult(item['user'], item['score'], item['status'], item['reason'], List<String>.from(item['sources'])),
                        onLongPress: () async {
                          await DatabaseHelper.instance.deleteReel(item['id']);
                          _loadHistory();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isAnalyzing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
