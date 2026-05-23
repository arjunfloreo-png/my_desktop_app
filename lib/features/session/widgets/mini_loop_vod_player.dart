import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MiniVodLoopPlayer extends StatefulWidget {
  final String url;

  const MiniVodLoopPlayer({
    required this.url,
  });

  @override
  State<MiniVodLoopPlayer> createState() =>
      MiniVodLoopPlayerState();
}

class MiniVodLoopPlayerState
    extends State<MiniVodLoopPlayer> {
  late final Player _player;
  late final VideoController _controller;

  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _player = Player();
    _controller = VideoController(_player);

    await _player.open(
      Media(widget.url),
    );

    await _player.setVolume(0);

    await _player.setPlaylistMode(
      PlaylistMode.loop,
    );

    _player.play();

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Container(
        color: Colors.black,
      );
    }

    return Video(
      controller: _controller,
      controls: NoVideoControls,
      fit: BoxFit.cover,
    );
  }
}