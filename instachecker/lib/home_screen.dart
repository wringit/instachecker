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
  final TextEditingController _filterController = TextEditingController();
  late StreamSubscription _intentDataStreamSubscription;
  bool _isAnalyzing = false;
  String _searchQuery = "";

  final AutoVerificationService _searchService = AutoVerificationService();

  // History list
  List<Map<String, dynamic>> searchHistory = [
    {
      "user": "Reel: Travel Tips",
      "profilePic": "https://i.pravatar.cc/150?u=reel1",
      "score": 0.85,
      "date": "2 mins ago",
      "status": "Verified",
      "reason": "The travel advisory mentioned is confirmed by official boards.",
      "transcript": "Video claims Italy has opened a new visa-free path...",
      "sources": ["https://reuters.com", "https://apnews.com"]
    },
    {
      "user": "Reel: Health Hack",
      "profilePic": "https://i.pravatar.cc/150?u=reel2",
      "score": 0.0,
      "date": "1 hour ago",
      "status": "Refuted",
      "reason": "Medical professionals have flagged this hack as dangerous.",
      "transcript": "Claiming that drinking salt water cures insomnia...",
      "sources": ["https://mayoclinic.org"]
    },
  ];
  
  // Dynamic list loaded from SQLite
  List<Map<String, dynamic>> searchHistory = [];

  @override
  void initState() {
    super.initState();
    
    // Handling the Intent (The ONLY way to trigger a search)
    ReceiveSharingIntent.getInitialText().then((value) {
      if (value != null) _handleAnalyze(value);
    _loadHistory();
    
    ReceiveSharingIntent.getInitialText().then((value) {
      if (value != null) _handleAnalyze(value);
    });

    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream().listen((value) {
    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream().listen((value) {
      _handleAnalyze(value);
    }, onError: (err) => debugPrint("Sharing Error: $err"));

    // Listen to the search bar for filtering ONLY
    _filterController.addListener(() {
      setState(() {
        _searchQuery = _filterController.text.toLowerCase();
      });
    });
    }, onError: (err) => debugPrint("Intent error: $err"));
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _filterController.dispose();
    super.dispose();
  }

  void _loadHistory() async {
    final data = await DatabaseHelper.instance.fetchAllReels();
    setState(() => searchHistory = data);
  }

// This now finds the ID even if there is extra text around it
  String? _extractReelId(String text) {
    // Looks for the ID after /reel/, /reels/, or /p/
    final RegExp regExp = RegExp(r"instagram\.com\/(?:reel|reels|p)\/([a-zA-Z0-9_-]+)");
    final match = regExp.firstMatch(text);
    return (match != null && match.groupCount >= 1) ? match.group(1) : null;
  }

  void _handleAnalyze(String input) async {
    // 1. Clean the input (Instagram often sends text + link)
    String? reelId = _extractReelId(input);

    // If we can't find a Reel ID, it might be a username search fallback
    if (reelId == null && input.contains("@")) {
       reelId = input.split("@").last.split(" ").first;
    }

    if (reelId == null) return;

    setState(() { _isAnalyzing = true; });

    // 2. Run the actual background scan
    await _searchService.startAutomatedScan("Verify the claims in this Instagram content: $reelId");
    final report = _searchService.getFinalReport(reelId);

    setState(() { _isAnalyzing = false; });
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

    // 3. Launch Result Screen
  void _navigateToResult(String user, double score, String status, String reason, List<String> sources) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          username: "Reel: $reelId",
          profilePic: "https://i.pravatar.cc/150?u=$reelId", 
          score: (report['position'] == "Refuted") ? 0.0 : 1.0, 
          status: report['position'], 
          reason: report['summary'],
          transcript: "Reel Analysis: ${report['summary']}",
          sources: _searchService.verifiedResults.isNotEmpty 
              ? _searchService.verifiedResults.map((r) => r['url'] as String).toList()
              : ["No sources found confirming these claims."],
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
    // Logic to filter the list based on the search bar text
    final filteredHistory = searchHistory.where((item) {
      return item['user'].toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text("InstaChecker"), backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // SEARCH BAR: Now functions ONLY as a list filter
                TextField(
                  controller: _filterController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Filter past scans...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    hintText: "Paste link or @username",
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    filled: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search), 
                      onPressed: () => _handleAnalyze(_searchController.text)
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("HISTORY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                const SizedBox(height: 20),
                Expanded(
                  child: filteredHistory.isEmpty 
                    ? const Center(child: Text("No matches found", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final item = filteredHistory[index];
                          return Card(
                            color: const Color(0xFF1E293B),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(image: NetworkImage(item['profilePic']), fit: BoxFit.cover),
                                ),
                              ),
                              title: Text(item['user'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text("Credibility: ${(item['score'] * 100).toInt()}%", style: const TextStyle(color: Colors.white70)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ResultScreen(
                                  username: item['user'],
                                  profilePic: item['profilePic'],
                                  score: item['score'], 
                                  status: item['status'],
                                  reason: item['reason'],
                                  transcript: item['transcript'],
                                  sources: List<String>.from(item['sources']),
                                )));
                              },
                            ),
                          );
                        },
                      ),
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
          if (_isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.86),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 5),
                    SizedBox(height: 20),
                    Text("FACT-CHECKING SHARED REEL...", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
          if (_isAnalyzing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
