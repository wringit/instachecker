import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; 
import 'result_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredHistory = [];

  // mock data
  List<Map<String, dynamic>> searchHistory = [
    {
      "user": "alpha_traveler", 
      "score": 0.85, 
      "profilePic": "https://i.pravatar.cc/150?u=alpha",
      "date": "2 mins ago",
      "status": "Safe",
      "reason": "Account shows consistent travel content with no flagged misinformation.",
      "sources": [
        "https://www.nationalgeographic.com",
        "https://www.lonelyplanet.com",
        "https://www.tripadvisor.com",
        "https://www.bbc.com/travel",
        "https://www.cntraveler.com",
        "https://www.travelandleisure.com"
      ]
    },
    {
      "user": "bot_test_01", 
      "score": 0.12, 
      "profilePic": "https://i.pravatar.cc/150?u=bot",
      "date": "1 hour ago",
      "status": "High Risk",
      "reason": "Bot-like behavior detected. High frequency of repetitive posts.",
      "sources": [
        "https://www.reuters.com",
        "https://www.apnews.com",
        "https://www.factcheck.org",
        "https://www.snopes.com",
        "https://www.nytimes.com",
        "https://www.wikipedia.org"
      ]
    },
  ];

  void _filterSearch(String query) {
    setState(() {
      _filteredHistory = searchHistory
          .where((item) => item['user'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    // sorted from most credible (1.0) to least (0.0)
    searchHistory.sort((a, b) => b['score'].compareTo(a['score']));
    _filteredHistory = searchHistory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21), // apply navy theme
      appBar: AppBar(
        title: const Text("Insta Checker", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearch, // trigger the filter
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: const Color(0xFF1D1E33),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            // makes sure only one slider can stay open at a given time
            child: SlidableAutoCloseBehavior(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredHistory.length,
                itemBuilder: (context, index) {
                  final item = _filteredHistory[index];

                  // actually delete function
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Slidable(
                      key: Key(item['user']),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              setState(() {
                                String userToDelete = item['user'];
                                searchHistory.removeWhere((element) => element['user'] == userToDelete);
                                _filterSearch(_searchController.text);
                              });
                            },
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                          ),
                        ],
                      ),

                      // the actual card
                      child: HistoryTile(
                        username: item['user'],
                        score: item['score'],
                        date: item['date'],
                        // pass all necessary variables to the next screen
                        status: item['status'],
                        reason: item['reason'],
                        sources: List<String>.from(item['sources']),
                        profilePic: item['profilePic'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  final String username;
  final double score;
  final String profilePic;
  final String date;
  final String status;
  final String reason;
  final List<String> sources;

  const HistoryTile({
    super.key,
    required this.username,
    required this.score,
    required this.profilePic,
    required this.date,
    required this.status,
    required this.reason,
    required this.sources,
  });

  // helper function to change color based on score
  Color _getScoreColor() {
    if (score > 0.8) return Colors.greenAccent;
    if (score > 0.5) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    // makes the whole card clickable
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              // use of data belonging to specifically this screen
              username: username, 
              score: score,
              profilePic: profilePic,
              status: status,
              reason: reason,
              sources: sources,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33), // lighter navy
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [

            // circular progress indicator
            SizedBox(
              height: 50,
              width: 50,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: score,
                    strokeWidth: 4,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
                  ),
                  Center(
                    child: Text(
                      "${(score * 100).toInt()}",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // user text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("@$username", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(color: Colors.white70)), 
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}