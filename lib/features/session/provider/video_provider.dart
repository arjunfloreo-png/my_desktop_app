import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../services/socket_service.dart';
import '../models/therpy_video_item_model.dart';
import '../models/video_item.dart';

List<MainTopic> _mapApiToTopics(TherapyVideoItemModel model) {
  final List<MainTopic> result = [];

  for (final therapyMsg in model.message) {
    if (therapyMsg.topics.isEmpty) continue;

    final List<SubTopic> subTopics = [];

    for (final topicEl in therapyMsg.topics) {
      for (final subtopicEl in topicEl.subtopics) {
        final videos = <VideoItem>[];

        for (final c in subtopicEl.contents) {
          final rawType = (c.videoType).trim().toLowerCase();

          final vType = rawType == 'mp4' ? VideoType.mp4 : VideoType.external;

          String url;

          if (vType == VideoType.mp4) {
            url = _nonEmpty(c.videoUrl) ?? '';
          } else {
            url = _nonEmpty(c.videoLink) ?? _nonEmpty(c.videoUrl) ?? '';
          }

          if (url.isEmpty) continue;

          videos.add(
            VideoItem(
              title: c.title.isNotEmpty ? c.title : c.name,
              url: url,
              thumbnail: '',
              videoType: vType,
            ),
          );
        }

        if (videos.isEmpty) continue;

        subTopics.add(
          SubTopic(
            title:
                '${topicEl.topic.topicName} › ${subtopicEl.subtopic.subTopicName}',
            videos: videos,
          ),
        );
      }
    }

    if (subTopics.isEmpty) continue;

    result.add(
      MainTopic(title: therapyMsg.therapy.therapyType, subTopics: subTopics),
    );
  }

  return result;
}

String? _nonEmpty(String? s) =>
    (s != null && s.trim().isNotEmpty) ? s.trim() : null;

class VideoProvider extends ChangeNotifier {
  late final Player _player;

  late final VideoController videoController;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _bufferSub;
  StreamSubscription? _playSub;

  List<MainTopic> topics = [];

  bool isLoadingTopics = false;

  String? topicsError;

  static const String _apiUrl =
      'https://fabric-unloader-spray.ngrok-free.dev/api/method/floreo.api.desktop_app.v1.get_full_structure';

  String? selectedVideoUrl;
  String? selectedThumbnail;

  VideoType? _currentVideoType;

  bool isVideoMode = false;
  bool isVideoPlaying = false;
  bool showLibrary = false;
  bool isBuffering = false;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  // ONLY FOR SLIDER/TIMER UI
  final ValueNotifier<int> progressNotifier = ValueNotifier(0);

  double volume = 1.0;

  bool isVolMuted = false;

  // EXTERNAL CONTROLS
  Future<void> Function()? externalPlay;
  Future<void> Function()? externalPause;
  Future<void> Function()? externalStop;

  Future<void> Function(Duration position)? externalSeek;

  VideoProvider() {
    _player = Player();

    videoController = VideoController(_player);

    // MP4 POSITION
    _posSub = _player.stream.position.listen((p) {
      if (!isExternal) {
        position = p;

        // ONLY UPDATE SLIDER
        progressNotifier.value++;
      }
    });

    // MP4 DURATION
    _durSub = _player.stream.duration.listen((d) {
      if (!isExternal) {
        duration = d;

        progressNotifier.value++;
      }
    });

    // BUFFERING
    _bufferSub = _player.stream.buffering.listen((b) {
      isBuffering = b;

      notifyListeners();
    });

    // PLAY / PAUSE
    _playSub = _player.stream.playing.listen((playing) {
      if (!isExternal) {
        isVideoPlaying = playing;

        notifyListeners();
      }
    });

    fetchTopics();
  }

  Player get player => _player;

  bool get isExternal => _currentVideoType == VideoType.external;

  bool get isYoutube => isExternal;

  // EXTERNAL PLAY STATE
  void setExternalPlayingState(bool playing) {
    if (!isExternal) return;

    // PREVENT EXTRA REBUILDS
    if (isVideoPlaying == playing) {
      return;
    }

    isVideoPlaying = playing;

    notifyListeners();
  }

