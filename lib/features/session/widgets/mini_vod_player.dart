import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MiniVodPlayer extends StatefulWidget {
  final String videoUrl;
  const MiniVodPlayer({required this.videoUrl});

  @override
  State<MiniVodPlayer> createState() => MiniVodPlayerState();
}

class MiniVodPlayerState extends State<MiniVodPlayer> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.videoUrl));
    _player.setPlaylistMode(PlaylistMode.loop); // auto loop
  }

  @override
  void didUpdateWidget(MiniVodPlayer old) {
    super.didUpdateWidget(old);
    if (old.videoUrl != widget.videoUrl) {
      _player.open(Media(widget.videoUrl));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Video(
          controller: _controller,
          controls: NoVideoControls, // no controls
        ),
      ),
    );
  }
}