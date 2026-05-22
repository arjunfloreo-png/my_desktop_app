import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class HoverVideoPreview extends StatefulWidget {
  final String videoUrl;

  const HoverVideoPreview({
    super.key,
    required this.videoUrl,
  });

  @override
  State<HoverVideoPreview> createState() => _HoverVideoPreviewState();
}

class _HoverVideoPreviewState extends State<HoverVideoPreview> {
  late final Player _player;
  late final VideoController _controller;

  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _player = Player();
      _controller = VideoController(_player);

      await _player.open(
        Media(
          widget.videoUrl,
          httpHeaders: const {
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      await _player.setVolume(0);

      await _player.setPlaylistMode(PlaylistMode.loop);

      _player.play();

      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      debugPrint('Hover preview error: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00bd74),
            ),
          ),
        ),
      );
    }

    return Video(
      controller: _controller,
      controls: NoVideoControls,
      fit: BoxFit.cover,
    );
  }
}