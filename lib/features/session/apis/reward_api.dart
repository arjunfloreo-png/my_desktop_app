import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reward_box_model.dart' show RewardBoxModel;

class RewardApi {
  static const _base = 'https://only-clapped-bride.ngrok-free.dev';
  static const _headers = {
    'ngrok-skip-browser-warning': 'true',
    'Content-Type': 'application/json',
  };

  static Future<RewardBoxModel> fetchRewardBox() async {
    final res = await http.get(
      Uri.parse(
          'https://only-clapped-bride.ngrok-free.dev/api/method/floreo.api.therapist_api.v1.get_full_reactions'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode}');
    }
    return RewardBoxModel.fromJson(jsonDecode(res.body));
  }

  /// Prepend base URL to relative /files/... paths
  static String fullUrl(String path) => '$_base$path';
}
