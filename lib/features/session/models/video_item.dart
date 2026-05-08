//  class VideoItem {
//   final String title;
//   final String url;
//   final String thumbnail;

//   const VideoItem({
//     required this.title,
//     required this.url,
//     required this.thumbnail,
//   });
// }

// ─── Model Classes ───────────────────────────────────────────────────

class VideoItem {
  final String title;
  final String url;
  final String thumbnail;

  const VideoItem({
    required this.title,
    required this.url,
    required this.thumbnail,
  });
}

class SubTopic {
  final String title;
  final List<VideoItem> videos;

  const SubTopic({
    required this.title,
    required this.videos,
  });
}

class MainTopic {
  final String title;
  final List<SubTopic> subTopics;

  const MainTopic({
    required this.title,
    required this.subTopics,
  });
}