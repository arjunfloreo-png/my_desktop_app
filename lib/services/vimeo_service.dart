import 'dart:convert';
import 'package:http/http.dart' as http;

class VimeoService {
  // Single call — returns both thumb + duration
  static Future<({String thumb, Duration? duration})> getVideoInfo(String vimeoId) async {
  try {
    final url = 'https://vimeo.com/api/oembed.json?url=https://vimeo.com/$vimeoId';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final thumb = json['thumbnail_url'] as String? ?? '';
      final secs  = json['duration'];
      print('🎬 $vimeoId → duration=$secs thumb=$thumb'); // ← add
      final dur = secs != null && secs != 0
          ? Duration(seconds: secs is int ? secs : int.parse(secs.toString()))
          : null;
      return (thumb: thumb, duration: dur);
    } else {
      print('❌ $vimeoId → status=${res.statusCode}'); // ← add
    }
  } catch (e) {
    print('✗ $vimeoId error: $e');
  }
  return (thumb: '', duration: null);
}

  // Keep for backward compat
  static Future<String> getThumbnailUrl(String vimeoId) async {
    final info = await getVideoInfo(vimeoId);
    return info.thumb;
  }

  static Future<Map<String, String>> getThumbnailUrls(List<String> vimeoIds) async {
    final results = <String, String>{};
    await Future.wait(
      vimeoIds.map((id) async {
        final info = await getVideoInfo(id);
        if (info.thumb.isNotEmpty) results[id] = info.thumb;
      }),
    );
    return results;
  }
}