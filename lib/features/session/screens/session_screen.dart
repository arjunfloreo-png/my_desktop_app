import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/session_constants.dart';
import '../models/user_role.dart';
import '../provider/reward_provider.dart';
import '../provider/screen_share_provider.dart';
import '../provider/session_provider.dart';
import '../provider/video_provider.dart';
import '../widgets/camera_tile.dart';
import '../widgets/controls_bar.dart';
import '../widgets/flying_badge_overlay.dart';
import '../widgets/reward_drawer.dart';
import '../widgets/video_library_overlay.dart';
import '../widgets/video_panel.dart';
import 'role_selection_screen.dart';

class SessionScreen extends StatefulWidget {
  final UserRole role;
  const SessionScreen({super.key, required this.role});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with TickerProviderStateMixin {
  late final SessionProvider _session;
  late final VideoProvider _video;
  late final RewardProvider _reward;
  late final ScreenShareProvider _screenShare; // ← NEW
  final FocusNode _screenFocusNode = FocusNode();

  final _random = Random();
  bool _showCharacter = false;
  String _currentPrompt = kPausePrompts[0];

  // ── TIMER STATE ──────────────────────────────
  int _timerSeconds = 0;
  bool _timerVisible = false;
  bool _timerRunning = false;
  Timer? _countdownTimer;
  int _stopGeneration = 0;

  @override
  void initState() {
    super.initState();
    _session = SessionProvider(role: widget.role);
    _video = VideoProvider();
    _reward = RewardProvider(vsync: this);
    _screenShare = ScreenShareProvider(); // ← NEW

    _session.addListener(_onSessionChange);
    _video.addListener(_onVideoChange);
    _reward.addListener(_onRewardChange);
    _screenShare.addListener(_onScreenShareChange); // ← NEW

    // Init browser + Agora engine in background
    _screenShare.init(); // ← NEW
  }

  // ── SCREEN SHARE LISTENER ────────────────────
  void _onScreenShareChange() {
    if (!mounted) return;
    setState(() {});
  }

  // ── TIMER LOGIC ──────────────────────────────

  void _onTimerButtonPressed() {
    if (_timerRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _stopGeneration++;
    _countdownTimer?.cancel();

    setState(() {
      _timerSeconds = 0;
      _timerVisible = true;
      _timerRunning = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timerSeconds++);
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    final generation = ++_stopGeneration;

    setState(() => _timerRunning = false);

    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_stopGeneration != generation) return;
      setState(() {
        _timerVisible = false;
        _timerSeconds = 0;
      });
    });
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── EXISTING LISTENERS ───────────────────────

  void _onRewardChange() {
    if (!mounted) return;
    setState(() {});
  }

  void _onSessionChange() {
    if (!mounted) return;
    setState(() {});
  }

  void _onVideoChange() {
    if (!mounted) return;

    if (!_video.isVideoPlaying && _video.isVideoMode) {
      _showCharacter = true;
      _currentPrompt = kPausePrompts[_random.nextInt(kPausePrompts.length)];
    } else if (_video.isVideoPlaying) {
      _showCharacter = false;
    }

    setState(() {});
  }

  Future<void> _endSession() async {
    try {
      _stopGeneration++;
      _countdownTimer?.cancel();
      setState(() {
        _timerRunning = false;
        _timerVisible = false;
        _timerSeconds = 0;
      });

      await _video.stop();
      await _screenShare.stopShare(); // ← stop share on session end
      await _session.endSession();

      _reward.closeDrawer();
      _session.isSwapped = false;

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (_) => false,
      );
    } catch (e) {
      debugPrint('End session error: $e');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _session.removeListener(_onSessionChange);
    _video.removeListener(_onVideoChange);
    _reward.removeListener(_onRewardChange);
    _screenShare.removeListener(_onScreenShareChange); // ← NEW
    _session.dispose();
    _video.dispose();
    _reward.dispose();
    _screenShare.dispose(); // ← NEW
    _screenFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.space): () =>
            _video.isVideoMode ? _video.togglePlayPause() : null,
        LogicalKeySet(LogicalKeyboardKey.keyJ): () =>
            _video.isVideoMode ? _video.skipBack() : null,
        LogicalKeySet(LogicalKeyboardKey.keyL): () =>
            _video.isVideoMode ? _video.skipForward() : null,
        LogicalKeySet(LogicalKeyboardKey.keyM): () =>
            _video.isVideoMode ? _video.toggleLibrary() : null,
        LogicalKeySet(LogicalKeyboardKey.keyG): () {
          _video.toggleLibrary();
        },
        LogicalKeySet(LogicalKeyboardKey.keyS): () =>
            _video.showLibrary ? null : _session.toggleSwap(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.f4):
            _endSession,
      },
      child: Focus(
        autofocus: true,
        focusNode: _screenFocusNode,
        child: Scaffold(
          backgroundColor: const Color(0xFFE8F5F0),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(child: _mainLayout(context)),
                    const SizedBox(height: 10),

                    if (widget.role == UserRole.therapist)
                      ControlsBar(
                        videoProvider: _video,
                        rewardProvider: _reward,
                        onEndSession: _endSession,
                        sessionProvider: _session,
                        onTimerPressed: _onTimerButtonPressed,
                        timerRunning: _timerRunning,
                      ),
                  ],
                ),
              ),

              // Drawer backdrop
              if (_reward.isDrawerOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _reward.toggleDrawer,
                    child: Container(color: Colors.black.withOpacity(0.25)),
                  ),
                ),

              // Reward drawer
              if (_reward.isDrawerOpen)
                Positioned(
                  top: 12,
                  bottom: 12 + 80,
                  right: 12,
                  child: SlideTransition(
                    position: _reward.drawerSlide,
                    child: RewardDrawer(rewardProvider: _reward),
                  ),
                ),

              // Video Library — now receives screenShareProvider
              if (_video.showLibrary)
                VideoLibraryOverlay(
                  videoProvider: _video,
                  screenShareProvider: _screenShare, // ← NEW
                  onClose: () => _screenFocusNode.requestFocus(),
                ),

              // Flying badges
              FlyingBadgeOverlay(flyingBadges: _reward.flyingBadges),

              // ── TIMER OVERLAY ──
              if (_timerVisible)
                Positioned(
                  bottom: 135,
                  left: 0,
                  right: 240,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.black.withOpacity(0.25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.30),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: const Color(0xFF2ECC71).withOpacity(0.15),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2ECC71).withOpacity(0.20),
                                  border: Border.all(
                                    color: const Color(0xFF2ECC71).withOpacity(0.40),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.timer_rounded,
                                  color: Color(0xFF2ECC71),
                                  size: 26,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Text(
                                _formatTimer(_timerSeconds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainLayout(BuildContext context) {
    final isTherapist = widget.role == UserRole.therapist;

    Widget mainPanel = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: const Color(0xff005735)),
        ),
        child: isTherapist
            ? (_session.isSwapped
                  ? VideoPanel(
                      videoProvider: _video,
                      screenShareProvider: _screenShare, // ← NEW
                      showCharacter: _showCharacter,
                      currentPrompt: _currentPrompt,
                    )
                  : CameraTile(session: _session, isRemote: true))
            : CameraTile(session: _session, isRemote: true),
      ),
    );

    Widget sideVideo = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: const Color(0xff005735)),
        ),
        child: isTherapist
            ? (_session.isSwapped
                  ? CameraTile(session: _session, isRemote: true, large: true)
                  : VideoPanel(
                      videoProvider: _video,
                      screenShareProvider: _screenShare, // ← NEW
                      showCharacter: _showCharacter,
                      currentPrompt: _currentPrompt,
                    ))
            : VideoPanel(
                videoProvider: _video,
                screenShareProvider: _screenShare, // ← NEW
                showCharacter: _showCharacter,
                currentPrompt: _currentPrompt,
              ),
      ),
    );

    Widget localCamera = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: const Color(0xff005735)),
        ),
        child: CameraTile(session: _session, isRemote: false),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: mainPanel),
        const SizedBox(width: 10),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.2,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _session.toggleSwap,
                  child: sideVideo,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: localCamera),
            ],
          ),
        ),
      ],
    );
  }
}
