class TherapyVideoItemModel {
  List<Message> message;

  TherapyVideoItemModel({
    required this.message,
  });

  factory TherapyVideoItemModel.fromJson(Map<String, dynamic> json) {
    return TherapyVideoItemModel(
      message: (json['message'] as List)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Message {
  Therapy therapy;
  List<TopicElement> topics;

  Message({
    required this.therapy,
    required this.topics,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      therapy: Therapy.fromJson(json['therapy'] as Map<String, dynamic>),
      topics: (json['topics'] as List)
          .map((e) => TopicElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Therapy {
  String name;
  String therapyType;

  Therapy({
    required this.name,
    required this.therapyType,
  });

  factory Therapy.fromJson(Map<String, dynamic> json) {
    return Therapy(
      name: json['name'] as String,
      therapyType: json['therapy_type'] as String,
    );
  }
}

class TopicElement {
  TopicTopic topic;
  List<SubtopicElement> subtopics;

  TopicElement({
    required this.topic,
    required this.subtopics,
  });

  factory TopicElement.fromJson(Map<String, dynamic> json) {
    return TopicElement(
      topic: TopicTopic.fromJson(json['topic'] as Map<String, dynamic>),
      subtopics: (json['subtopics'] as List)
          .map((e) => SubtopicElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubtopicElement {
  SubtopicSubtopic subtopic;
  List<Content> contents;

  SubtopicElement({
    required this.subtopic,
    required this.contents,
  });

  factory SubtopicElement.fromJson(Map<String, dynamic> json) {
    return SubtopicElement(
      subtopic: SubtopicSubtopic.fromJson(
          json['subtopic'] as Map<String, dynamic>),
      contents: (json['contents'] as List)
          .map((e) => Content.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Content {
  String name;
  String title;
  String video;
  String videoUrl;

  Content({
    required this.name,
    required this.title,
    required this.video,
    required this.videoUrl,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      name: json['name'] as String,
      
      title: json['title'] as String,
      video: json['video'] as String,
      videoUrl: json['video_url'] as String,
    );
  }
}

class SubtopicSubtopic {
  String name;
  String subTopicName;

  SubtopicSubtopic({
    required this.name,
    required this.subTopicName,
  });

  factory SubtopicSubtopic.fromJson(Map<String, dynamic> json) {
    return SubtopicSubtopic(
      name: json['name'] as String,
      subTopicName: json['sub_topic_name'] as String,
    );
  }
}

class TopicTopic {
  String name;
  String topicName;

  TopicTopic({
    required this.name,
    required this.topicName,
  });

  factory TopicTopic.fromJson(Map<String, dynamic> json) {
    return TopicTopic(
      name: json['name'] as String,
      topicName: json['topic_name'] as String,
    );
  }
}