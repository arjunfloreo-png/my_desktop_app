import 'mini_video_charater_reaction_model.dart';
class MiniVod {
  final String id;
  final String name;
  final String videoUrl;
  String thumbnailUrl;
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

  factory MiniVod.fromCharacter(Character char, {required String type}) {
    return MiniVod(
      id: char.vimeoId,
      name: char.name1,
      videoUrl: char.videoUrl.isNotEmpty ? char.videoUrl.first : '', // ← fix
      thumbnailUrl: char.vimeoThumbnailUrl,                          // ← use real thumb
      duration: const Duration(minutes: 5),
      category: type == 'character' ? 'Character' : 'Reaction',
      vimeoUrl: char.vimeoUrl,
      uploadStatus: char.uploadStatus,
    );
  }
}