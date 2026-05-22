// lib/services/reward_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mini_video_charater_reaction_model.dart';

class RewardApi {
  static const _base = 'https://only-clapped-bride.ngrok-free.dev';
  static const _headers = {
    'ngrok-skip-browser-warning': 'true',
    'Content-Type': 'application/json',
  };

  static Future<MiniVideoCharaterReactionModel> fetchRewardBox() async {
    final res = await http.get(
      Uri.parse(
        '$_base/api/method/floreo.api.therapist_api.v1.get_full_reactions',
      ),
      headers: _headers,
    );
    
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return MiniVideoCharaterReactionModel.fromJson(json);
  }

  static Future<List<Character>> fetchCharacterVods() async {
    final box = await fetchRewardBox();
    return box.message.characters;
  }

  static Future<List<Character>> fetchReactionVods() async {
    final box = await fetchRewardBox();
    return box.message.reactions;
  }

  static String fullUrl(String path) => '$_base$path';
}
