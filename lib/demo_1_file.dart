import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:video_player/video_player.dart';

const appId = "9bbcfb22bb73429fa08643c4da2fcc0b";
const token =
    "007eJxTYNhxbMulxrbZqsE7c0Jl7+l2cG6tn9Hy7t/rDZVrL2y7oK+lwGCZlJSclmRklJRkbmxiZJmWaGBhZmKcbJKSaJSWnGyQ9FricWZDICOD9ZVpDIxQCOILM6TllJaUpBaFZaak5jsn5uQ4FhQwMAAAiAco+A==";
const channel = "flutterVideoCallApp";

const videoUrl =
    "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4";

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  late WebSocketChannel socket;
  String role = "";
  String sessionId = "session_123";
  bool isSocketConnected = false;

  late VideoPlayerController _videoController;
  bool isVideoInitialized = false;
  bool isPlaying = false;

  bool isMuted = false;
  bool isVideoOff = false;
  bool showControls = true;

  List<_VideoReaction> reactions = [];

  bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  @override
  void initState() {
    super.initState();
    initAgora();
    initVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isSocketConnected) {
      role = isTablet(context) ? "therapist" : "client";
      connectSocket();
      isSocketConnected = true;
    }
  }

  /// ---------------- VIDEO ----------------
  Future<void> initVideo() async {
    _videoController = VideoPlayerController.network(videoUrl);
    await _videoController.initialize();
    await _videoController.pause();

    setState(() => isVideoInitialized = true);
  }

  /// ---------------- SOCKET ----------------
  void connectSocket() {
    socket = WebSocketChannel.connect(
      Uri.parse('ws://192.168.29.75:3000'),
    );

    socket.sink.add(jsonEncode({
      "type": "JOIN",
      "role": role,
      "sessionId": sessionId,
    }));

    socket.stream.listen((message) {
      final data = jsonDecode(message);
      handleSocketEvent(data);
    });
  }

  void handleSocketEvent(Map data) {
    final type = data['type'];

    /// 🔥 REACTION RECEIVE (BOTH SIDES) - SYNCHRONIZED
    if (type == "REACTION") {
      final path = data['path'] as String;
      final sentTimestamp = data['timestamp'] as int;
      _showReactionDelayed(path, sentTimestamp);
      return;
    }

    /// Only client syncs video
    if (role != "client") return;

    final position = data['position'] ?? 0;
    final timestamp = data['timestamp'] ?? 0;

    final delay =
        (DateTime.now().millisecondsSinceEpoch - timestamp) / 1000;
    final correctedPosition = position + delay;

    if (!isVideoInitialized) return;

    if (type == "PLAY") {
      _videoController.seekTo(Duration(seconds: correctedPosition.toInt()));
      _videoController.play();
      setState(() => isPlaying = true);
    }

    if (type == "PAUSE") {
      _videoController.pause();
      setState(() => isPlaying = false);
    }

    if (type == "SEEK") {
      _videoController.seekTo(Duration(seconds: position.toInt()));
    }
  }

  void sendEvent(String type, {double position = 0}) {
    socket.sink.add(jsonEncode({
      "type": type,
      "position": position,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    }));
  }

  /// ---------------- REACTIONS ----------------
  void _sendReaction(String path) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Send reaction with timestamp for synchronization
    socket.sink.add(jsonEncode({
      "type": "REACTION",
      "path": path,
      "timestamp": timestamp,
    }));

    // Show locally with delay for sync
    _showReactionDelayed(path, timestamp);
  }

  void _showReactionDelayed(String path, int sentTimestamp) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDiff = currentTime - sentTimestamp;

    // Calculate delay to ensure both devices show at same time
    // Use a fixed 500ms delay from when message was sent
    final delayMs = max(0, 500 - timeDiff);

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _addReaction(path);
      }
    });
  }

  void _addReaction(String path) {
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;

    final reaction = _VideoReaction(
      DateTime.now().microsecondsSinceEpoch.toString(),
      path,
      random.nextDouble() * (screenWidth - 60),
    );

    /// limit (optional safety)
    if (reactions.length > 30) {
      reactions.removeAt(0);
    }

    setState(() => reactions.add(reaction));

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() =>
            reactions.removeWhere((r) => r.id == reaction.id));
      }
    });
  }

  /// ---------------- AGORA ----------------
  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await _engine.enableVideo();

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (_, uid, __) {
          setState(() => _remoteUid = uid);
        },
        onUserOffline: (_, __, ___) {
          setState(() => _remoteUid = null);
        },
      ),
    );

    await _engine.startPreview();

    await _engine.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Widget floatingUserView() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channel),
        ),
      );
    }

    return Center(
      child: Text(
        role == "client"
            ? "Waiting for therapist..."
            : "Waiting for client...",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    socket.sink.close();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isVideoInitialized)
            Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  ),
                ),
                _videoOverlayControls(),
              ],
            ),

          Positioned(
            bottom: 100,
            right: 50,
            child: Container(
              width: 150,
              height: 180,
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.white)),
              child: floatingUserView(),
            ),
          ),

          /// 🔥 MULTIPLE UNIQUE REACTIONS
          ...reactions.map((r) => _floatingReaction(r)).toList(),

          if (showControls) _bottomControls(),
        ],
      ),
    );
  }

  Widget _videoOverlayControls() {
    if (role != "therapist") return const SizedBox();

    return Positioned.fill(
      child: Center(
        child: IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white, size: 50),
          onPressed: () {
            setState(() => isPlaying = !isPlaying);

            if (isPlaying) {
              _videoController.play();
              sendEvent("PLAY",
                  position:
                      _videoController.value.position.inSeconds.toDouble());
            } else {
              _videoController.pause();
              sendEvent("PAUSE");
            }
          },
        ),
      ),
    );
  }

  Widget _bottomControls() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleButton(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            onTap: () {
              setState(() => isMuted = !isMuted);
              _engine.muteLocalAudioStream(isMuted);
            },
          ),
          _circleButton(
            icon: Icons.video_collection,
            onTap: _showReactions,
          ),
          _circleButton(
            icon: Icons.call_end,
            color: Colors.red,
            onTap: () async {
              await _engine.leaveChannel();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return CircleAvatar(
      backgroundColor: Colors.black54,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
      ),
    );
  }

  void _showReactions() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             _reactionButton("assets/reactions/chutimanthonglue-cartoon-1142.gif"),
              _reactionButton("assets/reactions/tilixia-summer-clap-hands-6897.gif"),
              _reactionButton("assets/reactions/tilixia-summer-sad-22096.gif"),
          ],
        );
      },
    );
  }

  Widget _reactionButton(String path) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _sendReaction(path);
      },
      child: Image.asset(path, width: 120),
    );
  }

  Widget _floatingReaction(_VideoReaction reaction) {
    return Positioned(
      key: ValueKey(reaction.id),
      bottom: 120,
      left: reaction.startX,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(seconds: 2),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, -200 * value),
            child: Opacity(
              opacity: 1 - value,
              child: Image.asset(reaction.path, width: 50),
            ),
          );
        },
      ),
    );
  }
}

class _VideoReaction {
  final String id;
  final String path;
  final double startX;

  _VideoReaction(this.id, this.path, this.startX);
}