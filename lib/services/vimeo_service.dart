// lib/services/vimeo_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class VimeoService {
  /// Get real thumbnail from Vimeo oEmbed API
  static Future<String> getThumbnailUrl(String vimeoId) async {
    try {
      final url = 'https://vimeo.com/api/oembed.json?url=https://vimeo.com/$vimeoId';
      final res = await http.get(Uri.parse(url));
      
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final thumbUrl = json['thumbnail_url'] as String?;
        
        if (thumbUrl != null && thumbUrl.isNotEmpty) {
          print('✓ Thumbnail for $vimeoId: $thumbUrl');
          return thumbUrl;
        }
      }
    } catch (e) {
      print('✗ Error fetching thumbnail for $vimeoId: $e');
    }
    
    return ''; // Empty = use fallback
  }

  /// Batch fetch all thumbnails
  static Future<Map<String, String>> getThumbnailUrls(List<String> vimeoIds) async {
    final results = <String, String>{};
    
    print('Fetching ${vimeoIds.length} thumbnails...');
    
    await Future.wait(
      vimeoIds.map((id) async {
        final thumb = await getThumbnailUrl(id);
        if (thumb.isNotEmpty) {
          results[id] = thumb;
        }
      }),
    );
    
    print('✓ Fetched ${results.length}/${vimeoIds.length} thumbnails');
    return results;
  }
}

// TEST: Run this to fetch your 4 thumbnails
void main() async {
  final vimeoIds = [
    '1194620720', // Laugh
    '1194620656', // Confused
    '1194620461', // Man Walking
    '1194620067', // award
  ];
  
  final thumbnails = await VimeoService.getThumbnailUrls(vimeoIds);
  
  print('\n=== THUMBNAILS ===');
  thumbnails.forEach((id, url) {
    print('$id → $url');
  });
}
