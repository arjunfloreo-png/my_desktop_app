import 'dart:async';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:floreo/role_selection_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

const appId = "54bf8a5095374303aa14ff23c73bac0d";
const token =
    "007eJxTYFBn2h12zpOp8Zz/mpl/OFZJndrwKZalTqfg2tmT/VcE+CIVGExNktIsEk0NLE2NzU2MDYwTEw1N0tKMjJPNjZMSkw1SJNQ+ZzYEMjJYnu1jZWSAQBCflyElNTc/PDWpOD85O7WEgQEAOsgiUA==";
const channel = "demoWebsocket";

enum UserRole { therapist, client }

enum _ActionStyle { filled, soft, outline, danger }

// ── Pause prompt messages shown in the speech bubble ────────────
const List<String> _pausePrompts = [
  'What did you notice? 🤔',
  'Can you describe that? 💬',
  'How did that feel? 😊',
  'What comes next? 🌟',
  'Tell me more! 👂',
  'Great observation! ⭐',
  'What do you think? 🧠',
  'Try it yourself! 💪',
];

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

// ── Reward badge model ───────────────────────────────────────────
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

// ═══════════════════════════════════════════════════════════════
//  Bouncing character widget
// ═══════════════════════════════════════════════════════════════
class _BouncingCharacter extends StatefulWidget {
  const _BouncingCharacter();

  @override
  State<_BouncingCharacter> createState() => _BouncingCharacterState();
}

class _BouncingCharacterState extends State<_BouncingCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: SizedBox(
        width: 110,
        height: 140,
        child: CustomPaint(painter: _CharacterPainter()),
      ),
    );
  }
}

// ── Character painter (drawn entirely with canvas primitives) ───
class _CharacterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()..color = const Color(0xff00bd74);
    final darkGreen = Paint()..color = const Color(0xff005735);
    final lightGreen = Paint()..color = const Color(0xff00e68a);
    final white = Paint()..color = Colors.white;

    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(55, 128), width: 56, height: 16),
      Paint()..color = const Color(0xff00bd74).withOpacity(0.18),
    );

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(42, 105, 9, 22), const Radius.circular(4)),
      green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(59, 105, 9, 22), const Radius.circular(4)),
      green,
    );

    // Feet
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(46, 127), width: 14, height: 8),
        darkGreen);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(64, 127), width: 14, height: 8),
        darkGreen);

    // Body torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(33, 68, 44, 42), const Radius.circular(14)),
      green,
    );

    // Left arm
    canvas.save();
    canvas.translate(16, 76);
    canvas.rotate(-0.26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, -4, 18, 9), const Radius.circular(4)),
      green,
    );
    canvas.restore();

    // Right arm
    canvas.save();
    canvas.translate(76, 76);
    canvas.rotate(0.26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, -4, 18, 9), const Radius.circular(4)),
      green,
    );
    canvas.restore();

    // Hands
    canvas.drawCircle(const Offset(14, 85), 6, green);
    canvas.drawCircle(const Offset(96, 85), 6, green);

    // Head
    canvas.drawCircle(const Offset(55, 50), 28, lightGreen);

    // Eye whites
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(44, 46), width: 12, height: 14),
        white);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(66, 46), width: 12, height: 14),
        white);

    // Pupils
    canvas.drawCircle(const Offset(45, 47), 3.5, darkGreen);
    canvas.drawCircle(const Offset(67, 47), 3.5, darkGreen);

    // Eye shine
    canvas.drawCircle(const Offset(46.2, 45.5), 1.2, white);
    canvas.drawCircle(const Offset(68.2, 45.5), 1.2, white);

    // Eyebrows
    final browPaint = Paint()
      ..color = const Color(0xff005735)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final leftBrow = Path()
      ..moveTo(38, 37)
      ..quadraticBezierTo(44, 33, 50, 37);
    final rightBrow = Path()
      ..moveTo(60, 37)
      ..quadraticBezierTo(66, 33, 72, 37);
    canvas.drawPath(leftBrow, browPaint);
    canvas.drawPath(rightBrow, browPaint);

    // Smile
    final mouthPaint = Paint()
      ..color = const Color(0xff005735)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final mouth = Path()
      ..moveTo(44, 60)
      ..quadraticBezierTo(55, 70, 66, 60);
    canvas.drawPath(mouth, mouthPaint);

    // Blush circles
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(36, 57), width: 12, height: 8),
      Paint()..color = Colors.red.withOpacity(0.28),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(74, 57), width: 12, height: 8),
      Paint()..color = Colors.red.withOpacity(0.28),
    );

    // Question mark on shirt
    final tp = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(47, 80));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  Main app widget
