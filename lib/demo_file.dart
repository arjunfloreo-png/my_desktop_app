import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class OnlineMovPlayer extends StatefulWidget {
  const OnlineMovPlayer({super.key});

  @override
  State<OnlineMovPlayer> createState() => _OnlineMovPlayerState();
}

class _OnlineMovPlayerState extends State<OnlineMovPlayer> {
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();

    player = Player();
    controller = VideoController(player);

    player.open(
      Media(
        'https://example.com/video.mov',
      ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 800,
          height: 450,
          child: Video(controller: controller),
        ),
      ),
    );
  }
}