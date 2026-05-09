// ─────────────────────────────────────────────────────────────
// THERAPY VIDEO ITEM MODEL  — with safe fromJson deserializers
// ─────────────────────────────────────────────────────────────

class TherapyVideoItemModel {
  final List<Message> message;

  TherapyVideoItemModel({required this.message});

  factory TherapyVideoItemModel.fromJson(Map<String, dynamic> json) {
    // The API wraps results under a "message" key.
    final raw = json['message'];
    final List<dynamic> list = raw is List ? raw : [];
    return TherapyVideoItemModel(
      message: list
          .whereType<Map<String, dynamic>>()
          .map(Message.fromJson)
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class Message {
  final Therapy therapy;
  final List<TopicElement> topics;

  Message({required this.therapy, required this.topics});

  factory Message.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['topics'];
    return Message(
      therapy: Therapy.fromJson(
          (json['therapy'] as Map<String, dynamic>?) ?? {}),
      topics: (rawTopics is List)
          ? rawTopics
              .whereType<Map<String, dynamic>>()
              .map(TopicElement.fromJson)
              .toList()
          : [],
    );
  }
}

// ─────────────────────────────────────────────────────────────
class Therapy {
  final String name;
  final String therapyType;

  Therapy({required this.name, required this.therapyType});

  factory Therapy.fromJson(Map<String, dynamic> json) => Therapy(
        name: (json['name'] as String?) ?? '',
        therapyType: (json['therapy_type'] as String?)        // snake_case
            ?? (json['therapyType'] as String?)               // camelCase
            ?? (json['name'] as String?)                      // fallback
            ?? '',
      );
}

// ─────────────────────────────────────────────────────────────
class TopicElement {
  final TopicTopic topic;
  final List<SubtopicElement> subtopics;

  TopicElement({required this.topic, required this.subtopics});

  factory TopicElement.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['subtopics'];
    return TopicElement(
      topic: TopicTopic.fromJson(
          (json['topic'] as Map<String, dynamic>?) ?? {}),
      subtopics: (rawSubs is List)
          ? rawSubs
              .whereType<Map<String, dynamic>>()
              .map(SubtopicElement.fromJson)
              .toList()
          : [],
    );
  }
}

// ─────────────────────────────────────────────────────────────
class SubtopicElement {
  final SubtopicSubtopic subtopic;
  final List<Content> contents;

  SubtopicElement({required this.subtopic, required this.contents});

  factory SubtopicElement.fromJson(Map<String, dynamic> json) {
    final rawContents = json['contents'];
    return SubtopicElement(
      subtopic: SubtopicSubtopic.fromJson(
          (json['subtopic'] as Map<String, dynamic>?) ?? {}),
      contents: (rawContents is List)
          ? rawContents
              .whereType<Map<String, dynamic>>()
              .map(Content.fromJson)
              .toList()
          : [],
    );
  }
}

// ─────────────────────────────────────────────────────────────
class Content {
  final String name;
  final String title;
  final String? video;
  final String videoType;
  final String? videoLink;
  final String videoUrl;

  Content({
    required this.name,
    required this.title,
    required this.video,
    required this.videoType,
    required this.videoLink,
    required this.videoUrl,
  });

  factory Content.fromJson(Map<String, dynamic> json) => Content(
        name:  (json['name']  as String?) ?? '',
        title: (json['title'] as String?) ?? '',

        // Direct mp4 file — stored under "video" key
        video: json['video'] as String?,

        // Type field — try both snake_case and camelCase
        videoType: (json['video_type'] as String?)
            ?? (json['videoType'] as String?)
            ?? '',

        // External URL — try both snake_case and camelCase
        videoLink: (json['video_link'] as String?)
            ?? (json['videoLink'] as String?),

        // Pre-resolved URL (may be set by server regardless of type)
        videoUrl: (json['video_url'] as String?)
            ?? (json['videoUrl'] as String?)
            ?? '',
      );
}

// ─────────────────────────────────────────────────────────────
class SubtopicSubtopic {
  final String name;
  final String subTopicName;

  SubtopicSubtopic({required this.name, required this.subTopicName});

  factory SubtopicSubtopic.fromJson(Map<String, dynamic> json) =>
      SubtopicSubtopic(
        name: (json['name'] as String?) ?? '',
        subTopicName: (json['sub_topic_name'] as String?)   // snake_case
            ?? (json['subTopicName'] as String?)            // camelCase
            ?? (json['name'] as String?)                    // fallback
            ?? '',
      );
}

// ─────────────────────────────────────────────────────────────
class TopicTopic {
  final String name;
  final String topicName;

  TopicTopic({required this.name, required this.topicName});

  factory TopicTopic.fromJson(Map<String, dynamic> json) => TopicTopic(
        name: (json['name'] as String?) ?? '',
        topicName: (json['topic_name'] as String?)          // snake_case
            ?? (json['topicName'] as String?)               // camelCase
            ?? (json['name'] as String?)                    // fallback
            ?? '',
      );
}
