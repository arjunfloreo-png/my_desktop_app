import 'mini_video_charater_reaction_model.dart';

class MiniVod {
  final String id;
  final String name;
  final String videoUrl;
  String thumbnailUrl;
  Duration duration; // ← remove final
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

  factory MiniVod.fromCharacter(Character char, {required String type}) {
    return MiniVod(
      id: char.vimeoId,
      name: char.name1,
      videoUrl: char.videoUrl.isNotEmpty ? char.videoUrl.first : '',
      thumbnailUrl: char.vimeoThumbnailUrl,
      duration: const Duration(seconds: 0), // ← temp, real fetched below
      category: type == 'character' ? 'Character' : 'Reaction',
      vimeoUrl: char.vimeoUrl,
      uploadStatus: char.uploadStatus,
    );
  }
}