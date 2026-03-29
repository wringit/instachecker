import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Ensure this is imported
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
  
  // The dynamic list that syncs with SQLite
  List<Map<String, dynamic>> searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReceiveSharingIntent.getInitialText().then((value) {
        if (value != null && mounted) {
          _handleAnalyze(value);
        }
      });
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

  String? _extractReelId(String text) {
    final RegExp regExp = RegExp(r"instagram\.com\/(?:reel|reels|p)\/([a-zA-Z0-9_-]+)");
  String? _extractUsername(String text) {
    final RegExp regExp = RegExp(r"instagram\.com\/([a-zA-Z0-9_.]+)");
    final match = regExp.firstMatch(text);
    return (match != null && match.groupCount >= 1) ? match.group(1) : null;
  }

  String? _extractUsername(String text) {
    final RegExp regExp = RegExp(r"(?:@|instagram\.com\/)([a-zA-Z0-9_.]+)");
    final match = regExp.firstMatch(text);
    return match?.group(1);
  }

  void _handleAnalyze(String input) async {
    debugPrint("🚀 DATA RECEIVED FROM INSTAGRAM: $input"); 

    String? reelId = _extractReelId(input);
    String? targetUser = reelId ?? _extractUsername(input);

    if (targetUser == null || targetUser.isEmpty) return;

    setState(() { _isAnalyzing = true; });

    try {
      await _searchService.startAutomatedScan("Verify the claims: $targetUser");
      final report = await _searchService.getFinalReport(targetUser);

      final String status = report['position'] ?? "Neutral";
      final String summary = report['summary'] ?? "No data found.";
      
      // Clean up the confidence string from "100%" to a double 1.0
      final String confStr = report['confidence_percent'].toString().replaceAll('%', '');
      final double finalScore = (double.tryParse(confStr) ?? 0.0) / 100.0;

      final List<String> finalSources = _searchService.verifiedResults.isNotEmpty 
          ? _searchService.verifiedResults.map((r) => r['url'] as String).toList()
          : ["No sources found."];
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

      await DatabaseHelper.instance.addReelWithSources({
        'user': targetUser,
        'profilePic': "https://unavatar.io/instagram/$targetUser",
        'score': finalScore,
        'date': "${DateTime.now().hour}:${DateTime.now().minute}",
        'status': status, 
        'reason': summary,
        'transcript': "Analyzed ${finalSources.length} sources.",
      }, finalSources);
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

      _loadHistory(); 
      setState(() { _isAnalyzing = false; });
    // 4. Refresh History List
    _loadHistory();

      if (!mounted) return;
      _navigateToResult(targetUser, finalScore, status, summary, finalSources);

    } catch (e) {
      setState(() { _isAnalyzing = false; });
      debugPrint("Analysis Error: $e");
    }
  }

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
          profilePic: "https://unavatar.io/instagram/$user",
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
      return item['user'].toString().toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "InstaChecker",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _filterController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Filter past scans...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white54),
                      onPressed: () => _handleAnalyze(_filterController.text),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "HISTORY",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Expanded(
                  // AutoCloseBehavior ensures only one slider is open at a time
                  child: SlidableAutoCloseBehavior(
                    child: filteredHistory.isEmpty
                        ? const Center(
                            child: Text(
                              "No matches found",
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredHistory.length,
                            itemBuilder: (context, index) {
                              final item = filteredHistory[index];
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Slidable(
                                  key: Key(item['id'].toString()),
                                  // This groupTag helps AutoCloseBehavior track items
                                  groupTag: 'history_group',
                                  
                                  // Right-side actions (Slide left to reveal)
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    extentRatio: 0.25, // Reveal 25% of the width
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) async {
                                          await DatabaseHelper.instance.deleteReel(item['id']);
                                          _loadHistory();
                                        },
                                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: 'Delete',
                                        borderRadius: const BorderRadius.horizontal(
                                          right: Radius.circular(15)
                                        ),
                                      ),
                                    ],
                                  ),

                                  child: Card(
                                    color: const Color(0xFF1E293B),
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blueGrey,
                                        backgroundImage: NetworkImage(
                                          "https://unavatar.io/instagram/${item['user']}",
                                        ),
                                      ),
                                      title: Text(
                                        item['user'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "Credibility: ${(item['score'] * 100).toInt()}%",
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white24,
                                      ),
                                      onTap: () => _navigateToResult(
                                        item['user'],
                                        item['score'],
                                        item['status'],
                                        item['reason'],
                                        List<String>.from(item['sources'] ?? []),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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
                    CircularProgressIndicator(
                      color: Colors.blueAccent,
                      strokeWidth: 5,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "FACT-CHECKING SHARED REEL...",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}