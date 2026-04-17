
import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:video_player/video_player.dart';

const appId = "9bbcfb22bb73429fa08643c4da2fcc0b";
const token =
    "007eJxTYNi3clLMklOlk9c7l+6cKS6jwvQ/supwTOSlW+/OMEkePPFfgcEyKSk5LcnIKCnJ3NjEyDIt0cDCzMQ42SQl0SgtOdkgiWXJg8yGQEYG35sBLIwMEAjiCzOk5ZSWlKQWhWWmpOY7J+bkOBYUMDAAAB1uJ6I=";
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
  /// ✅ AUTO ROLE
  String role = "";
  String sessionId = "session_123";
  bool isSocketConnected = false;

  late VideoPlayerController _videoController;
  bool isVideoInitialized = false;
  bool isPlaying = false;

  bool isMuted = false;
  bool isVideoOff = false;
  bool showControls = true;
    bool isScreenSharing = false;

  List<_VideoReaction> reactions = [];
  /// ✅ DEVICE DETECTION
  bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  @override
  void initState() {
    super.initState();
    initAgora();
    connectSocket();
    initVideo();
  }
  /// ✅ ROLE + SOCKET INIT
    @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isSocketConnected) {
      role = isTablet(context) ? "therapist" : "client";
      connectSocket();
      isSocketConnected = true;
    }
  }



  Future<void> initVideo() async {
    _videoController = VideoPlayerController.network(videoUrl);
    await _videoController.initialize();
    await _videoController.pause();

    setState(() => isVideoInitialized = true);
  }

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
      if (role == "client") {
        handleClientEvent(data);
      }
    });
  }

  void handleClientEvent(Map data) {
    final type = data['type'];
    final position = data['position'] ?? 0;
    final timestamp = data['timestamp'] ?? 0;

    final delay =
        (DateTime.now().millisecondsSinceEpoch - timestamp) / 1000;
    final correctedPosition = position + delay;

    if (!isVideoInitialized) return;

    if (type == "PLAY") {
      _videoController
          .seekTo(Duration(seconds: correctedPosition.toInt()));
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

  @override
  void dispose() {
    _videoController.dispose();
    socket.sink.close();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 🎥 Remote Agora Video
          Center(child: _remoteVideo()),

          /// 🎬 Video Player + Overlay Controls
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

          /// 🎥 Local Camera
          Positioned(
            top: 40,
            left: 10,
            child: Container(
              width: 100,
              height: 150,
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.white)),
              child: _localUserJoined
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),

        /// 🔥 FLOATING VIDEO REACTIONS
            ...reactions.map((r) => _floatingReaction(r)).toList(),

            /// 🎛 CONTROLS
            if (showControls) _bottomControls(),
        ],  /// Bottom Controls (mute/end call)
  
        //  if (role == "therapist") _bottomControls(),
      ),
    );
  }

  Widget _videoOverlayControls() {
    if (role != "therapist") return const SizedBox();

    return Positioned.fill(
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _overlayButton(
              icon: Icons.replay_10,
              onTap: () {
                final current =
                    _videoController.value.position.inSeconds;
                final newPos = (current - 10).clamp(0, 99999);

                _videoController.seekTo(Duration(seconds: newPos));
                sendEvent("SEEK", position: newPos.toDouble());
              },
            ),
            const SizedBox(width: 20),
            _overlayButton(
              icon: isPlaying ? Icons.pause : Icons.play_arrow,
              onTap: () {
                setState(() => isPlaying = !isPlaying);

                if (isPlaying) {
                  _videoController.play();
                  sendEvent("PLAY",
                      position: _videoController.value.position.inSeconds
                          .toDouble());
                } else {
                  _videoController.pause();
                  sendEvent("PAUSE");
                }
              },
            ),
            const SizedBox(width: 20),
            _overlayButton(
              icon: Icons.forward_10,
              onTap: () {
                final current =
                    _videoController.value.position.inSeconds;
                final newPos = current + 10;

                _videoController.seekTo(Duration(seconds: newPos));
                sendEvent("SEEK", position: newPos.toDouble());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 30),
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
            icon: isVideoOff ? Icons.videocam_off : Icons.videocam,
            onTap: () {
              setState(() => isVideoOff = !isVideoOff);
              _engine.muteLocalVideoStream(isVideoOff);
            },
          ),
          _circleButton(
            icon: Icons.cameraswitch,
            onTap: () {
              _engine.switchCamera();
            },
          ),
          // _circleButton(
          //   icon: isScreenSharing
          //       ? Icons.stop_screen_share
          //       : Icons.screen_share,
          //   onTap: () async {
          //     setState(() => isScreenSharing = !isScreenSharing);
          //     if (isScreenSharing) {
          //       await _engine.startScreenCapture(
          //         const ScreenCaptureParameters2(captureVideo: true),
          //       );
          //     } else {
          //       await _engine.stopScreenCapture();
          //     }
          //   },
          // ),

          /// 🎥 VIDEO REACTIONS BUTTON
          _circleButton(
            icon: Icons.video_collection_rounded,
            onTap: _showReactions,
          ),

          /// ❌ END CALL
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


  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channel),
        ),
      );
    }
    return const Center(
      child: Text("Waiting for user...",
          style: TextStyle(color: Colors.white)),
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
  
  /// 🎥 SHOW VIDEO REACTIONS ROW
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

        setState(() {
          reactions.add(_VideoReaction(
            path,
            (MediaQuery.of(context).size.width * 0.4
            ) +
                (reactions.length % 4) * 60,
          ));
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && reactions.isNotEmpty) {
            setState(() => reactions.removeAt(0));
          }
        });
      },
      child: Image.asset(path, width: 150)
    );
  }

  /// 🔥 FLOATING ANIMATION
  Widget _floatingReaction(_VideoReaction reaction) {
    return Positioned(
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
              child: Image.asset(
                reaction.path,
                width: 50,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoReaction {
  final String path;
  final double startX;

  _VideoReaction(this.path, this.startX);

}