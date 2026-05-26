import 'mini_video_charater_reaction_model.dart';

class MiniVod {
  final String id;
  final String name;
  final String videoUrl;
  String thumbnailUrl;
  Duration duration;
  final String category; // 'Character' or 'Reaction'
  final String vimeoUrl;
  final String uploadStatus;

  MiniVod({
    required this.id,
    required this.name,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.category,
    required this.vimeoUrl,
    required this.uploadStatus,
  });

  // Factory for Character VODs
  factory MiniVod.fromCharacter(Character char) {
    return MiniVod(
      id: char.name1, // Use name as ID since Character has no vimeoId
      name: char.name1,
      videoUrl: char.character, // GIF path
      thumbnailUrl: char.character, // Use GIF as thumbnail
      duration: const Duration(seconds: 0),
      category: 'Character',
      vimeoUrl: '',
      uploadStatus: '',
    );
  }

  // Factory for Reaction VODs
  factory MiniVod.fromReaction(Reaction react) {
    return MiniVod(
      id: react.vimeoId,
      name: react.name1,
      videoUrl: react.videoUrl.isNotEmpty ? react.videoUrl.first : react.vimeoUrl ?? '',
      thumbnailUrl: react.vimeoThumbnailUrl,
      duration: const Duration(seconds: 0), // fetched async later
      category: 'Reaction',
      vimeoUrl: react.vimeoUrl ?? '',
      uploadStatus: react.uploadStatus ?? '',
    );
  }
}
