import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:dart_sentiment/dart_sentiment.dart';

Map<String, String> backgroundAnalyze(Map<String, dynamic> data) {
  final sentiment = Sentiment();
  String claim = (data['claim'] ?? "").toString().toLowerCase();
  String title = (data['title'] ?? "").toString().toLowerCase();
  String body = (data['body'] ?? "").toString().toLowerCase();

  int titleScore = tokenSetRatio(claim, title);
  int bodyScore = tokenSetPartialRatio(claim, body);

  if (titleScore < 60 && bodyScore < 65) {
    return {'verdict': 'Neither', 'reason': 'Irrelevant content'};
  }

  String context = _extractContext(body, claim);
  var analysis = sentiment.analysis(context);
  double score = analysis['comparative'];

  if (score > 0.15) {
    return {'verdict': 'Supports', 'reason': 'Positive alignment found'};
  } else if (score < -0.15 || _containsRefutationKeywords(context)) {
    return {'verdict': 'Refutes', 'reason': 'Contradictory language detected'};
  } else {
    return {'verdict': 'Neither', 'reason': 'Neutral or ambiguous stance'};
  }
}

bool _containsRefutationKeywords(String text) {
  final keys = ['fake', 'debunked', 'false', 'hoax', 'incorrect', 'myth', 'faked'];
  return keys.any((k) => text.contains(k));
}

String _extractContext(String body, String claim) {
  int index = body.indexOf(claim.split(' ').first);
  if (index == -1) return body.substring(0, body.length > 300 ? 300 : body.length);
  int start = (index - 100).clamp(0, body.length);
  int end = (index + 300).clamp(0, body.length);
  return body.substring(start, end);
}

class AutoVerificationService extends ChangeNotifier {
  List<Map<String, String>> verifiedResults = [];
  bool isSearching = false;
  int sitesProcessed = 0;
  final int maxLinks = 6;

  Future<void> startAutomatedScan(String claim) async {
    isSearching = true;
    verifiedResults.clear();
    sitesProcessed = 0;
    notifyListeners();

    final urls = await _fetchGoogleUrls(claim);
    if (urls.isEmpty) {
      isSearching = false;
      notifyListeners();
      return;
    }

    for (var url in urls.take(maxLinks)) {
      await Future.delayed(const Duration(milliseconds: 600));
      _runHeadlessScraper(url, claim);
    }
  }

  Future<List<String>> _fetchGoogleUrls(String query) async {
    try {
      final url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url), headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
      });

      if (response.statusCode == 200) {
        var doc = parse(response.body);
        return doc.querySelectorAll('div.yuRUbf > a, div.v7W49e a, a[data-ved]')
            .map((e) => e.attributes['href'] ?? '')
            .where((href) => href.startsWith('http') && !href.contains('google.com'))
            .toList();
      }
    } catch (e) {
      debugPrint("Search Fetch Error: $e");
    }
    return [];
  }

  void _runHeadlessScraper(String url, String claim) {
    HeadlessInAppWebView? headless;
    final watchdog = Timer(const Duration(seconds: 20), () {
    // If headless is null, the whole thing returns null, then defaults to false.
    if (headless?.isRunning() == true) {
      headless?.dispose();
      _checkIfFinished();
    }
    });

    headless = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(javaScriptEnabled: true, blockNetworkImage: true),
      onLoadStop: (controller, _) async {
        watchdog.cancel();
        try {
          final Map? data = await controller.evaluateJavascript(source: """
            ({
              title: document.title,
              body: Array.from(document.querySelectorAll('p')).map(el => el.innerText).join(' ').substring(0, 5000)
            })
          """);

          if (data != null) {
            final Map<String, String> analysis = await compute(backgroundAnalyze, {
              'claim': claim,
              'title': data['title'] ?? '',
              'body': data['body'] ?? ''
            });

            if (analysis['verdict'] != 'Neither') {
              verifiedResults.add({
                'url': url,
                'title': data['title'] ?? 'No Title',
                'verdict': analysis['verdict']!,
                'reason': analysis['reason']!,
              });
              notifyListeners();
            }
          }
        } finally {
          controller.dispose();
          _checkIfFinished();
        }
      },
    );
    headless.run();
  }

  void _checkIfFinished() {
    sitesProcessed++;
    if (sitesProcessed >= maxLinks) {
      isSearching = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> getFinalReport(String originalQuery) {
    List<Map<String, String>> supporters = verifiedResults.where((r) => r['verdict'] == 'Supports').toList();
    List<Map<String, String>> refuters = verifiedResults.where((r) => r['verdict'] == 'Refutes').toList();

    int totalRelevant = supporters.length + refuters.length;
    bool isSupported = supporters.length > refuters.length;
    bool isRefuted = refuters.length > supporters.length;
    String position = isSupported ? "Supported" : (isRefuted ? "Refuted" : "Neutral");

    double confidence = (position == "Neutral") 
        ? 100.0 
        : (totalRelevant > 0 ? (isSupported ? supporters.length : refuters.length) / totalRelevant * 100 : 0.0);

    return {
      "initial_query": originalQuery,
      "position": position,
      "confidence_percent": "${confidence.toStringAsFixed(0)}%",
      "summary": "Found ${supporters.length} supporting and ${refuters.length} refuting sources.",
      "ordered_sources": isSupported ? [...supporters, ...refuters] : [...refuters, ...supporters],
    };
  }
}