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
  String connectionStatus = "Connecting...";

  late VideoPlayerController _videoController;
  bool isVideoInitialized = false;
  bool isPlaying = false;

  bool isMuted = false;
  bool isVideoOff = false;
  bool showControls = true;
  bool isScreenSharing = false;  // ✅ SCREEN SHARING STATE
  bool showVideoLibrary = false; // ✅ VIDEO LIBRARY WINDOW

  // ✅ AVAILABLE VIDEOS FOR SELECTION
  final List<Map<String, String>> availableVideos = [
    {
      'title': 'Bee Video',
      'url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'thumbnail': 'assets/images/bee_thumb.jpg',
    },
    {
      'title': 'Butterfly Video',
      'url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'thumbnail': 'assets/images/butterfly_thumb.jpg',
    },
    {
      'title': 'Relaxation Video',
      'url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      'thumbnail': 'assets/images/relax_thumb.jpg',
    },
    {
      'title': 'Nature Sounds',
      'url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
      'thumbnail': 'assets/images/nature_thumb.jpg',
    },
    // Add more videos here as needed
  ];

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
    print("🔌 CONNECTING TO WEBSOCKET as $role");
    setState(() => connectionStatus = "Connecting...");

    socket = WebSocketChannel.connect(
      Uri.parse('ws://192.168.29.75:3000'),
    );

    socket.sink.add(jsonEncode({
      "type": "JOIN",
      "role": role,
      "sessionId": sessionId,
    }));

    print("📤 SENT JOIN: $role");

    socket.stream.listen((message) {
      print("📨 RAW MESSAGE: $message");
      setState(() => connectionStatus = "Connected ✅");
      final data = jsonDecode(message);
      handleSocketEvent(data);
    }, onError: (error) {
      print("❌ WEBSOCKET ERROR: $error");
      setState(() => connectionStatus = "Error: $error");
    }, onDone: () {
      print("🔚 WEBSOCKET DONE");
      setState(() => connectionStatus = "Disconnected");
    });
  }

  void handleSocketEvent(Map data) {
    final type = data['type'];
    print("📨 RECEIVED: $type from ${data['role'] ?? 'unknown'}");

    /// 🔥 REACTION RECEIVE (BOTH SIDES) - SYNCHRONIZED
    if (type == "REACTION") {
      final path = data['path'] as String;
      final sentTimestamp = data['timestamp'] as int;
      print("-------------------------🎯 REACTION RECEIVED: $path at $sentTimestamp -----------------");
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

  /// ---------------- SCREEN SHARING ----------------
  void _toggleScreenShare() async {
    setState(() {
      isScreenSharing = !isScreenSharing;
      showVideoLibrary = isScreenSharing;
    });

    if (isScreenSharing) {
      print("🖥️ SCREEN SHARING ENABLED - Showing video library");
      // Could add actual screen sharing here if needed
      // await _engine.startScreenCapture(const ScreenCaptureParameters2(captureVideo: true));
    } else {
      print("🖥️ SCREEN SHARING DISABLED - Back to normal video call");
      showVideoLibrary = false;
      // await _engine.stopScreenCapture();
    }
  }

  /// ✅ SELECT VIDEO FROM LIBRARY
  Future<void> _selectVideo(String videoUrl, String title) async {
    print("🎬 SELECTING VIDEO: $title ($videoUrl)");

    // Dispose current video
    if (isVideoInitialized) {
      await _videoController.dispose();
      setState(() => isVideoInitialized = false);
    }

    // Load new video
    _videoController = VideoPlayerController.network(videoUrl);
    await _videoController.initialize();
    await _videoController.pause();

    setState(() {
      isVideoInitialized = true;
      isPlaying = false;
    });

    print("✅ VIDEO LOADED: $title");

    // Close video library after selection
    setState(() => showVideoLibrary = false);
  }

  /// ---------------- VIDEO LIBRARY WINDOW ----------------
  Widget _videoLibraryWindow() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 100,
      top: 100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "🎬 Select Video to Share",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => showVideoLibrary = false),
                  ),
                ],
              ),
            ),

            // Video Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: availableVideos.length,
                itemBuilder: (context, index) {
                  final video = availableVideos[index];
                  return _videoLibraryItem(video);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoLibraryItem(Map<String, String> video) {
    return GestureDetector(
      onTap: () => _selectVideo(video['url']!, video['title']!),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Thumbnail placeholder (you can add actual thumbnails later)
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.video_library,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video['title']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              "Tap to select",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendReaction(String path) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    print("🚀 SENDING REACTION: $path at $timestamp");

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

    print("⏰ SHOWING REACTION: $path in ${delayMs}ms (diff: ${timeDiff}ms)");

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        print("🎉 DISPLAYING REACTION: $path");
        _addReaction(path);
      }
    });
  }

  void _addReaction(String path) {
    print("🎨 ADDING REACTION: $path");
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;

    final reaction = _VideoReaction(
      DateTime.now().microsecondsSinceEpoch.toString(),
      path,
      random.nextDouble() * (screenWidth - 60),
    );

    print("📍 REACTION POSITION: ${reaction.startX}");

    /// limit (optional safety)
    if (reactions.length > 30) {
      reactions.removeAt(0);
    }

    setState(() => reactions.add(reaction));
    print("✅ REACTION ADDED TO LIST: ${reactions.length} total");

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() =>
            reactions.removeWhere((r) => r.id == reaction.id));
        print("🗑️ REACTION REMOVED: ${reaction.id}");
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

          /// 🎬 VIDEO LIBRARY WINDOW (when screen sharing)
          if (showVideoLibrary) _videoLibraryWindow(),

          /// 🔌 CONNECTION STATUS (DEBUG)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Role: $role\nStatus: $connectionStatus",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

          if (showControls) _bottomControls(),
        ],
      ),
    );
  }

  Widget _videoOverlayControls() {
    // Hide controls when video library is open
    if (role != "therapist" || showVideoLibrary) return const SizedBox();

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
          // ✅ SCREEN SHARE BUTTON
          _circleButton(
            icon: isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            onTap: _toggleScreenShare,
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
        return Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _reactionButton("assets/reactions/chutimanthonglue-cartoon-1142.gif"),
              _reactionButton("assets/reactions/tilixia-summer-clap-hands-6897.gif"),
              _reactionButton("assets/reactions/tilixia-summer-sad-22096.gif"),
              // Test button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  print("🧪 TEST: Showing reaction locally");
                  _addReaction("assets/reactions/chutimanthonglue-cartoon-1142.gif");
                },
                child: const Text("Test Local"),
              ),
            ],
          ),
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