  // FETCH API
  Future<void> fetchTopics() async {
    isLoadingTopics = true;

    topicsError = null;

    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;

        final model = TherapyVideoItemModel.fromJson(jsonMap);

        topics = _mapApiToTopics(model);
      } else {
        topicsError = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      topicsError = 'Failed to load videos';
    } finally {
      isLoadingTopics = false;

      notifyListeners();
    }
  }

  // SELECT VIDEO
  Future<void> selectVideo(VideoItem item) async {
  if (!isExternal && isVideoMode) {
    await _player.stop();
  }

  selectedVideoUrl = item.url;
  selectedThumbnail = item.thumbnail;
  _currentVideoType = item.videoType;
  isVideoMode = true;
  showLibrary = false;

  if (item.isExternal) {
    isVideoPlaying = true;
    isBuffering = false;
  } else {
    isBuffering = true;
    notifyListeners();
    await _player.open(Media(item.url), play: true);
  }

  // EXTRACT YT ID IF EXTERNAL
  String videoId = item.url;
  if (item.videoType == VideoType.external) {
    videoId = _extractYoutubeId(item.url) ?? item.url;
  }

  SocketService().selectVideo(
    videoId,
    item.url,
    title: item.title,
  );

  notifyListeners();
}

String? _extractYoutubeId(String url) {
  try {
    final uri = Uri.parse(url);
    
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    } else if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
  } catch (_) {}
  
  return null;
}

  // PLAY URL
  Future<void> playFromUrl(String url, {VideoType type = VideoType.mp4}) async {
    try {
      if (!isExternal && isVideoMode) {
        await _player.stop();
      }

      isBuffering = true;

      selectedVideoUrl = url;

      selectedThumbnail = _extractThumbnail(url);

      _currentVideoType = type;

      notifyListeners();

      if (type == VideoType.external) {
        isVideoMode = true;

        isVideoPlaying = true;

        showLibrary = false;

        isBuffering = false;

        notifyListeners();

        return;
      }

      await _player.open(Media(url), play: true);

      isVideoMode = true;

      showLibrary = false;

      notifyListeners();
    } catch (e) {
      debugPrint('playFromUrl error: $e');
    }
  }

  String? _extractThumbnail(String url) {
    try {
      final uri = Uri.parse(url);

      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        String? id;

        if (uri.host.contains('youtu.be')) {
          id = uri.pathSegments.first;
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

  // CONTROLS

  Future<void> pause() async {
    if (isExternal) {
      await externalPause?.call();

      isVideoPlaying = false;
    } else {
      await _player.pause();
    }
    SocketService().pauseVideo(position.inMilliseconds / 1000.0);

    notifyListeners();
  }

  Future<void> resume() async {
    if (isExternal) {
      await externalPlay?.call();

      isVideoPlaying = true;
    } else {
      await _player.play();
    }

    //select video on  web socket
    SocketService().playVideo(position.inMilliseconds / 1000.0);

    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    isVideoPlaying ? await pause() : await resume();
  }

  Future<void> seek(Duration to) async {
    if (isExternal) {
      await externalSeek?.call(to);

      position = to;
    } else {
      await _player.seek(to);

      position = to;
    }

    SocketService().seekVideo(to.inMilliseconds / 1000.0);

    // ONLY UPDATE SLIDER
    progressNotifier.value++;
  }

  Future<void> skipBack() async {
    await seek(
      Duration(
        milliseconds: (position.inMilliseconds - 5000).clamp(
          
          0,
          duration.inMilliseconds,
        ),
      ),
    );
  }

  Future<void> skipForward() async {
    await seek(
      Duration(
        milliseconds: (position.inMilliseconds + 5000).clamp(
          0,
          duration.inMilliseconds,
        ),
      ),
    );
  }

  Future<void> setVolume(double v) async {
    if (!isExternal) {
      await _player.setVolume(v * 100);
    }

    volume = v;

    isVolMuted = v == 0;

    // ← ADD

    SocketService().setVolume(v);

    notifyListeners();
  }

  Future<void> toggleMute() async {
    setVolume(isVolMuted ? volume.clamp(0.1, 1.0) : 0);
  }

  void toggleLibrary() {
    showLibrary = !showLibrary;

    notifyListeners();
  }

  Future<void> stop() async {
    if (isExternal) {
      await externalStop?.call();
    } else {
      await _player.pause();

      await _player.stop();
    }

    isVideoMode = false;

    isVideoPlaying = false;

    isBuffering = false;

    selectedVideoUrl = null;

    selectedThumbnail = null;

    _currentVideoType = null;

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

    progressNotifier.dispose();

    _player.dispose();

    super.dispose();
  }
}
