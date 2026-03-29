import 'dart:convert';
import 'package:http/http.dart' as http;

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
  // Get your free API key at https://scrapecreators.com
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // These keys vary slightly by provider; ScrapeCreators usually returns 
        // an 'owner' or 'author' object
        final author = data['author'] ?? data['owner'];
        
        return ReelMetadata(
          username: author['username'],
          profilePicUrl: author['profile_pic_url'] ?? author['profile_pic_url_hd'],
          transcript: data['transcripts']?['text'],
        );
      }
    } catch (e) {
      print('Metadata Fetch Error: $e');
    }
    return null;
  }
}
