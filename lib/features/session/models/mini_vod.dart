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
  final String? character; // GIF path for characters

  MiniVod({
    required this.id,
    required this.name,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.category,
    required this.vimeoUrl,
    required this.uploadStatus,
    this.character,
  });

  // Factory for Character VODs
  factory MiniVod.fromCharacter(Character char) {
    return MiniVod(
      id: char.name1,
      name: char.name1,
      videoUrl: char.character,
      thumbnailUrl: char.character,
      duration: const Duration(seconds: 0),
      category: 'Character',
      vimeoUrl: '',
      uploadStatus: '',
      character: char.character, // Store GIF path
    );
  }

  // Factory for Reaction VODs
  factory MiniVod.fromReaction(Reaction react) {
    return MiniVod(
      id: react.vimeoId,
      name: react.name1,
      videoUrl: react.videoUrl.isNotEmpty ? react.videoUrl.first : react.vimeoUrl ?? '',
      thumbnailUrl: react.vimeoThumbnailUrl,
      duration: const Duration(seconds: 0),
      category: 'Reaction',
      vimeoUrl: react.vimeoUrl ?? '',
      uploadStatus: react.uploadStatus ?? '',
      character: null,
    );
  }
}
