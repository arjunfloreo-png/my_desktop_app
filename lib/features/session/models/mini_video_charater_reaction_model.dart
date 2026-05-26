class RewardBoxModel {
  Message message;
  RewardBoxModel({
    required this.message,
  });
  factory RewardBoxModel.fromJson(Map<String, dynamic> json) {
    return RewardBoxModel(
      message: Message.fromJson(json['message']),
    );
  }
}

class Message {
  List<Reaction> reactions;
  List<Character> characters;
  Message({
    required this.reactions,
    required this.characters,
  });
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      reactions: (json['reactions'] as List? ?? [])
          .map((e) => Reaction.fromJson(e))
          .toList(),
      characters: (json['characters'] as List? ?? [])
          .map((e) => Character.fromJson(e))
          .toList(),
    );
  }
}

class Character {
  String name1;
  String character;
  
  Character({
    required this.name1,
    required this.character,
  });
  
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name1: json['name1'] ?? '',
      character: json['character'] ?? '',
    );
  }
}

class Reaction {
  String name1;
  String vimeoId;
  String uploadStatus;
  String? vimeoUrl;
  String? thumbnailUrl;
  List<String> videoUrl;
  String vimeoThumbnailUrl;

  Reaction({
    required this.name1,
    required this.vimeoId,
    required this.uploadStatus,
    this.vimeoUrl,
    this.thumbnailUrl,
    required this.videoUrl,
    required this.vimeoThumbnailUrl,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    final videoUrlRaw = json['video_url'];
    List<String> videoUrlList = [];
    
    if (videoUrlRaw is String && videoUrlRaw.isNotEmpty) {
      videoUrlList = [videoUrlRaw];
    } else if (videoUrlRaw is List) {
      videoUrlList = List<String>.from(videoUrlRaw.cast<String>());
    }

    return Reaction(
      name1: json['name1'] ?? '',
      vimeoId: json['vimeo_id'] ?? '',
      uploadStatus: json['upload_status'] ?? '',
      vimeoUrl: json['vimeo_url'],
      thumbnailUrl: json['thumbnail_url'],
      videoUrl: videoUrlList,
      vimeoThumbnailUrl: json['vimeo_thumbnail_url'] ?? '',
    );
  }
}
