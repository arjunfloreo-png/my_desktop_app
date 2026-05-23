class RewardBoxModel {
  final Message message;
  RewardBoxModel({required this.message});

  factory RewardBoxModel.fromJson(Map<String, dynamic> json) =>
      RewardBoxModel(message: Message.fromJson(json['message']));
}

class Message {
  final List<Character> reactions;
  final List<Character> characters;
  Message({required this.reactions, required this.characters});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        reactions: (json['reactions'] as List)
            .map((e) => Character.fromJson(e))
            .toList(),
        characters: (json['characters'] as List)
            .map((e) => Character.fromJson(e))
            .toList(),
      );
}

class Character {
  final String name1;
  final String vimeoId;
  final String uploadStatus;
  final String vimeoUrl;
  final String vimeoThumbnailUrl;
  final List<String> videoUrl;

  Character({
    required this.name1,
    required this.vimeoId,
    required this.uploadStatus,
    required this.vimeoUrl,
    required this.vimeoThumbnailUrl,
    required this.videoUrl,
  });

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        name1: json['name1'] ?? '',
        vimeoId: json['vimeo_id'] ?? '',
        uploadStatus: json['upload_status'] ?? '',
        vimeoUrl: json['vimeo_url'] ?? '',
        vimeoThumbnailUrl: json['vimeo_thumbnail_url'] ?? '',
        videoUrl: List<String>.from(json['video_url'] ?? []),
      );
}