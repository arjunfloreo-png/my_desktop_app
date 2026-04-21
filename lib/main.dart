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
    enum UserRole { client, therapist }

extension UserRoleX on UserRole {
  bool get isTherapist => this == UserRole.therapist;
}

// ================= MAIN =================
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RoleSelectionScreen(),
  ));
}

/// ================= ROLE SELECTION =================
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Select Role",
                style: TextStyle(color: Colors.white, fontSize: 24)),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyApp(role: "therapist"),
                  ),
                );
              },
              child: const Text("Therapist"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyApp(role: "client"),
                  ),
                );
              },
              child: const Text("Client"),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= MAIN APP =================
class MyApp extends StatefulWidget {
  final String role;

  const MyApp({super.key, required this.role});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? _remoteUid;
  late RtcEngine _engine;

  late WebSocketChannel socket;

  late String role;
  String sessionId = "session_123";
  bool isSocketConnected = false;

  late VideoPlayerController _videoController;
  bool isVideoInitialized = false;
  bool isPlaying = false;

  bool isMuted = false;

  List<_VideoReaction> reactions = [];

  @override
  void initState() {
    super.initState();
    role = widget.role;

    initAgora();
    initVideo();
  }

  /// ================= VIDEO =================
  Future<void> initVideo() async {
    _videoController = VideoPlayerController.network(videoUrl);
    await _videoController.initialize();
    await _videoController.pause();

    setState(() => isVideoInitialized = true);
  }

  /// ================= SOCKET =================
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

    /// REACTIONS
    if (type == "REACTION") {
      _showReactionDelayed(
        data['path'],
        data['timestamp'],
      );
      return;
    }

    /// ONLY CLIENT SYNC VIDEO
    if (role != "client") return;

    final position = data['position'] ?? 0;
    final timestamp = data['timestamp'] ?? 0;

    final delay =
        (DateTime.now().millisecondsSinceEpoch - timestamp) / 1000;

    final correctedPosition = position + delay;

    if (!isVideoInitialized) return;

    if (type == "PLAY") {
      _videoController.seekTo(
        Duration(seconds: correctedPosition.toInt()),
      );
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

  /// ================= REACTIONS =================
  void _sendReaction(String path) {
    final ts = DateTime.now().millisecondsSinceEpoch;

    socket.sink.add(jsonEncode({
      "type": "REACTION",
      "path": path,
      "timestamp": ts,
    }));

    _showReactionDelayed(path, ts);
  }

  void _showReactionDelayed(String path, int ts) {
    final delay = max(
      0,
      500 - (DateTime.now().millisecondsSinceEpoch - ts),
    );

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _addReaction(path);
    });
  }

  void _addReaction(String path) {
    final random = Random();
    final width = MediaQuery.of(context).size.width;

    final reaction = _VideoReaction(
      DateTime.now().microsecondsSinceEpoch.toString(),
      path,
      random.nextDouble() * (width - 60),
    );

    setState(() => reactions.add(reaction));

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => reactions.removeWhere((r) => r.id == reaction.id));
      }
    });
  }

  /// ================= AGORA =================
  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();

    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    await _engine.enableVideo();

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          setState(() {});
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

    connectSocket();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isVideoInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            ),

          Positioned(
            bottom: 100,
            right: 40,
            child: SizedBox(
              width: 150,
              height: 180,
              child: _remoteView(),
            ),
          ),

          ...reactions.map(_floatingReaction).toList(),

          _controls(),
        ],
      ),
    );
  }

  Widget _remoteView() {
    if (_remoteUid == null) {
      return Center(
        child: Text(
          role == "client"
              ? "Waiting for therapist..."
              : "Waiting for client...",
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: const RtcConnection(channelId: channel),
      ),
    );
  }

  Widget _controls() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(isMuted ? Icons.mic_off : Icons.mic,
                color: Colors.white),
            onPressed: () {
              setState(() => isMuted = !isMuted);
              _engine.muteLocalAudioStream(isMuted);
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions, color: Colors.white),
            onPressed: _showReactions,
          ),
        ],
      ),
    );
  }

  void _showReactions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _reactionBtn("assets/reactions/1.gif"),
          _reactionBtn("assets/reactions/2.gif"),
        ],
      ),
    );
  }

  Widget _reactionBtn(String path) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _sendReaction(path);
      },
      child: Image.asset(path, width: 100),
    );
  }

  Widget _floatingReaction(_VideoReaction r) {
    return Positioned(
      left: r.x,
      bottom: 120,
      child: TweenAnimationBuilder(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 2),
        builder: (_, v, __) {
          return Opacity(
            opacity: 1 - v,
            child: Image.asset(r.path, width: 50),
          );
        },
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
}

/// ================= MODEL =================
class _VideoReaction {
  final String id;
  final String path;
  final double x;

  _VideoReaction(this.id, this.path, this.x);
}