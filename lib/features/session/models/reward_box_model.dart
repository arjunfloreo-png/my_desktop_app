class RewardBoxModel {
  final List<ReactionItem> reactions;
  final List<CharacterItem> characters;

  RewardBoxModel({required this.reactions, required this.characters});

  factory RewardBoxModel.fromJson(Map<String, dynamic> json) {
    final msg = json['message'] as Map<String, dynamic>;
    return RewardBoxModel(
      reactions: (msg['reactions'] as List)
          .map((e) => ReactionItem.fromJson(e))
          .toList(),
      characters: (msg['characters'] as List)
          .map((e) => CharacterItem.fromJson(e))
          .toList(),
    );
  }
}

class ReactionItem {
  final String name;
  final String gifPath;

  ReactionItem({required this.name, required this.gifPath});

  factory ReactionItem.fromJson(Map<String, dynamic> j) =>
      ReactionItem(name: j['name1'], gifPath: j['reactions']);
}

class CharacterItem {
  final String name;
  final String imagePath;

  CharacterItem({required this.name, required this.imagePath});

  factory CharacterItem.fromJson(Map<String, dynamic> j) =>
      CharacterItem(name: j['name1'], imagePath: j['character']);
}
