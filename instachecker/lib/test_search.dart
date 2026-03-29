import 'package:flutter/material.dart';
// Replace 'your_file.dart' with the actual filename of your service
import 'background_search.dart'; 

class FactCheckTestPage extends StatefulWidget {
  const FactCheckTestPage({super.key});

  @override
  State<FactCheckTestPage> createState() => _FactCheckTestPageState();
}

class _FactCheckTestPageState extends State<FactCheckTestPage> {
  final TextEditingController _queryController = TextEditingController();
  final AutoVerificationService _service = AutoVerificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fact Engine Test Lab")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. INPUT FIELD
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: "Enter a claim (e.g., 'Moon landing was faked')",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _service.startAutomatedScan(_queryController.text),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. LIVE RESULTS AREA
            Expanded(
              child: ListenableBuilder(
                listenable: _service,
                builder: (context, _) {
                  // Get the report data
                  final report = _service.getFinalReport(_queryController.text);
                  final sources = report['ordered_sources'] as List<Map<String, String>>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Indicator
                      if (_service.isSearching) ...[
                        const LinearProgressIndicator(),
                        const Text("Searching & Scraping 6 sites..."),
                      ],

                      // SUMMARY CARD
                      if (sources.isNotEmpty) 
                        Card(
                          color: _getVerdictColor(report['position']),
                          child: ListTile(
                            title: Text("Position: ${report['position']}", 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text("Confidence: ${report['confidence_percent']} | ${report['summary']}",
                                style: const TextStyle(color: Colors.white70)),
                          ),
                        ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("Individual Sources:", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),

                      // SOURCE LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: sources.length,
                          itemBuilder: (context, i) {
                            final s = sources[i];
                            final bool isSup = s['verdict'] == 'Supports';
                            return Card(
                              child: ListTile(
                                leading: Icon(isSup ? Icons.check_circle : Icons.cancel, 
                                              color: isSup ? Colors.green : Colors.red),
                                title: Text(s['title'] ?? "No Title"),
                                subtitle: Text("Stance: ${s['verdict']}\nReason: ${s['reason']}"),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getVerdictColor(String position) {
    if (position == "Supported") return Colors.green.shade700;
    if (position == "Refuted") return Colors.red.shade700;
    return Colors.grey.shade700;
  }
}
