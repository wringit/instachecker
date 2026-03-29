import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For clicking links

class ResultScreen extends StatelessWidget {
  // This is the "Contract" we talked about
  final double score = 85; 
  final String status = "High Risk";
  final String reason = "This video claims that lemons cure everything. Scientific consensus suggests otherwise.";
  final String true_post = "instagram.com/v='abbcdef'";
  final List<String> sources = [
    "https://www.healthline.com",
    "https://www.reuters.com/factcheck"
  ];
  final DateTime time = DateTime.timestamp();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Analysis Result")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. The Score Meter
            Text("Credibility Score: ${(score * 100).toInt()}%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            LinearProgressIndicator(
              value: score,
              backgroundColor: Colors.grey[300],
              color: score < 0.5 ? Colors.red : Colors.green,
              minHeight: 10,
            ),
            SizedBox(height: 20),
            
            // 2. The Reason
            Text("Why was this flagged?", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(reason),
            SizedBox(height: 20),

            // 3. The Links
            Text("Sources:", style: TextStyle(fontWeight: FontWeight.bold)),
            // This creates a list of clickable texts
            ...sources.map((url) => InkWell(
              onTap: () => launchUrl(Uri.parse(url)), // Opens in Browser
              child: Text(url, style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
            )).toList(),
          ],
        ),
      ),
    );
  }
}