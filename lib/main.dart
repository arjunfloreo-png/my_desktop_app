import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:floreo/role_selection_interface.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

const appId = "54bf8a5095374303aa14ff23c73bac0d";
const token =
    "007eJxTYMjOLd+p5HdVR8B2icrHD2uW2mms46zuaXrjedGErWXHw70KDKYmSWkWiaYGlqbG5ibGBsaJiYYmaWlGxsnmxkmJyQYp91++y2wIZGTQkn7DwsgAgSA+L0NKam5+eGpScX5ydmoJAwMAgWUjxg==";
const channel = "demoWebsocket";

enum UserRole { therapist, client }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  // ------------------------- audio and video of client and therapist -------------------------
  bool isTherpistMuted = false;
  bool isClientMuted = false;
  bool isTherpistvideoMuted = false;
  bool isClientvideoMuted = false;

  String? selectedVideoUrl;
  bool isVideoMode = false;
  bool showVideoLibrary = false;
  bool isVideoPlaying = false;

  // video timeline state
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  // volume state (0.0 – 1.0)
  double _videoVolume = 1.0;
  bool _isVolumeMuted = false;

  late final Player _player;
  late VideoController _videoController;

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

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _positionSub = _player.stream.position.listen((pos) {
      if (mounted) setState(() => _videoPosition = pos);
    });

    _durationSub = _player.stream.duration.listen((dur) {
      if (mounted) setState(() => _videoDuration = dur);
    });

    initAgora();
  }

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
          print("❌ Agora Error: $error - $msg");
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
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    _disposeAgora();
    super.dispose();
  }

  void _selectVideo(String url, String title) async {
    print("🎬 Selected: $title");
    await _player.open(Media(url));
    await _player.play();
    setState(() {
      selectedVideoUrl = url;
      isVideoMode = true;
      isVideoPlaying = true;
      showVideoLibrary = false;
    });
  }

  // ── Live badge ──────────────────────────────────────────────
  Widget _liveBadge(String name) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "LIVE",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Main 3-column layout ────────────────────────────
          Column(
            children: [
              Row(
                children: [
                  _liveBadge("Therapist"),
                  Spacer(),
                  _liveBadge("Client"),
                  SizedBox(width: 16),
                ],
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── LEFT: Therapist camera + controls below ─────
                    //  Padding wraps the whole left column:
                    //    left:12  = gap from screen edge
                    //    right:8  = gap between therapist panel and center
                    //    top/bottom:12 = vertical breathing room
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 12,
                        bottom: 12,
                        right: 8,
                      ),
                      child: SizedBox(
                        width: 280,
                        child: Column(
                          children: [
                            // camera fills available space
                            Expanded(
                              child: ClipRRect(
                                //  rounded corners on camera panel
                                borderRadius: BorderRadius.circular(12),
                                child: _localUserJoined
                                    ? Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          AgoraVideoView(
                                            controller: VideoViewController(
                                              rtcEngine: _engine,
                                              canvas: const VideoCanvas(uid: 0),
                                            ),
                                          ),
                                          if (widget.selectedRole ==
                                              UserRole.therapist)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _smallCircleButton(
                                                  icon: isTherpistMuted
                                                      ? Icons.mic_off
                                                      : Icons.mic,
                                                  onTap: () {
                                                    setState(
                                                      () => isTherpistMuted =
                                                          !isTherpistMuted,
                                                    );
                                                    _engine
                                                        .muteLocalAudioStream(
                                                          isTherpistMuted,
                                                        );
                                                  },
                                                ),
                                                const SizedBox(width: 12),
                                                _smallCircleButton(
                                                  icon: isTherpistvideoMuted
                                                      ? Icons.videocam_off
                                                      : Icons.videocam,
                                                  onTap: () {
                                                    setState(
                                                      () => isTherpistvideoMuted =
                                                          !isTherpistvideoMuted,
                                                    );
                                                    _engine
                                                        .muteLocalVideoStream(
                                                          isTherpistvideoMuted,
                                                        );
                                                  },
                                                ),
                                              ],
                                            ),
                                        ],
                                      )
                                    : const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // mic + video toggle buttons below therapist camera
                          ],
                        ),
                      ),
                    ),

                    // ── CENTER: Video / placeholder + controls below ─
                    Expanded(
                      child: Padding(
                        // vertical padding only — horizontal handled by side panels
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: isVideoMode
                                    ? AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Video(
                                          controller: _videoController,
                                          controls: NoVideoControls,
                                        ),
                                      )
                                    : Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                // Handle onTap: () {
                                                setState(
                                                  () => showVideoLibrary =
                                                      !showVideoLibrary,
                                                );
                                              },
                                              child: const Text(
                                                'Go LIVE',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            // controls bar directly below center
                            if (widget.selectedRole == UserRole.therapist)
                              _bottomControls(),
                          ],
                        ),
                      ),
                    ),

                    // ── RIGHT: Client camera + end call below ────────
                    //  Padding wraps the whole right column:
                    //    right:12  = gap from screen edge
                    //    left:8    = gap between center and client panel
                    //    top/bottom:12 = vertical breathing room
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        top: 12,
                        bottom: 12,
                        right: 12,
                      ),
                      child: SizedBox(
                        width: 280,
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _remoteUid != null
                                    ? Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          AgoraVideoView(
                                            controller:
                                                VideoViewController.remote(
                                                  rtcEngine: _engine,
                                                  canvas: VideoCanvas(
                                                    uid: _remoteUid,
                                                  ),
                                                  connection:
                                                      const RtcConnection(
                                                        channelId: channel,
                                                      ),
                                                ),
                                          ),
                                          if (widget.selectedRole ==
                                              UserRole.client)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _smallCircleButton(
                                                  icon: isClientMuted
                                                      ? Icons.mic_off
                                                      : Icons.mic,
                                                  onTap: () {
                                                    setState(
                                                      () => isClientMuted =
                                                          !isClientMuted,
                                                    );
                                                    _engine
                                                        .muteLocalAudioStream(
                                                          isClientMuted,
                                                        );
                                                  },
                                                ),
                                                const SizedBox(width: 12),
                                                _smallCircleButton(
                                                  icon: isClientvideoMuted
                                                      ? Icons.videocam_off
                                                      : Icons.videocam,
                                                  onTap: () {
                                                    setState(
                                                      () => isClientvideoMuted =
                                                          !isClientvideoMuted,
                                                    );
                                                    _engine
                                                        .muteLocalVideoStream(
                                                          isClientvideoMuted,
                                                        );
                                                  },
                                                ),
                                              ],
                                            ),
                                        ],
                                      )
                                    : Center(
                                        child: Text(
                                          widget.selectedRole ==
                                                  UserRole.therapist
                                              ? "Waiting for client..."
                                              : "Waiting for therapist...",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // end call button below client camera
                            // if (widget.selectedRole == UserRole.therapist)
                            //   Row(
                            //     mainAxisAlignment: MainAxisAlignment.center,
                            //     children: [
                            //       _smallCircleButton(
                            //         icon: Icons.call_end,
                            //         color: Colors.red,
                            //         onTap: () async {
                            //           await _player.stop();
                            //           await _engine.leaveChannel();
                            //           if (mounted) Navigator.pop(context);
                            //         },
                            //       ),
                            //     ],
                            //   ),

                            // const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Video library overlay ───────────────────────────
          if (showVideoLibrary) _videoLibraryWindow(),
        ],
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────
  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Bottom controls ─────────────────────────────────────────
  Widget _bottomControls() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Timeline row (only when video is active) ────────
          if (isVideoMode) ...[
            Row(
              children: [
                Text(
                  _formatDuration(_videoPosition),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white38,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white24,
                    ),
                    child: Slider(
                      min: 0,
                      max: _videoDuration.inMilliseconds.toDouble().clamp(
                        1,
                        double.infinity,
                      ),
                      value: _videoPosition.inMilliseconds.toDouble().clamp(
                        0,
                        _videoDuration.inMilliseconds.toDouble().clamp(
                          1,
                          double.infinity,
                        ),
                      ),
                      onChanged: (value) async {
                        final seekTo = Duration(milliseconds: value.toInt());
                        await _player.seek(seekTo);
                        setState(() => _videoPosition = seekTo);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_videoDuration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // ── Volume row (only when video is active) ──────────
          if (isVideoMode) ...[
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final newMuted = !_isVolumeMuted;
                    await _player.setVolume(newMuted ? 0 : _videoVolume * 100);
                    setState(() => _isVolumeMuted = newMuted);
                  },
                  child: Icon(
                    _isVolumeMuted
                        ? Icons.volume_off
                        : _videoVolume < 0.3
                        ? Icons.volume_mute
                        : _videoVolume < 0.7
                        ? Icons.volume_down
                        : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white38,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white24,
                    ),
                    child: Slider(
                      min: 0,
                      max: 1.0,
                      value: _isVolumeMuted ? 0 : _videoVolume,
                      onChanged: (value) async {
                        await _player.setVolume(value * 100);
                        setState(() {
                          _videoVolume = value;
                          _isVolumeMuted = value == 0;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isVolumeMuted ? '0%' : '${(_videoVolume * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // ── Buttons row ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // video library button always visible
              // _circleButton(
              //   icon: Icons.video_library,
              //   onTap: () {
              //     setState(() => showVideoLibrary = !showVideoLibrary);
              //   },
              // ),

              // Video controls — only when video is active
              if (isVideoMode) ...[
                   _circleButton(
                icon: Icons.video_library,
                onTap: () {
                  setState(() => showVideoLibrary = !showVideoLibrary);
                },
              ),
              backforwardButton(
                "Take Me Back",
                () async {
                  final target = Duration(
                    milliseconds: (_videoPosition.inMilliseconds - 10000)
                        .clamp(0, _videoDuration.inMilliseconds),
                  );
                  await _player.seek(target);
                  setState(() => _videoPosition = target);
                },
              ),
                // _circleButton(
                //   icon: Icons.replay_10,
                //   onTap: () async {
                //     final target = Duration(
                //       milliseconds: (_videoPosition.inMilliseconds - 10000)
                //           .clamp(0, _videoDuration.inMilliseconds),
                //     );
                //     await _player.seek(target);
                //     setState(() => _videoPosition = target);
                //   },
                // ),
                playPauseButton(
                  isVideoPlaying ?   "Pause A Question" : "  Asking",
                  () async {
                    if (isVideoPlaying) {
                      await _player.pause();
                    } else {
                      await _player.play();
                    }
                    setState(() => isVideoPlaying = !isVideoPlaying);
                  },
                ),
                // _circleButton(
                //   icon: isVideoPlaying ? Icons.pause : Icons.play_arrow,
                //   onTap: () async {
                //     if (isVideoPlaying) {
                //       await _player.pause();
                //     } else {
                //       await _player.play();
                //     }
                //     setState(() => isVideoPlaying = !isVideoPlaying);
                //   },
                // ),
                forwardButton("Dive In", () async {
                  final target = Duration(
                    milliseconds: (_videoPosition.inMilliseconds + 10000)
                        .clamp(0, _videoDuration.inMilliseconds),
                  );
                  await _player.seek(target);
                  setState(() => _videoPosition = target);
                }),
                // _circleButton(
                //   icon: Icons.forward_10,
                //   onTap: () async {
                //     final target = Duration(
                //       milliseconds: (_videoPosition.inMilliseconds + 10000)
                //           .clamp(0, _videoDuration.inMilliseconds),
                //     );
                //     await _player.seek(target);
                //     setState(() => _videoPosition = target);
                //   },
                // ),
                _circleButton(
                  icon: Icons.stop,
                  onTap: () async {
                    await _player.stop();
                    setState(() {
                      isVideoMode = false;
                      isVideoPlaying = false;
                      selectedVideoUrl = null;
                      _videoPosition = Duration.zero;
                      _videoDuration = Duration.zero;
                    });
                  },
                ),
              ],
            ],
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

  Widget playPauseButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xFF265cfc),
          gradient: LinearGradient(
            colors: [
              Color(0xFF265cfc),
              Color(0xff5451fc),
              Color(0xff763ffa),
              Color(0xff931dfa),
              Color(0xff6c46fb),
              Color(0xff4455fb)
            ],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(children: [
          SizedBox(width: 12,),
          Icon(Icons.message, color: Colors.white,size: 16,),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.white)),
        ],)
        // ElevatedButton.icon(
        //   style: ElevatedButton.styleFrom(
            
        //   ),
        //   onPressed: onTap,
        //   label: Text(text),
        //   icon: Icon(Icons.message),
        // ),
      ),
    );
  }
 Widget backforwardButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xFF265cfc),
          gradient: LinearGradient(
            colors: [
              Color(0xFF265cfc),
              Color(0xff5451fc),
              Color(0xff763ffa),
              Color(0xff931dfa),
              Color(0xff6c46fb),
              Color(0xff4455fb)
            ],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(child: Text(text, style: TextStyle(color: Colors.white)))
        // ElevatedButton.icon(
        //   style: ElevatedButton.styleFrom(
            
        //   ),
        //   onPressed: onTap,
        //   label: Text(text),
        //   icon: Icon(Icons.message),
        // ),
      ),
    );
  }
   Widget forwardButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xFF265cfc),
          gradient: LinearGradient(
            colors: [
              Color(0xFF265cfc),
              Color(0xff5451fc),
              Color(0xff763ffa),
              Color(0xff931dfa),
              Color(0xff6c46fb),
              Color(0xff4455fb)
            ],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(child: Text(text, style: TextStyle(color: Colors.white)))
        // ElevatedButton.icon(
        //   style: ElevatedButton.styleFrom(
            
        //   ),
        //   onPressed: onTap,
        //   label: Text(text),
        //   icon: Icon(Icons.message),
        // ),
      ),
    );
  }

  Widget endSession(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xFF265cfc),
          gradient: LinearGradient(
            colors: [
              Color(0xFF265cfc),
              Color(0xff5451fc),
              Color(0xff763ffa),
              Color(0xff931dfa),
              Color(0xff6c46fb),
              Color(0xff4455fb)
            ],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(child: Text(text, style: TextStyle(color: Colors.white)))
        // ElevatedButton.icon(
        //   style: ElevatedButton.styleFrom(
            
        //   ),
        //   onPressed: onTap,
        //   label: Text(text),
        //   icon: Icon(Icons.message),
        // ),
      ),
    );
  }
  // smaller version used below therapist/client panels
  Widget _smallCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: CircleAvatar(
        backgroundColor: Colors.black54,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: color, size: 18),
          onPressed: onTap,
        ),
      ),
    );
  }

  // ── Video library overlay ────────────────────────────────────
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
