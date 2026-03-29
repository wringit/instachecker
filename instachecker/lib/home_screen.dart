import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; 

// Ensure these filenames match your project exactly
import 'people_database.dart';
import 'result_screen.dart'; 
import 'background_search.dart'; 
import 'one_url.dart'; 

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
  final InstagramMetadataService _metadataService = InstagramMetadataService(); 
  List<Map<String, dynamic>> searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    
    // 1. Handle URL if app was closed and opened via share
    ReceiveSharingIntent.getInitialText().then((value) {
      if (value != null && mounted) _handleAnalyze(value);
    });

    // 2. Handle the "Jump" from Instagram while app is already open
    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream().listen((value) {
      if (mounted) {
        // This strips the custom scheme and decodes the real Instagram link
        String cleanValue = value.replaceFirst("instachecker://share?url=", "");
        _handleAnalyze(Uri.decodeComponent(cleanValue));
      }
    }, onError: (err) => debugPrint("Sharing Error: $err"));

    _filterController.addListener(() {
      setState(() => _searchQuery = _filterController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _filterController.dispose();
    super.dispose();
  }

  void _loadHistory() async {
    try {
      final data = await DatabaseHelper.instance.fetchAllReels();
      setState(() => searchHistory = data);
    } catch (e) {
      debugPrint("History Load Error: $e");
    }
  }

  void _handleAnalyze(String input) async {
    if (input.isEmpty) return;
    
    setState(() => _isAnalyzing = true);

    try {
      // 1. Fetch REAL Metadata from one_url.dart
      final metadata = await _metadataService.getReelDetails(input);
      
      String targetUser = metadata?.username ?? "Unknown User";
      String profilePic = metadata?.profilePicUrl ?? "https://unavatar.io/instagram/$targetUser";
      String? transcript = metadata?.transcript;

      // 2. Run the Fact-Check Scan
      String searchQuery = (transcript != null && transcript.isNotEmpty) 
          ? "Fact check: $transcript" 
          : "Is instagram user $targetUser trustworthy?";
          
      await _searchService.startAutomatedScan(searchQuery);
      final report = await _searchService.getFinalReport(targetUser);

      // 3. Prepare positions and scores
      final String status = report['position'] ?? "Neutral";
      final String summary = report['summary'] ?? "Analysis complete.";
      final String confStr = report['confidence_percent']?.toString().replaceAll('%', '') ?? '0';
      final double finalScore = (double.tryParse(confStr) ?? 0.0) / 100.0;

      final List<String> finalSources = _searchService.verifiedResults.isNotEmpty 
          ? _searchService.verifiedResults.map((r) => r['url'] as String).toList()
          : ["No sources found."];

      // 4. Save to SQLite
      await DatabaseHelper.instance.addReelWithSources({
        'user': targetUser,
        'profilePic': profilePic,
        'score': finalScore,
        'date': "${DateTime.now().hour}:${DateTime.now().minute}",
        'status': status, 
        'reason': summary,
        'transcript': transcript ?? "No transcript available.",
      }, finalSources);

      _loadHistory(); 
      setState(() => _isAnalyzing = false);

      if (!mounted) return;
      _navigateToResult(targetUser, profilePic, finalScore, status, summary, transcript ?? "", finalSources);

    } catch (e) {
      debugPrint("Analysis Error: $e");
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error analyzing Reel: $e")),
        );
      }
    }
  }

  void _navigateToResult(String user, String pic, double score, String status, String reason, String transcript, List<String> sources) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          username: user,
          profilePic: pic,
          score: score,
          status: status, 
          reason: reason,
          transcript: transcript,
          sources: sources,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = searchHistory.where((item) {
      return item['user'].toString().toLowerCase().contains(_searchQuery);
    }).toList();

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
                TextField(
                  controller: _filterController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Filter past scans...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white54),
                      onPressed: () => _handleAnalyze(_filterController.text),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("HISTORY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Expanded(
                  child: SlidableAutoCloseBehavior(
                    child: filteredHistory.isEmpty
                        ? const Center(child: Text("No matches found", style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            itemCount: filteredHistory.length,
                            itemBuilder: (context, index) {
                              final item = filteredHistory[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Slidable(
                                  key: Key(item['id'].toString()),
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
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
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(15)),
                                      ),
                                    ],
                                  ),
                                  child: Card(
                                    color: const Color(0xFF1E293B),
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(item['profilePic'] ?? ""),
                                        backgroundColor: Colors.blueGrey,
                                      ),
                                      title: Text(item['user'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      subtitle: Text("Credibility: ${((item['score'] ?? 0) * 100).toInt()}%", style: const TextStyle(color: Colors.white70)),
                                      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                                      onTap: () => _navigateToResult(
                                        item['user'],
                                        item['profilePic'] ?? "",
                                        item['score'],
                                        item['status'] ?? "N/A",
                                        item['reason'] ?? "N/A",
                                        item['transcript'] ?? "",
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
                    CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 5),
                    SizedBox(height: 20),
                    Text("FETCHING METADATA & FACT-CHECKING...", 
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}