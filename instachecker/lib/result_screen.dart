import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:any_link_preview/any_link_preview.dart';

class ResultScreen extends StatelessWidget {
  final String username;
  final String profilePic;
  final double score;
  final String status;
  final String reason;
  final List<String> sources;

  const ResultScreen({
    super.key, 
    required this.username, 
    required this.profilePic, 
    required this.score,
    required this.status,
    required this.reason,
    required this.sources,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      appBar: AppBar(
        title: Text("@$username Analysis", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // score banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: score > 0.7 
                      ? [Colors.greenAccent, Colors.blue] 
                      : [Colors.redAccent, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // circular profile pic
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 55, // made larger
                      backgroundImage: NetworkImage(profilePic),
                      backgroundColor: Colors.white10,
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // username and stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "@$username", 
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 16, // smaller username
                            fontWeight: FontWeight.w500
                          )
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${(score * 100).toInt()}% Credibility", 
                          style: const TextStyle(
                            fontSize: 24, // smaller percentage text
                            fontWeight: FontWeight.bold, 
                            color: Colors.white
                          )
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: score,
                            minHeight: 6, // thinner progress bar
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Status: $status", 
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8), 
                            fontSize: 13 // smaller status text
                          )
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ai analysis
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

            const Text("VERIFIED SOURCES", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // link preview
            ...sources.map((url) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: AnyLinkPreview(
                link: url,
                displayDirection: UIDirection.uiDirectionHorizontal,
                showMultimedia: true,
                bodyMaxLines: 2,
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                bodyStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                backgroundColor: const Color(0xFF1E293B),
                borderRadius: 12,
                onTap: () => launchUrl(Uri.parse(url)),
                
                // fail-safe: if image can't be shown, show a clean link tile
                errorWidget: InkWell(
                  onTap: () => launchUrl(Uri.parse(url)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            url,
                            style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.open_in_new, color: Colors.white24, size: 16),
                      ],
                    ),
                  ),
                ),
                cache: const Duration(days: 7),
              ),
            )),
          ],
        ),
      ),
    );
  }
}