// ═══════════════════════════════════════════════════════════════
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

  // ── true  → video is in the big panel, remote camera is in the small slot
  // ── false → remote camera is in the big panel, video is in the small slot
  bool _isSwapped = false;

  // ── Character overlay ─────────────────────────────────────────
  bool _showCharacter = false;
  String _currentPrompt = _pausePrompts[0];
  final _random = Random();

  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  double _videoVolume = 1.0;
  bool _isVolumeMuted = false;
  bool _showAllBadges = false;

  late final Player _player;
  late VideoController _videoController;

  final List<RewardBadge> _badges = [
    RewardBadge(
      label: 'Good Job',
      emoji: '😊',
      bgColor: const Color(0xFFE53935),
      name: 'Name Here',
    ),
    RewardBadge(
      label: "You're A Star",
      emoji: '⭐',
      bgColor: const Color(0xFF1565C0),
      name: 'Name Here',
    ),
    RewardBadge(
      label: 'Well Done',
      emoji: '😎',
      bgColor: const Color(0xFF0D1B2A),
      name: 'Name Here',
    ),
    RewardBadge(
      label: 'Fantastic Effort',
      emoji: '🤣',
      bgColor: const Color(0xFFE3F2FD),
      name: 'Name Here',
    ),
    RewardBadge(
      label: 'Keep It Up',
      emoji: '💪',
      bgColor: const Color(0xFF388E3C),
      name: 'Name Here',
    ),
    RewardBadge(
      label: 'Super Work',
      emoji: '🏆',
      bgColor: const Color(0xFFF57F17),
      name: 'Name Here',
    ),
    RewardBadge(
      label: 'Amazing!',
      emoji: '🎉',
      bgColor: const Color(0xFF6A1B9A),
      name: 'Name Here',
    ),
    RewardBadge(
      label: 'Brilliant',
      emoji: '🌟',
      bgColor: const Color(0xFF00838F),
      name: 'Name Here',
    ),
  ];

  static const List<String> _emojiOptions = [
    '😊', '⭐', '😎', '🤣', '💪', '🏆', '🎉', '🌟',
    '🥳', '❤️', '🔥', '👏', '🦋', '🌈', '🎯', '🧠',
    '🐣', '🦄', '🎀', '🍀', '🚀', '💡', '🎸', '🌺',
  ];

  static const List<Color> _colorOptions = [
    Color(0xFFE53935), Color(0xFF1565C0), Color(0xFF0D1B2A),
    Color(0xFFE3F2FD), Color(0xFF388E3C), Color(0xFFF57F17),
    Color(0xFF6A1B9A), Color(0xFF00838F), Color(0xFFAD1457),
    Color(0xFF4E342E), Color(0xFF546E7A), Color(0xFFFDD835),
  ];

  // ── Pause / resume helpers ────────────────────────────────────
  Future<void> _pauseVideo() async {
    await _player.pause();
    setState(() {
      isVideoPlaying = false;
      _showCharacter = true;
      _currentPrompt =
          _pausePrompts[_random.nextInt(_pausePrompts.length)];
    });
  }

  Future<void> _resumeVideo() async {
    await _player.play();
    setState(() {
      isVideoPlaying = true;
      _showCharacter = false;
    });
  }

  Future<void> _togglePlayPause() async {
    if (isVideoPlaying) {
      await _pauseVideo();
    } else {
      await _resumeVideo();
    }
  }

  void _showAddBadgeDialog() {
    String selectedEmoji = _emojiOptions[0];
    Color selectedColor = _colorOptions[0];
    final labelController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add New Badge',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          labelController.text.isEmpty
                              ? 'Label'
                              : labelController.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selectedColor.computeLuminance() < 0.4
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          selectedEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        Text(
                          nameController.text.isEmpty
                              ? 'Name'
                              : nameController.text,
                          style: TextStyle(
                            color: selectedColor.computeLuminance() < 0.4
                                ? Colors.white70
                                : Colors.black54,
                            fontSize: 7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Label',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Great Work!',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                const Text('Name',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Alex',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                const Text('Emoji',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _emojiOptions.map((e) {
                    final isSel = e == selectedEmoji;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedEmoji = e),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              isSel ? Colors.black12 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              isSel ? Border.all(color: Colors.black45) : null,
                        ),
                        child: Center(
                          child: Text(e,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Color',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorOptions.map((c) {
                    final isSel = c == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSel
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (labelController.text.trim().isEmpty) return;
                setState(() {
                  _badges.add(RewardBadge(
                    label: labelController.text.trim(),
                    emoji: selectedEmoji,
                    bgColor: selectedColor,
                    name: nameController.text.trim().isEmpty
                        ? 'Name Here'
                        : nameController.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
              },
              child:
                  const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  final List<Map<String, String>> availableVideos = [
    {
      'title': 'Walk Video',
      'url':
          'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/walk_animation.mp4',
    },
    {
      'title': 'Stomp Video',
      'url':
          'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/stomp_animation.mp4',
    },
    {
      'title': 'Stand Video',
      'url':
          'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/stand_animation.mp4',
    },
    {
      'title': 'Fly Video',
      'url':
          'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/fly_animation.mp4',
    },
    {
      'title': 'Dance Video',
      'url':
          'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/dance_animation.mp4',
    },
    {
      'title': 'Climb Video',
      'url':
          'https://cdn.jsdelivr.net/gh/arjunfloreo-png/speech_animation_1@main/climb_animation.mp4',
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
        onJoinChannelSuccess: (connection, elapsed) =>
            setState(() => _localUserJoined = true),
        onUserJoined: (connection, uid, elapsed) =>
            setState(() => _remoteUid = uid),
        onUserOffline: (connection, uid, reason) =>
            setState(() => _remoteUid = null),
        onError: (error, msg) => debugPrint('❌ Agora Error: $error - $msg'),
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
      _showCharacter = false;
      showVideoLibrary = false;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Remote camera widget ─────────────────────────────────────
  Widget _buildRemoteCamera({bool large = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: const Color(0xff00bd74)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: const RtcConnection(channelId: channel),
                  ),
                )
              : Center(
                  child: Text(
                    widget.selectedRole == UserRole.therapist
                        ? 'Waiting for client...'
                        : 'Waiting for therapist...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: large ? 15 : 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
          // Role label
          Positioned(
            bottom: 6,
            left: 8,
            child: _livePill(
              widget.selectedRole == UserRole.therapist ? 'Client' : 'Therapist',
            ),
          ),
          // Mic + video controls
          Positioned(
            top: 6,
            right: 6,
            child: Row(
              children: [
                _tinyIconBtn(
                  icon: (widget.selectedRole == UserRole.therapist
                          ? isClientMuted
                          : isTherpistMuted)
                      ? Icons.mic_off
                      : Icons.mic,
                  onTap: () {
                    if (widget.selectedRole == UserRole.therapist) {
                      setState(() => isTherpistMuted = !isTherpistMuted);
                      _engine.muteLocalAudioStream(isTherpistMuted);
                    } else {
                      setState(() => isClientMuted = !isClientMuted);
                      _engine.muteLocalAudioStream(isClientMuted);
                    }
                  },
                ),
                const SizedBox(width: 4),
                _tinyIconBtn(
                  icon: (widget.selectedRole == UserRole.therapist
                          ? isTherpistvideoMuted
                          : isClientvideoMuted)
                      ? Icons.videocam_off
                      : Icons.videocam,
                  onTap: () {
                    if (widget.selectedRole == UserRole.therapist) {
                      setState(
                          () => isTherpistvideoMuted = !isTherpistvideoMuted);
                      _engine.muteLocalVideoStream(isTherpistvideoMuted);
                    } else {
                      setState(() => isClientvideoMuted = !isClientvideoMuted);
                      _engine.muteLocalVideoStream(isClientvideoMuted);
                    }
                  },
                ),
              ],
            ),
          ),
          // Double-tap swap hint (small position only)
          if (!large)
            Positioned(
              top: 6,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.selectedRole == UserRole.therapist) ...[
                      const Icon(Icons.swap_horiz,
                          color: Colors.white70, size: 12),
                      const SizedBox(width: 3),
                      const Text('2× swap',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 9)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Video panel with character overlay ───────────────────────
  Widget _buildVideoPanel() {
    return isVideoMode
        ? Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(color: const Color(0xff00bd74)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── VOD player ──────────────────────────────
                Video(
                  controller: _videoController,
                  controls: NoVideoControls,
                ),

                // ── Character overlay (shown when paused) ───
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showCharacter
                      ? Container(
                          key: const ValueKey('character'),
                          color: Colors.black.withOpacity(0.38),
                          child: Center(
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(_currentPrompt),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 480),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) => Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: value.clamp(0.0, 1.1),
                                  child: child,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Speech bubble
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.72),
                                      border: Border.all(
                                          color: const Color(0xff00bd74),
                                          width: 1.5),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      _currentPrompt,
                                      style: const TextStyle(
                                        color: Color(0xff00e68a),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Bubble tail triangle
                                  CustomPaint(
                                    size: const Size(16, 10),
                                    painter: _BubbleTailPainter(),
                                  ),
                                  const SizedBox(height: 2),
                                  // Bouncing character
                                  const _BouncingCharacter(),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ],
            ),
          )
        : _videoPlaceholder();
  }

  // ── Main build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.keyJ): ? isVideoMode
            ? () async {
                final t = Duration(
                  milliseconds: (_videoPosition.inMilliseconds - 10000)
                      .clamp(0, _videoDuration.inMilliseconds),
                );
                await _player.seek(t);
                setState(() => _videoPosition = t);
              }
            : null,

        LogicalKeySet(LogicalKeyboardKey.space):? isVideoMode
            ? () => _togglePlayPause()
            : null,

        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.f4):
            _endSession,

        LogicalKeySet(LogicalKeyboardKey.keyL):? isVideoMode
            ? () async {
                final t = Duration(
                  milliseconds: (_videoPosition.inMilliseconds + 10000)
                      .clamp(0, _videoDuration.inMilliseconds),
                );
                await _player.seek(t);
                setState(() => _videoPosition = t);
              }
            : null,

        LogicalKeySet(LogicalKeyboardKey.keyM):? isVideoMode
            ? () => setState(() => showVideoLibrary = !showVideoLibrary)
            : null,

        LogicalKeySet(LogicalKeyboardKey.keyG): () {
          setState(() => showVideoLibrary = !showVideoLibrary);
        },

        LogicalKeySet(LogicalKeyboardKey.keyS): () {
          setState(() => _isSwapped = !_isSwapped);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFFE8F5F0),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── LARGE main panel ─────────────────────────
                                Expanded(
                                  flex: 3,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        border: Border.all(
                                            color: const Color(0xff00bd74)),
                                      ),
                                      child: widget.selectedRole ==
                                              UserRole.therapist
                                          ? _isSwapped
                                              ? _buildVideoPanel()
                                              : _buildRemoteCamera(large: false)
                                          : _buildRemoteCamera(),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // ── RIGHT camera column ───────────────────────
                                SizedBox(
                                  width: 200,
                                  child: Column(
                                    children: [
                                      // TOP tile — local feed
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              border: Border.all(
                                                  color: const Color(
                                                      0xff00bd74)),
                                            ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                _localUserJoined
                                                    ? AgoraVideoView(
                                                        controller:
                                                            VideoViewController(
                                                          rtcEngine: _engine,
                                                          canvas:
                                                              const VideoCanvas(
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
                                                Positioned(
                                                  bottom: 6,
                                                  left: 8,
                                                  child: _livePill(
                                                    widget.selectedRole ==
                                                            UserRole.therapist
                                                        ? 'Therapist'
                                                        : 'Client',
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 6,
                                                  right: 6,
                                                  child: Row(
                                                    children: [
                                                      _tinyIconBtn(
                                                        icon: (widget.selectedRole ==
                                                                    UserRole
                                                                        .therapist
                                                                ? isTherpistMuted
                                                                : isClientMuted)
                                                            ? Icons.mic_off
                                                            : Icons.mic,
                                                        onTap: () {
                                                          if (widget.selectedRole ==
                                                              UserRole
                                                                  .therapist) {
                                                            setState(() =>
                                                                isTherpistMuted =
                                                                    !isTherpistMuted);
                                                            _engine
                                                                .muteLocalAudioStream(
                                                                    isTherpistMuted);
                                                          } else {
                                                            setState(() =>
                                                                isClientMuted =
                                                                    !isClientMuted);
                                                            _engine
                                                                .muteLocalAudioStream(
                                                                    isClientMuted);
                                                          }
                                                        },
                                                      ),
                                                      const SizedBox(width: 4),
                                                      _tinyIconBtn(
                                                        icon: (widget.selectedRole ==
                                                                    UserRole
                                                                        .therapist
                                                                ? isTherpistvideoMuted
                                                                : isClientvideoMuted)
                                                            ? Icons.videocam_off
                                                            : Icons.videocam,
                                                        onTap: () {
                                                          if (widget.selectedRole ==
                                                              UserRole
                                                                  .therapist) {
                                                            setState(() =>
                                                                isTherpistvideoMuted =
                                                                    !isTherpistvideoMuted);
                                                            _engine.muteLocalVideoStream(
                                                                isTherpistvideoMuted);
                                                          } else {
                                                            setState(() =>
                                                                isClientvideoMuted =
                                                                    !isClientvideoMuted);
                                                            _engine.muteLocalVideoStream(
                                                                isClientvideoMuted);
                                                          }
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

                                      // BOTTOM tile — double-tap swaps
                                      Expanded(
                                        child: GestureDetector(
                                          onDoubleTap: () => setState(
                                              () => _isSwapped = !_isSwapped),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                border: Border.all(
                                                    color: const Color(
                                                        0xff00bd74)),
                                              ),
                                              child: widget.selectedRole ==
                                                      UserRole.therapist
                                                  ? _isSwapped
                                                      ? _buildRemoteCamera(
                                                          large: true)
                                                      : _buildVideoPanel()
                                                  : _buildVideoPanel(),
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

                          if (widget.selectedRole == UserRole.therapist)
                            _bottomControlsBar(),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),
                    if (widget.selectedRole == UserRole.therapist)
                      _rewardPanel(),
                  ],
                ),
              ),

              if (showVideoLibrary) _videoLibraryWindow(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Video placeholder ────────────────────────────────────────
  Widget _videoPlaceholder() {
    return Container(
      color: const Color(0xFFE8F5F0),
      child: Center(
        child: GestureDetector(
          onTap: () => setState(() => showVideoLibrary = !showVideoLibrary),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        ),
      ),
    );
  }

  // ── Live pill ────────────────────────────────────────────────
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

  // ── Tiny icon button ─────────────────────────────────────────
  Widget _tinyIconBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
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
        border: Border.all(color: const Color(0xff00bd74)),
        color: Colors.white,
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
                        : _videoVolume < 0.4
                            ? Icons.volume_down
                            : Icons.volume_up,
                    color: const Color(0xff00bd74),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 6),
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
                Expanded(
                  child: _thinSlider(
                    value: _videoPosition.inMilliseconds
                        .toDouble()
                        .clamp(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionButton(
                isButton: false,
                label: 'TAKE ME BACK',
                style: _ActionStyle.soft,
                onTap: isVideoMode
                    ? () async {
                        final t = Duration(
                          milliseconds:
                              (_videoPosition.inMilliseconds - 10000)
                                  .clamp(0, _videoDuration.inMilliseconds),
                        );
                        await _player.seek(t);
                        setState(() => _videoPosition = t);
                      }
                    : null,
              ),
              _actionButton(
                isButton: false,
                label: isVideoPlaying ? 'POSE A QUESTION' : '  ASKING...',
                style: _ActionStyle.outline,
                onTap: isVideoMode ? () => _togglePlayPause() : null,
              ),
              _actionButton(
                isButton: true,
                icon: Icons.call_end_sharp,
                label: '',
                style: _ActionStyle.danger,
                onTap: _endSession,
              ),
              _actionButton(
                isButton: false,
                label: 'DIVE IN',
                style: _ActionStyle.filled,
                onTap: isVideoMode
                    ? () async {
                        final t = Duration(
                          milliseconds:
                              (_videoPosition.inMilliseconds + 10000)
                                  .clamp(0, _videoDuration.inMilliseconds),
                        );
                        await _player.seek(t);
                        setState(() => _videoPosition = t);
                      }
                    : null,
              ),
              _actionButton(
                isButton: false,
                label: 'LET ME SHARE',
                style: _ActionStyle.outline,
                onTap: isVideoMode
                    ? () =>
                        setState(() => showVideoLibrary = !showVideoLibrary)
                    : null,
              ),
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
        activeTrackColor: const Color(0xff00bd74),
        inactiveTrackColor: Colors.black12,
        thumbColor: const Color(0xffdaf9ed),
        overlayColor: Colors.black12,
      ),
      child: Slider(value: value, min: 0, max: max, onChanged: onChanged),
    );
  }

  // ── Action button ────────────────────────────────────────────
  Widget _actionButton({
    required bool isButton,
    IconData? icon,
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
          border: Border.all(
            width: 4,
            color: isDisabled
                ? const Color.fromARGB(255, 200, 238, 223)
                : const Color(0xff005735),
          ),
          color: isDisabled
              ? const Color.fromARGB(255, 200, 238, 223)
              : const Color(0xFF00bd74),
          borderRadius: BorderRadius.circular(30),
        );
        textStyle = const TextStyle(
          color: Color(0xffdaf9ed),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        );
        break;
      case _ActionStyle.soft:
        deco = BoxDecoration(
          border: Border.all(
            color: isDisabled
                ? const Color.fromARGB(255, 200, 238, 223)
                : const Color(0xff005735),
            width: 4,
          ),
          color: isDisabled
              ? const Color.fromARGB(255, 200, 238, 223)
              : const Color(0xFF00bd74),
          borderRadius: BorderRadius.circular(30),
        );
        textStyle = const TextStyle(
          color: Color(0xffdaf9ed),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        );
        break;
      case _ActionStyle.outline:
        deco = BoxDecoration(
          color: isDisabled
              ? const Color.fromARGB(255, 200, 238, 223)
              : const Color(0xFF00bd74),
          border: Border.all(
            color: isDisabled
                ? const Color.fromARGB(255, 200, 238, 223)
                : const Color(0xff005735),
            width: 4,
          ),
          borderRadius: BorderRadius.circular(30),
        );
        textStyle = TextStyle(
          color: const Color(0xffdaf9ed),
          fontWeight: FontWeight.w600,
          fontSize: small ? 11 : 15,
        );
        break;
      case _ActionStyle.danger:
        deco = BoxDecoration(
          border: Border.all(
            width: 4,
            color: isDisabled
                ? const Color.fromARGB(255, 200, 238, 223)
                : const Color(0xff005735),
          ),
          color: isDisabled ? Colors.red.shade200 : Colors.red,
          shape: BoxShape.circle,
        );
        textStyle = const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
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
        child: isButton
            ? Icon(icon, color: Colors.white)
            : Text(label, textAlign: TextAlign.center, style: textStyle),
      ),
    );
  }

  // ── Reward badges panel ──────────────────────────────────────
  Widget _rewardPanel() {
    final visibleBadges =
        _showAllBadges ? _badges : _badges.take(4).toList();
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xff00bd74)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * 0.04,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: const Color(0xFF00796B),
            ),
            child: const Center(
              child: Text(
                'REWARD BOX',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 30),
              itemCount: visibleBadges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 40),
              itemBuilder: (_, i) => _rewardBadge(visibleBadges[i]),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showAllBadges = !_showAllBadges),
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
              child: Icon(
                _showAllBadges ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardBadge(RewardBadge badge) {
    final isDark = badge.bgColor.computeLuminance() < 0.4;
    return GestureDetector(
      onTap: () {
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
            Text(
              badge.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
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
                color: isDark ? Colors.white70 : Colors.black54,
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
                color: Colors.black.withOpacity(0.15), blurRadius: 20),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Select Video',
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

  Future<void> _endSession() async {
    try {
      await _player.pause();
      await _player.stop();
      await _engine.leaveChannel();

      setState(() {
        isVideoMode = false;
        selectedVideoUrl = null;
        _remoteUid = null;
        isVideoPlaying = false;
        _isSwapped = false;
        _showCharacter = false;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('End session error: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  Speech bubble tail painter
// ═══════════════════════════════════════════════════════════════
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff00bd74)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
