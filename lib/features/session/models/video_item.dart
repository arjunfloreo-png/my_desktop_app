// ─────────────────────────────────────────────────────────────
// VIDEO TYPE ENUM
// ─────────────────────────────────────────────────────────────
enum VideoType { mp4, external }

// ─────────────────────────────────────────────────────────────
// VIDEO ITEM
// ─────────────────────────────────────────────────────────────
class VideoItem {
  final String title;
  final String url;
  final String thumbnail;
  final VideoType videoType;

  const VideoItem({
    required this.title,
    required this.url,
    required this.thumbnail,
    required this.videoType,
  });

  bool get isMp4 => videoType == VideoType.mp4;
  bool get isExternal => videoType == VideoType.external;
}

// ─────────────────────────────────────────────────────────────
// SUB TOPIC
// ─────────────────────────────────────────────────────────────
class SubTopic {
  final String title;
  final List<VideoItem> videos;

  const SubTopic({
    required this.title,
    required this.videos,
  });
}

// ─────────────────────────────────────────────────────────────
// MAIN TOPIC
// ─────────────────────────────────────────────────────────────
class MainTopic {
  final String title;
  final List<SubTopic> subTopics;

  const MainTopic({
    required this.title,
    required this.subTopics,
  });
}
