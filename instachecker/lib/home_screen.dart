import 'package:flutter/material.dart';
import 'result_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock Data
  List<Map<String, dynamic>> searchHistory = [
    {"user": "alpha_traveler", "score": 0.85, "date": "2 mins ago"},
    {"user": "bot_test_01", "score": 0.12, "date": "1 hour ago"},
    {"user": "insta_queen", "score": 0.98, "date": "Yesterday"},
    {"user": "spam_account_404", "score": 0.35, "date": "Oct 27"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21), // Apply navy theme
      appBar: AppBar(
        title: const Text("Search History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: searchHistory.length,
        itemBuilder: (context, index) {
          final item = searchHistory[index];

          // Handle the Swipe-to-Delete
          return Dismissible(
            key: Key(item['user']),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                searchHistory.removeAt(index);
              });
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),

            // the actual card
            child: HistoryTile(
              username: item['user'],
              score: item['score'],
              date: item['date'],
            ),
          );
        },
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  final String username;
  final double score;
  final String date;

  const HistoryTile({
    super.key,
    required this.username,
    required this.score,
    required this.date,
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
          MaterialPageRoute(builder: (context) => ResultScreen()),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33), // lighter navy
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues()),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                  Text(date, style: const TextStyle(color: Colors.white38)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}