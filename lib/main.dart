import 'dart:async';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:floreo/role_selection_interface.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// 🔥 NEW IMPORTS
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

const appId = "54bf8a5095374303aa14ff23c73bac0d";
const token =
    "007eJxTYLguVb0xuTNRxmmO7ffjgXVbVLik5u82lv8suL1WsNTK9poCg6lJUppFoqmBpamxuYmxgXFioqFJWpqRcbK5cVJiskHKpaDXmQ2BjAxLSp0ZGRkgEMTnZUhJzc0PT00qzk/OTi1hYAAA72ghqA==";
const channel = "demoWebsocket";

enum UserRole { therapist, client }

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 REQUIRED for media_kit
  MediaKit.ensureInitialized();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RoleSelectionScreen(),
    ),
  );
}

class MyApp extends StatefulWidget {
  MyApp({Key? key, this.selectedRole}) : super(key: key);
  UserRole? selectedRole = UserRole.therapist;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  bool isMuted = false;

  // 🔥 VIDEO MODE
  String? selectedVideoUrl;
  bool isVideoMode = false;
  bool showVideoLibrary = false;

  // 🔥 MEDIA KIT PLAYER

//late final Player _player;
//late final VideoController _videoController;




  final List<Map<String, String>> availableVideos = [
    {
      'title': 'Bee Video',
      'url':
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    },
    {
      'title': 'Butterfly Video',
      'url':
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    },
    {
      'title': 'Relaxation Video',
      'url':
          'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
    },
  ];
// For media_kit_video 0.0.4 ONLY
late final Player _player;
late VideoController _videoController;

@override
void initState() {
  super.initState();
  _player = Player();
  _videoController = VideoController(_player);
 //initVideoController();
  initAgora();
}

// Future<void> _initVideoController() async {
//   _videoController =  VideoController(
//     _player
//   );
//   //reate(_player.handle);
//   setState(() {});
// }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (connection, uid, elapsed) {
          setState(() => _remoteUid = uid);
        },
        onUserOffline: (connection, uid, reason) {
          setState(() => _remoteUid = null);
        },
        onError: (error, msg) {
          print("-----------------------------------------❌ Agora Error: $error - $msg----------------------------");
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _disposeAgora() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  void dispose() {
  _player?.dispose();
  _disposeAgora();
    super.dispose();
  }

  // 🔥 VIDEO SELECT
  void _selectVideo(String url, String title) async {
    print("🎬 Selected: $title");

    await _player?.open(Media(url));

    setState(() {
      selectedVideoUrl = url;
      isVideoMode = true;
      showVideoLibrary = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _remoteVideo()),

          // LOCAL CAMERA
          Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 150,
              height: 200,
              child: _localUserJoined
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),

          if (showVideoLibrary) _videoLibraryWindow(),

          if (widget.selectedRole == UserRole.therapist) _bottomControls(),
        ],
      ),
    );
  }

  // 🔥 REMOTE VIEW SWITCH
  Widget _remoteVideo() {
    // VIDEO MODE
  if (isVideoMode && _videoController != null) {
  return Center(
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: Video(controller: _videoController!),
    ),
  );
}

    // NORMAL CALL
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channel),
        ),
      );
    }

    return Text(
      widget.selectedRole == UserRole.therapist
          ? "Waiting for client..."
          : "Waiting for therapist...",
      style: const TextStyle(color: Colors.white),
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
            icon: Icons.video_library,
            onTap: () {
              setState(() {
                showVideoLibrary = !showVideoLibrary;
              });
            },
          ),
          _circleButton(
            icon: Icons.videocam,
            onTap: () {
              setState(() {
                isVideoMode = false;
                selectedVideoUrl = null;
              });
            },
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

  // 🔥 VIDEO LIBRARY
  Widget _videoLibraryWindow() {
    return Positioned(
      left: 20,
      right: 20,
      top: 100,
      bottom: 100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "Select Video",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => showVideoLibrary = false),
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                itemCount: availableVideos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemBuilder: (context, index) {
                  final video = availableVideos[index];
                  return GestureDetector(
                    onTap: () => _selectVideo(video['url']!, video['title']!),
                    child: Card(
                      color: Colors.white10,
                      child: Center(
                        child: Text(
                          video['title']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
