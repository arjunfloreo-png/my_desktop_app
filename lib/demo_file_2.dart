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

enum _ActionStyle { outline, soft, filled }

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

// ── Reward badge model ───────────────────────────────────────
class RewardBadge {
  final String label;
  final String emoji;
  final Color bgColor;
  final String name;
  RewardBadge({
    required this.label,
    required this.emoji,
    required this.bgColor,
    required this.name,
  });
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

  bool isTherpistMuted = false;
  bool isClientMuted = false;
  bool isTherpistvideoMuted = false;
  bool isClientvideoMuted = false;

  String? selectedVideoUrl;
  bool isVideoMode = false;
  bool showVideoLibrary = false;
  bool isVideoPlaying = false;

  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  double _videoVolume = 1.0;
  bool _isVolumeMuted = false;

  late final Player _player;
  late VideoController _videoController;

  // Reward badges — now dynamic, can add more
  final List<RewardBadge> _badges = [
    RewardBadge(label: 'Good Job',        emoji: '😊', bgColor: const Color(0xFFE53935), name: 'Name Here'),
    RewardBadge(label: "You're A Star",   emoji: '⭐', bgColor: const Color(0xFF1565C0), name: 'Name Here'),
    RewardBadge(label: 'Well Done',       emoji: '😎', bgColor: const Color(0xFF0D1B2A), name: 'Name Here'),
    RewardBadge(label: 'Fantastic Effort',emoji: '🤣', bgColor: const Color(0xFFE3F2FD), name: 'Name Here'),
    RewardBadge(label: 'Keep It Up',      emoji: '💪', bgColor: const Color(0xFF388E3C), name: 'Name Here'),
    RewardBadge(label: 'Super Work',      emoji: '🏆', bgColor: const Color(0xFFF57F17), name: 'Name Here'),
    RewardBadge(label: 'Amazing!',        emoji: '🎉', bgColor: const Color(0xFF6A1B9A), name: 'Name Here'),
    RewardBadge(label: 'Brilliant',       emoji: '🌟', bgColor: const Color(0xFF00838F), name: 'Name Here'),
  ];

  // Preset emoji options for the add-badge dialog
  static const List<String> _emojiOptions = [
    '😊','⭐','😎','🤣','💪','🏆','🎉','🌟',
    '🥳','❤️','🔥','👏','🦋','🌈','🎯','🧠',
    '🐣','🦄','🎀','🍀','🚀','💡','🎸','🌺',
  ];

  // Preset color options for the add-badge dialog
  static const List<Color> _colorOptions = [
    Color(0xFFE53935), Color(0xFF1565C0), Color(0xFF0D1B2A), Color(0xFFE3F2FD),
    Color(0xFF388E3C), Color(0xFFF57F17), Color(0xFF6A1B9A), Color(0xFF00838F),
    Color(0xFFAD1457), Color(0xFF4E342E), Color(0xFF546E7A), Color(0xFFFDD835),
  ];

