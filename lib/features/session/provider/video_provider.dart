import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/therpy_video_item_model.dart';
import '../models/video_item.dart';

// ─────────────────────────────────────────────────────────────
// HELPER: Convert API response → MainTopic list for the UI
// ─────────────────────────────────────────────────────────────
List<MainTopic> _mapApiToTopics(TherapyVideoItemModel model) {
  final List<MainTopic> result = [];

  for (final therapyMsg in model.message) {
    if (therapyMsg.topics.isEmpty) continue;

    final List<SubTopic> subTopics = [];

    for (final topicEl in therapyMsg.topics) {
      for (final subtopicEl in topicEl.subtopics) {
        final videos = subtopicEl.contents.map((c) {
          return VideoItem(
            title: c.title,
            url: c.videoUrl,
            thumbnail: '',
          );
        }).toList();

        if (videos.isEmpty) continue;

        subTopics.add(SubTopic(
          title:
              '${topicEl.topic.topicName} › ${subtopicEl.subtopic.subTopicName}',
          videos: videos,
        ));
      }
    }

    if (subTopics.isEmpty) continue;

    result.add(MainTopic(
      title: therapyMsg.therapy.therapyType,
      subTopics: subTopics,
    ));
  }

  return result;
}

// ─────────────────────────────────────────────────────────────
// VIDEO PROVIDER
// ─────────────────────────────────────────────────────────────
class VideoProvider extends ChangeNotifier {
  late final Player _player;
  late final VideoController videoController;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _bufferSub;
  StreamSubscription? _playSub;

  // ── Library data from API ──────────────────
  List<MainTopic> topics = [];
  bool isLoadingTopics = false;
  String? topicsError;

  static const String _apiUrl =
      'https://only-clapped-bride.ngrok-free.dev/api/method/floreo.api.therapist_api.v1.get_full_structure';

  // ── Playback state ─────────────────────────
  String? selectedVideoUrl;
  String? selectedThumbnail;

  bool isVideoMode    = false;
  bool isVideoPlaying = false;
  bool showLibrary    = false;
  bool isBuffering    = false;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  double volume   = 1.0;
  bool isVolMuted = false;

  VideoProvider() {
    _player = Player();
    videoController = VideoController(_player);

    // Position listener
    _posSub = _player.stream.position.listen((p) {
      position = p;
      notifyListeners();
    });

    // Duration listener
    _durSub = _player.stream.duration.listen((d) {
      duration = d;
      notifyListeners();
    });

    // Buffering listener
    _bufferSub = _player.stream.buffering.listen((b) {
      isBuffering = b;
      notifyListeners();
    });

    // Playing state listener
    _playSub = _player.stream.playing.listen((playing) {
      isVideoPlaying = playing;
      notifyListeners();
    });

    // Auto-fetch topics on creation
    fetchTopics();
  }

  Player get player => _player;

  // ─────────────────────────────────────────────
  // FETCH TOPICS FROM API
  // ─────────────────────────────────────────────
  Future<void> fetchTopics() async {
    isLoadingTopics = true;
    topicsError = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final model = TherapyVideoItemModel.fromJson(json);
        topics = _mapApiToTopics(model);
        topicsError = null;
      } else {
        topicsError = 'Server error: ${response.statusCode}';
        debugPrint('fetchTopics HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      topicsError = 'Failed to load videos. Please retry.';
      debugPrint('fetchTopics error: $e');
    } finally {
      isLoadingTopics = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // YouTube detection
  // ─────────────────────────────────────────────
  bool get isYoutube {
    if (selectedVideoUrl == null) return false;
    return selectedVideoUrl!.contains('youtube.com') ||
        selectedVideoUrl!.contains('youtu.be');
  }

  // ─────────────────────────────────────────────
  // SELECT FROM LIBRARY
  // ─────────────────────────────────────────────
  Future<void> selectVideo(VideoItem item) async {
    isBuffering = true;
    notifyListeners();

    await _player.open(Media(item.url), play: true);

    selectedVideoUrl  = item.url;
    selectedThumbnail = item.thumbnail;

    isVideoMode = true;
    showLibrary = false;

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // PLAY FROM URL (YouTube + MP4)
  // ─────────────────────────────────────────────
  Future<void> playFromUrl(String url) async {
    try {
      isBuffering = true;
      notifyListeners();

      selectedVideoUrl  = url;
      selectedThumbnail = _extractThumbnail(url);

      // YOUTUBE → skip media_kit
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        isVideoMode    = true;
        isVideoPlaying = true;
        showLibrary    = false;
        isBuffering    = false;
        notifyListeners();
        return;
      }

      // NORMAL VIDEO
      await _player.open(Media(url), play: true);

      isVideoMode = true;
      showLibrary = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error playing URL: $e');
    }
  }

  // ─────────────────────────────────────────────
  // THUMBNAIL EXTRACTOR
  // ─────────────────────────────────────────────
  String? _extractThumbnail(String url) {
    try {
      final uri = Uri.parse(url);

      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        String? id;

        if (uri.host.contains('youtu.be')) {
          id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        } else {
          id = uri.queryParameters['v'];
        }

        if (id != null) {
          return 'https://img.youtube.com/vi/$id/0.jpg';
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // CONTROLS
  // ─────────────────────────────────────────────
  Future<void> pause() async => _player.pause();

  Future<void> resume() async => _player.play();

  Future<void> togglePlayPause() async {
    isVideoPlaying ? await pause() : await resume();
  }

  Future<void> seek(Duration to) async {
    await _player.seek(to);
    position = to;
    notifyListeners();
  }

  Future<void> skipBack() async => seek(
        Duration(
          milliseconds:
              (position.inMilliseconds - 10000)
                  .clamp(0, duration.inMilliseconds),
        ),
      );

  Future<void> skipForward() async => seek(
        Duration(
          milliseconds:
              (position.inMilliseconds + 10000)
                  .clamp(0, duration.inMilliseconds),
        ),
      );

  Future<void> setVolume(double v) async {
    await _player.setVolume(v * 100);
    volume = v;
    isVolMuted = v == 0;
    notifyListeners();
  }

  Future<void> toggleMute() async =>
      setVolume(isVolMuted ? volume.clamp(0.1, 1.0) : 0);

  void toggleLibrary() {
    showLibrary = !showLibrary;
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.pause();
    await _player.stop();

    isVideoMode    = false;
    isVideoPlaying = false;
    isBuffering    = false;
    selectedVideoUrl  = null;
    selectedThumbnail = null;

    notifyListeners();
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _bufferSub?.cancel();
    _playSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}