import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ReelMetadata {
  final String username;
  final String profilePicUrl;
  final String? transcript;

  ReelMetadata({
    required this.username, 
    required this.profilePicUrl, 
    this.transcript
  });
}

class InstagramMetadataService {
  static const String _apiKey = 'QRAul4aV3hTJTGkl0HzBAA3UkVC3';
  static const String _baseUrl = 'https://api.scrapecreators.com';

  Future<ReelMetadata?> getReelDetails(String reelUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?url=$reelUrl'),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // This is the safety check that prevents the crash
        final author = data['author'] ?? data['owner'];
        if (author == null) return null;
        
        return ReelMetadata(
          username: author['username'] ?? "Unknown",
          profilePicUrl: author['profile_pic_url'] ?? author['profile_pic_url_hd'] ?? "",
          transcript: data['transcripts']?['text'],
        );
      }
    } catch (e) {
      debugPrint('Metadata Fetch Error: $e');
    }
    return null;
  }
}