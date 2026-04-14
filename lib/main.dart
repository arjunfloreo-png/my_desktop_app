import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

const appId = "9bbcfb22bb73429fa08643c4da2fcc0b";
const token =
    "007eJxTYJjz7fcRo9++mWvOVotP+1KifIBJ13DJ29QFRyJ69338sG+lAoNlUlJyWpKRUVKSubGJkWVaooGFmYlxsklKolFacrJBUvzHu5kNgYwMC3/1sTIyQCCIL8yQllNaUpJaFJaZkprvnJiT41hQwMAAAPUPKpA=";
const channel = "flutterVideoCallApp";

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

  bool isMuted = false;
  bool isVideoOff = false;
  bool showControls = true;
  bool isScreenSharing = false;

  List<_VideoReaction> reactions = [];

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() => _remoteUid = null);
        },
      ),
    );

    await _engine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster);

    await _engine.enableVideo();
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
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => showControls = !showControls);
        },
        child: Stack(
          children: [
            /// 🎥 Remote Video
            Center(child: _remoteVideo()),

            /// 🎥 Local Video
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: const EdgeInsets.all(12),
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                ),
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
            if (showControls) _buildControls(),
          ],
        ),
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
    } else {
      return const Center(
        child: Text(
          'Waiting for user...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 30,
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
          _circleButton(
            icon: isScreenSharing
                ? Icons.stop_screen_share
                : Icons.screen_share,
            onTap: () async {
              setState(() => isScreenSharing = !isScreenSharing);
              if (isScreenSharing) {
                await _engine.startScreenCapture(
                  const ScreenCaptureParameters2(captureVideo: true),
                );
              } else {
                await _engine.stopScreenCapture();
              }
            },
          ),

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