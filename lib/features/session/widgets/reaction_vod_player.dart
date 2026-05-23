import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class FullVodPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onComplete;
  const FullVodPlayer({super.key, required this.videoUrl, required this.onComplete});

  @override
  State<FullVodPlayer> createState() => _FullVodPlayerState();
}

class _FullVodPlayerState extends State<FullVodPlayer> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.videoUrl));
    _player.stream.completed.listen((completed) {
      if (completed) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Video(
        controller: _controller,
        controls: NoVideoControls,
      ),
    );
  }
}