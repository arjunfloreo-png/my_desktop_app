// lib/models/mini_vod.dart

import 'mini_video_charater_reaction_model.dart';

class MiniVod {
  final String id;
  final String name;
  final String videoUrl;
  String thumbnailUrl;  // ← MUTABLE (not final)
  final Duration duration;
  final String? category;
  final String vimeoUrl;
  final String uploadStatus;

  MiniVod({
    required this.id,
    required this.name,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    this.category,
    required this.vimeoUrl,
    required this.uploadStatus,
  });

  /// Character → MiniVod
  factory MiniVod.fromCharacter(
    Character char, {
    required String type,
  }) {
    return MiniVod(
      id: char.vimeoId,
      name: char.name1,
      videoUrl: char.videoUrl,
      thumbnailUrl: '', // Will fetch real one
      duration: const Duration(minutes: 5),
      category: type == 'character' ? 'Character' : 'Reaction',
      vimeoUrl: char.vimeoUrl,
      uploadStatus: char.uploadStatus,
    );
  }
}
