import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'people_database.dart'; // Ensure this contains your DatabaseHelper
import 'result_screen.dart'; 
import 'background_search.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _filterController = TextEditingController();
  late StreamSubscription _intentDataStreamSubscription;
  bool _isAnalyzing = false;
  String _searchQuery = "";

  final AutoVerificationService _searchService = AutoVerificationService();
  
  // The dynamic list that syncs with SQLite
  List<Map<String, dynamic>> searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory(); // Load SQLite data on startup
    
    // Handling the Intent (App opened via Share)
    ReceiveSharingIntent.getInitialText().then((value) {
      if (value != null) _handleAnalyze(value);
    });

    // Handling the Intent (App in background)
    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream().listen((value) {
      _handleAnalyze(value);
    }, onError: (err) => debugPrint("Sharing Error: $err"));

    // Real-time filtering logic for the search bar
    _filterController.addListener(() {
      setState(() {
        _searchQuery = _filterController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _filterController.dispose();
    super.dispose();
  }

  // Fetch all records from the database
  void _loadHistory() async {
    final data = await DatabaseHelper.instance.fetchAllReels();
    setState(() => searchHistory = data);
  }

  String? _extractUsername(String text) {
    final RegExp regExp = RegExp(r"instagram\.com\/([a-zA-Z0-9_.]+)");
    final match = regExp.firstMatch(text);
    return (match != null && match.groupCount >= 1) ? match.group(1) : text.replaceAll("@", "").trim();
  }

  void _handleAnalyze(String input) async {
    String? targetUser = _extractUsername(input);
    if (targetUser == null || targetUser.isEmpty) return;

    setState(() => _isAnalyzing = true);

    // 1. Run Scraper Logic
    await _searchService.startAutomatedScan("Is Instagram user @$targetUser reliable?");
    final report = _searchService.getFinalReport(targetUser);

    setState(() => _isAnalyzing = false);

    // 2. Prepare Data
    final double finalScore = report['position'] == "Supported" ? 0.92 : 0.25;
    final List<String> finalSources = _searchService.verifiedResults.map((r) => r['url']!).toList();

    // 3. Save to SQLite
    await DatabaseHelper.instance.addReelWithSources({
      'user': targetUser,
      'profilePic': "https://unavatar.io",
      'score': finalScore,
      'date': "${DateTime.now().hour}:${DateTime.now().minute}",
      'status': report['position'], 
      'reason': report['summary'],
      'transcript': "Analyzed ${finalSources.length} sources.",
    }, finalSources);

    // 4. Refresh History List
    _loadHistory();

    if (!mounted) return;

    // 5. Navigate to Result
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
          transcript: "Analysis Complete.",
          sources: sources,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter the history list based on search bar input
    final filteredHistory = searchHistory.where((item) {
      return item['user'].toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("InstaChecker", style: TextStyle(color: Colors.white)),
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
                TextField(
                  controller: _filterController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Filter past scans...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    fillColor: const Color(0xFF1E293B),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("HISTORY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Expanded(
                  child: filteredHistory.isEmpty 
                    ? const Center(child: Text("No history found", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final item = filteredHistory[index];
                          return Card(
                            color: const Color(0xFF1E293B),
                            child: ListTile(
                              leading: CircleAvatar(backgroundImage: NetworkImage(item['profilePic'] ?? "")),
                              title: Text("@${item['user']}", style: const TextStyle(color: Colors.white)),
                              subtitle: Text("Score: ${(item['score'] * 100).toInt()}% • ${item['status']}"),
                              onTap: () => _navigateToResult(
                                item['user'], 
                                item['score'], 
                                item['status'], 
                                item['reason'], 
                                List<String>.from(item['sources'] ?? [])
                              ),
                              onLongPress: () async {
                                await DatabaseHelper.instance.deleteReel(item['id']);
                                _loadHistory();
                              },
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
