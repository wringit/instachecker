import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultScreen extends StatelessWidget {
  // Fix: score must be between 0.0 and 1.0 for the UI bar to work
  final double score = 0.85; 
  final String status = "High Risk";
  final String reason = "This video claims that lemons cure everything. Scientific consensus suggests otherwise.";
  final List<String> sources = [
    "https://www.healthline.com",
    "https://www.reuters.com/factcheck"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Give it a deep, modern background
      backgroundColor: const Color(0xFF0F172A), 
      appBar: AppBar(
        title: const Text("Analysis Result", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView( // Prevents "Going to hell" on small screens
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 2. The "Score Card" with a Gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: score > 0.7 ? [Colors.redAccent, Colors.orange] : [Colors.greenAccent, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text("Credibility Score", style: TextStyle(color: Colors.white.withOpacity(0.8))),
                  Text("${(score * 100).toInt()}%", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: score,
                      minHeight: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. The Reason Section (Using a Card)
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("AI ANALYSIS", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text(reason, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 4. Stylized Sources
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("VERIFIED SOURCES", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ...sources.map((url) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link, color: Colors.blueAccent),
              title: Text(url, style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline)),
              onTap: () => launchUrl(Uri.parse(url)),
            )).toList(),
          ],
        ),
      ),
    );
  }
}