import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/video_item.dart';


final List<MainTopic> allTopics = [

  // 1. Speech Therapy
  MainTopic(
    title: 'Speech Therapy',
    subTopics: [
      SubTopic(
        title: 'Articulation Therapy',
        videos: [
          VideoItem(
            title: 'Walk Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/walk_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?1',
          ),
        ],
      ),
      SubTopic(
        title: 'Phonology',
        videos: [
          VideoItem(
            title: 'Fly Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/fly_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?4',
          ),
        ],
      ),
      SubTopic(
        title: 'Childhood Apraxia of Speech (CAS)',
        videos: [
          VideoItem(
            title: 'Dance Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/dance_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?5',
          ),
        ],
      ),
      SubTopic(
        title: 'Dysarthria',
        videos: [
          VideoItem(
            title: 'Climb Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/climb_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?6',
          ),
        ],
      ),
    ],
  ),

  // 2. Occupational Therapy
  MainTopic(
    title: 'Occupational Therapy',
    subTopics: [
      SubTopic(
        title: 'Sensory Integration',
        videos: [
          VideoItem(
            title: 'Stomp Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/stomp_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?2',
          ),
        ],
      ),
      SubTopic(
        title: 'Fine Motor Skills',
        videos: [
          VideoItem(
            title: 'Stand Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/stand_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?3',
          ),
        ],
      ),
      SubTopic(
        title: 'Activities of Daily Living (ADL)',
        videos: [
          VideoItem(
            title: 'Walk Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/walk_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?1',
          ),
        ],
      ),
      SubTopic(
        title: 'Cognitive Rehabilitation',
        videos: [
          VideoItem(
            title: 'Dance Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/dance_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?5',
          ),
        ],
      ),
    ],
  ),

  // 3. Applied Behavior Analysis
  MainTopic(
    title: 'Applied Behavior Analysis',
    subTopics: [
      SubTopic(
        title: 'Discrete Trial Training (DTT)',
        videos: [
          VideoItem(
            title: 'Climb Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/climb_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?6',
          ),
        ],
      ),
      SubTopic(
        title: 'Natural Environment Teaching (NET)',
        videos: [
          VideoItem(
            title: 'Fly Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/fly_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?4',
          ),
        ],
      ),
      SubTopic(
        title: 'Verbal Behavior Therapy',
        videos: [
          VideoItem(
            title: 'Stomp Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/stomp_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?2',
          ),
        ],
      ),
      SubTopic(
        title: 'Behavior Intervention Plans (BIP)',
        videos: [
          VideoItem(
            title: 'Stand Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/stand_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?3',
          ),
        ],
      ),
    ],
  ),

  // 4. Psychology / Counseling
  MainTopic(
    title: 'Psychology/Counseling',
    subTopics: [
      SubTopic(
        title: 'Cognitive Behavioral Therapy (CBT)',
        videos: [
          VideoItem(
            title: 'Walk Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/walk_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?1',
          ),
        ],
      ),
      SubTopic(
        title: 'Play Therapy',
        videos: [
          VideoItem(
            title: 'Dance Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/dance_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?5',
          ),
        ],
      ),
      SubTopic(
        title: 'Family Therapy',
        videos: [
          VideoItem(
            title: 'Climb Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/climb_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?6',
          ),
        ],
      ),
      SubTopic(
        title: 'Mindfulness & Stress Management',
        videos: [
          VideoItem(
            title: 'Fly Video',
            url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/fly_animation.mp4',
            thumbnail: 'https://picsum.photos/300/200?4',
          ),
        ],
      ),
    ],
  ),

];
 const List<VideoItem> kAvailableVideos = [
  VideoItem(
    title: 'Walk Video',
    url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/walk_animation.mp4',
    thumbnail: 'https://picsum.photos/300/200?1',
  ),
   VideoItem(
    title: 'Fly Video',
    url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/fly_animation.mp4',
    thumbnail: 'https://picsum.photos/300/200?4',
  ),
  VideoItem(
    title: 'Dance Video',
    url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/dance_animation.mp4',
    thumbnail: 'https://picsum.photos/300/200?5',
  ),
  VideoItem(
    title: 'Climb Video',
    url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/climb_animation.mp4',
    thumbnail: 'https://picsum.photos/300/200?6',
  ),
  VideoItem(
    title: 'Stomp Video',
    url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/stomp_animation.mp4',
    thumbnail: 'https://picsum.photos/300/200?2',
  ),
  VideoItem(
    title: 'Stand Video',
    url: 'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/stand_animation.mp4',
    thumbnail: 'https://picsum.photos/300/200?3',
  ),
 
];

class VideoProvider extends ChangeNotifier {
  late final Player _player;
  late final VideoController videoController;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _bufferSub;
  StreamSubscription? _playSub;

  String? selectedVideoUrl;
  String? selectedThumbnail;

  bool isVideoMode    = false;
  bool isVideoPlaying = false;
  bool showLibrary    = false;
  bool isBuffering    = false;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  double volume = 1.0;
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
  }

  Player get player => _player;

  // ─────────────────────────────────────────────
  // 🔥 YouTube detection
  // ─────────────────────────────────────────────
  bool get isYoutube {
    if (selectedVideoUrl == null) return false;
    return selectedVideoUrl!.contains('youtube.com') ||
           selectedVideoUrl!.contains('youtu.be');
  }

  // ─────────────────────────────────────────────
  // SELECT FROM GRID (MP4 only)
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

      // ✅ YOUTUBE → skip media_kit
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        isVideoMode    = true;
        isVideoPlaying = true;
        showLibrary    = false;
        isBuffering    = false;

        notifyListeners();
        return;
      }

      // ✅ NORMAL VIDEO
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

      if (uri.host.contains('youtube.com') ||
          uri.host.contains('youtu.be')) {
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

    isVideoMode = false;
    isVideoPlaying = false;
    isBuffering = false;
    selectedVideoUrl = null;
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