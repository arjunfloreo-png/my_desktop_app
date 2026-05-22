// lib/models/mini_video_charater_reaction_model.dart

class MiniVideoCharaterReactionModel {
  Message message;

  MiniVideoCharaterReactionModel({
    required this.message,
  });

  factory MiniVideoCharaterReactionModel.fromJson(Map<String, dynamic> json) {
    return MiniVideoCharaterReactionModel(
      message: Message.fromJson(json['message'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message.toJson(),
  };
}

class Message {
  List<Character> reactions;
  List<Character> characters;

  Message({
    required this.reactions,
    required this.characters,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      reactions: (json['reactions'] as List?)
          ?.map((e) => Character.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      characters: (json['characters'] as List?)
          ?.map((e) => Character.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'reactions': reactions.map((e) => e.toJson()).toList(),
    'characters': characters.map((e) => e.toJson()).toList(),
  };
}

class Character {
  String name1;
  String vimeoId;
  String uploadStatus;
  String vimeoUrl;
  String videoUrl;

  Character({
    required this.name1,
    required this.vimeoId,
    required this.uploadStatus,
    required this.vimeoUrl,
    required this.videoUrl,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name1: json['name1'] ?? '',
      vimeoId: json['vimeo_id'] ?? '',
      uploadStatus: json['upload_status'] ?? '',
      vimeoUrl: json['vimeo_url'] ?? '',
      videoUrl: json['video_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name1': name1,
    'vimeo_id': vimeoId,
    'upload_status': uploadStatus,
    'vimeo_url': vimeoUrl,
    'video_url': videoUrl,
  };
}