  void _showAddBadgeDialog() {
    String selectedEmoji = _emojiOptions[0];
    Color selectedColor = _colorOptions[0];
    final labelController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add New Badge', style: TextStyle(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview
                    Center(
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: selectedColor, shape: BoxShape.circle),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(labelController.text.isEmpty ? 'Label' : labelController.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selectedColor.computeLuminance() < 0.4 ? Colors.white : Colors.black87,
                                fontSize: 8, fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(selectedEmoji, style: const TextStyle(fontSize: 22)),
                            Text(nameController.text.isEmpty ? 'Name' : nameController.text,
                              style: TextStyle(
                                color: selectedColor.computeLuminance() < 0.4 ? Colors.white70 : Colors.black54,
                                fontSize: 7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Label input
                    const Text('Label', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Great Work!',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Name input
                    const Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Alex',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Emoji picker
                    const Text('Emoji', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _emojiOptions.map((e) {
                        final isSelected = e == selectedEmoji;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedEmoji = e),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black12 : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected ? Border.all(color: Colors.black45) : null,
                            ),
                            child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Color picker
                    const Text('Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _colorOptions.map((c) {
                        final isSelected = c == selectedColor;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 2.5)
                                  : Border.all(color: Colors.black12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (labelController.text.trim().isEmpty) return;
                    setState(() {
                      _badges.add(RewardBadge(
                        label: labelController.text.trim(),
                        emoji: selectedEmoji,
                        bgColor: selectedColor,
                        name: nameController.text.trim().isEmpty ? 'Name Here' : nameController.text.trim(),
                      ));
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
          debugPrint("❌ Agora Error: $error - $msg");
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
    await _player.open(Media(url));
    await _player.play();
    setState(() {
      selectedVideoUrl = url;
      isVideoMode = true;
      isVideoPlaying = true;
      showVideoLibrary = false;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Main Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F0), // mint-green background
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── LEFT+CENTER: Video area ────────────────────
                Expanded(
                  child: Column(
                    children: [
                      // ── Main content area (video + cameras) ──
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Main video panel ──────────────
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  color: Colors.white,
                                  child: isVideoMode
                                      ? Video(
                                          controller: _videoController,
                                          controls: NoVideoControls,
                                        )
                                      : _videoPlaceholder(),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // ── Therapist + Client cameras stacked ──
                            SizedBox(
                              width: 200,
                              child: Column(
                                children: [
                                  // Therapist camera
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        color: Colors.black,
                                        child: Stack(
                                          children: [
                                            _localUserJoined
                                                ? AgoraVideoView(
                                                    controller:
                                                        VideoViewController(
                                                      rtcEngine: _engine,
                                                      canvas: const VideoCanvas(
                                                          uid: 0),
                                                    ),
                                                  )
                                                : const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white54,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                            // Therapist label
                                            Positioned(
                                              bottom: 6,
                                              left: 8,
                                              child: _livePill("Therapist"),
                                            ),
                                            // Therapist controls
                                            if (widget.selectedRole ==
                                                UserRole.therapist)
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Row(
                                                  children: [
                                                    _tinyIconBtn(
                                                      icon: isTherpistMuted
                                                          ? Icons.mic_off
                                                          : Icons.mic,
                                                      onTap: () {
                                                        setState(() =>
                                                            isTherpistMuted =
                                                                !isTherpistMuted);
                                                        _engine
                                                            .muteLocalAudioStream(
                                                                isTherpistMuted);
                                                      },
                                                    ),
                                                    const SizedBox(width: 4),
                                                    _tinyIconBtn(
                                                      icon: isTherpistvideoMuted
                                                          ? Icons.videocam_off
                                                          : Icons.videocam,
                                                      onTap: () {
                                                        setState(() =>
                                                            isTherpistvideoMuted =
                                                                !isTherpistvideoMuted);
                                                        _engine
                                                            .muteLocalVideoStream(
                                                                isTherpistvideoMuted);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Client camera
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        color: Colors.black87,
                                        child: Stack(
                                          children: [
                                            _remoteUid != null
                                                ? AgoraVideoView(
                                                    controller:
                                                        VideoViewController
                                                            .remote(
                                                      rtcEngine: _engine,
                                                      canvas: VideoCanvas(
                                                          uid: _remoteUid),
                                                      connection:
                                                          const RtcConnection(
                                                              channelId:
                                                                  channel),
                                                    ),
                                                  )
                                                : Center(
                                                    child: Text(
                                                      widget.selectedRole ==
                                                              UserRole.therapist
                                                          ? "Waiting for client..."
                                                          : "Waiting for therapist...",
                                                      style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 11,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                            // Client label
                                            Positioned(
                                              bottom: 6,
                                              left: 8,
                                              child: _livePill("Client"),
                                            ),
                                            // Client controls
                                            if (widget.selectedRole ==
                                                UserRole.client)
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Row(
                                                  children: [
                                                    _tinyIconBtn(
                                                      icon: isClientMuted
                                                          ? Icons.mic_off
                                                          : Icons.mic,
                                                      onTap: () {
                                                        setState(() =>
                                                            isClientMuted =
                                                                !isClientMuted);
                                                        _engine
                                                            .muteLocalAudioStream(
                                                                isClientMuted);
                                                      },
                                                    ),
                                                    const SizedBox(width: 4),
                                                    _tinyIconBtn(
                                                      icon: isClientvideoMuted
                                                          ? Icons.videocam_off
                                                          : Icons.videocam,
                                                      onTap: () {
                                                        setState(() =>
                                                            isClientvideoMuted =
                                                                !isClientvideoMuted);
                                                        _engine
                                                            .muteLocalVideoStream(
                                                                isClientvideoMuted);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Bottom Controls ────────────────────
                      if (widget.selectedRole == UserRole.therapist)
                        _bottomControlsBar(),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ── RIGHT: Reward badges panel ─────────────
                _rewardPanel(),
              ],
            ),
          ),

          // ── Video library overlay ─────────────────────────
          if (showVideoLibrary) _videoLibraryWindow(),
        ],
      ),
    );
  }

  // ── Video placeholder (no video selected) ───────────────────
  Widget _videoPlaceholder() {
    return Container(
      color: const Color(0xFFE8F5F0),
      child: Center(
        child: GestureDetector(
          onTap: () => setState(() => showVideoLibrary = !showVideoLibrary),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Go LIVE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Live pill badge ──────────────────────────────────────────
  Widget _livePill(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tiny icon button (on camera panels) ─────────────────────
  Widget _tinyIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  // ── Bottom controls bar ──────────────────────────────────────
  Widget _bottomControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        // border: Border.all(
        //   width: 4,
        //   color: Color(0xff00bd74)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Timeline + Volume row ──────────────────────────
          if (isVideoMode) ...[
            Row(
              children: [
                // Volume icon
                GestureDetector(
                  onTap: () async {
                    final newMuted = !_isVolumeMuted;
                    await _player.setVolume(newMuted ? 0 : _videoVolume * 100);
                    setState(() => _isVolumeMuted = newMuted);
                  },
                  child: Icon(
                    _isVolumeMuted
                        ? Icons.volume_off
                        : _videoVolume < 0.4
                            ? Icons.volume_down
                            : Icons.volume_up,
                    color: Color(0xff00bd74),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 6),

                // Volume slider
                SizedBox(
                  width: 100,
                  child: _thinSlider(
                    value: _isVolumeMuted ? 0 : _videoVolume,
                    max: 1.0,
                    onChanged: (v) async {
                      await _player.setVolume(v * 100);
                      setState(() {
                        _videoVolume = v;
                        _isVolumeMuted = v == 0;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // Timeline
                Expanded(
                  child: _thinSlider(
                    value: _videoPosition.inMilliseconds.toDouble().clamp(
                          0,
                          _videoDuration.inMilliseconds
                              .toDouble()
                              .clamp(1, double.infinity),
                        ),
                    max: _videoDuration.inMilliseconds
                        .toDouble()
                        .clamp(1, double.infinity),
                    onChanged: (v) async {
                      final seekTo = Duration(milliseconds: v.toInt());
                      await _player.seek(seekTo);
                      setState(() => _videoPosition = seekTo);
                    },
                  ),
                ),

                const SizedBox(width: 8),
                Text(
                  '${_formatDuration(_videoPosition)}/${_formatDuration(_videoDuration)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ── Action buttons row ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
           

              // Take Me Back
              _actionButton(
                label: 'Take me back',
                style: _ActionStyle.soft,
                onTap: isVideoMode
                    ? () async {
                        final target = Duration(
                          milliseconds: (_videoPosition.inMilliseconds - 10000)
                              .clamp(0, _videoDuration.inMilliseconds),
                        );
                        await _player.seek(target);
                        setState(() => _videoPosition = target);
                      }
                    : null,
              ),
                 // Pose a Question (pause)
              _actionButton(
                label: isVideoPlaying ? 'Pose a Question' : '  Asking...',
                style: _ActionStyle.outline,
                onTap: isVideoMode
                    ? () async {
                        if (isVideoPlaying) {
                          await _player.pause();
                        } else {
                          await _player.play();
                        }
                        setState(() => isVideoPlaying = !isVideoPlaying);
                      }
                    : null,
              ),

              // Dive IN (forward / resume)
              _actionButton(
                label: 'Dive IN',
                style: _ActionStyle.filled,
                onTap: isVideoMode
                    ? () async {
                        final target = Duration(
                          milliseconds: (_videoPosition.inMilliseconds + 10000)
                              .clamp(0, _videoDuration.inMilliseconds),
                        );
                        await _player.seek(target);
                        setState(() => _videoPosition = target);
                      }
                    : null,
              ),

              // Let Me Share / video library
              _actionButton(
                label: 'LET\nME\nSHARE',
                style: _ActionStyle.outline,
                onTap: () => setState(() => showVideoLibrary = !showVideoLibrary),
                small: true,
              ),

                 _actionButton(
                label: 'End Session',
                style: _ActionStyle.filled,
                onTap: isVideoMode
                    ? () async {
                        final target = Duration(
                          milliseconds: (_videoPosition.inMilliseconds + 10000)
                              .clamp(0, _videoDuration.inMilliseconds),
                        );
                        await _player.seek(target);
                        setState(() => _videoPosition = target);
                      }
                    : null,
              ),
                // _actionButton(
                // label: 'End Session',
                // style: _ActionStyle.outline,
                // onTap: () => setState(() => showVideoLibrary = !showVideoLibrary),
                // small: true,
             // ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Thin slider ──────────────────────────────────────────────
  Widget _thinSlider({
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: Color(0xff00bd74),
        inactiveTrackColor: Colors.black12,
        thumbColor: Color(0xffdaf9ed),
        overlayColor: Colors.black12,
      ),
      child: Slider(value: value, min: 0, max: max, onChanged: onChanged),
    );
  }

  // ── Action button styles ─────────────────────────────────────
  Widget _actionButton({
    required String label,
    required _ActionStyle style,
    VoidCallback? onTap,
    bool small = false,
  }) {
    final isDisabled = onTap == null;

    BoxDecoration deco;
    TextStyle textStyle;

    switch (style) {
      case _ActionStyle.filled:
        deco = BoxDecoration(
          color: isDisabled ? Colors.black26 : Color(0xFF00bd74),
          borderRadius: BorderRadius.circular(30),
        );
        textStyle = const TextStyle(
          color:Color(0xffdaf9ed) ,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        );
        break;
      case _ActionStyle.soft:
        deco = BoxDecoration(
          color: isDisabled
              ? const Color(0xFF00bd74)
              : const Color(0xFF00bd74),
          borderRadius: BorderRadius.circular(30),
        );
        textStyle = TextStyle(
          color: isDisabled ? Color(0xffdaf9ed) : Color(0xffdaf9ed),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        );
        break;
      case _ActionStyle.outline:
        deco = BoxDecoration(
          color: Color(0xFF00bd74),
          border: Border.all(
            color: isDisabled ? Colors.black12 : Color(0xffdaf9ed) ,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(30),
        );
        textStyle = TextStyle(
          color: isDisabled ? Colors.black38 : Color(0xffdaf9ed) ,
          fontWeight: FontWeight.w600,
          fontSize: small ? 11 : 14,
        );
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 14 : 20,
          vertical: small ? 8 : 10,
        ),
        decoration: deco,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }

  // ── Reward badges panel ──────────────────────────────────────
  Widget _rewardPanel() {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Scrollable badge list ──────────────────────
          Expanded(
            child: ListView.separated(
              itemCount: _badges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _rewardBadge(_badges[i]),
            ),
          ),
          const SizedBox(height: 8),
          // ── Add badge button ───────────────────────────
          GestureDetector(
            onTap: _showAddBadgeDialog,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardBadge(RewardBadge badge) {
    final isDark = badge.bgColor.computeLuminance() < 0.4;
    final labelColor = isDark ? Colors.white : Colors.black87;
    final nameColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () {
        // TODO: send reward to client
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sent "${badge.label}" to ${badge.name}'),
            duration: const Duration(seconds: 1),
            backgroundColor: badge.bgColor,
          ),
        );
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: badge.bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: badge.bgColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Curved label text at top
            Text(
              badge.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(badge.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(
              badge.name,
              style: TextStyle(
                color: nameColor,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Video library overlay ────────────────────────────────────
  Widget _videoLibraryWindow() {
    return Positioned(
      left: 60,
      right: 140,
      top: 80,
      bottom: 120,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    "Select Video",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => showVideoLibrary = false),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: availableVideos.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.4,
                ),
                itemBuilder: (context, index) {
                  final video = availableVideos[index];
                  return GestureDetector(
                    onTap: () =>
                        _selectVideo(video['url']!, video['title']!),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFB2DFDB),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_outline,
                            size: 32,
                            color: Color(0xFF00796B),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            video['title']!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
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
