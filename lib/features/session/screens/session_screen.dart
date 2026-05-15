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
  final String? channelName;
  final String? token;

  const SessionScreen({
    super.key,
    required this.role,
    this.channelName,
    this.token,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with TickerProviderStateMixin {
  late final SessionProvider _session;
  late final VideoProvider _video;
  late final RewardProvider _reward;
  late final ScreenShareProvider _screenShare;
  final FocusNode _screenFocusNode = FocusNode();
     
  final _random = Random();
  bool _showCharacter = false;
  String _currentPrompt = kPausePrompts[0];

  int _timerSeconds = 0;
  bool _timerVisible = false;
  bool _timerRunning = false;
  Timer? _countdownTimer;
  int _stopGeneration = 0;
   

   @override
  @override
  void initState() {
    super.initState();
    _session = SessionProvider(role: widget.role, token: widget.token! , channelName: widget.channelName! );
    _video = VideoProvider();
    _reward = RewardProvider(vsync: this);
    _screenShare = ScreenShareProvider(
      token: widget.token!,
      channelName: widget.channelName!,
    );

    _session.addListener(_onSessionChange);
    _video.addListener(_onVideoChange);
    _reward.addListener(_onRewardChange);
    _screenShare.addListener(_onScreenShareChange);

    if (widget.role == UserRole.therapist) {
      _screenShare.init();
    }
  }

  void _onScreenShareChange() {
    if (!mounted) return;
    setState(() {});
  }

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
      if (!mounted) { t.cancel(); return; }
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
      await _screenShare.stopShare();
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
    _screenShare.removeListener(_onScreenShareChange);
    _session.dispose();
    _video.dispose();
    _reward.dispose();
    _screenShare.dispose();
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
        LogicalKeySet(LogicalKeyboardKey.keyG): () => _video.toggleLibrary(),
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

              if (_reward.isDrawerOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _reward.toggleDrawer,
                    child: Container(color: Colors.black.withOpacity(0.25)),
                  ),
                ),

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

              if (_video.showLibrary)
                VideoLibraryOverlay(
                  videoProvider: _video,
                  screenShareProvider: _screenShare,
                  onClose: () => _screenFocusNode.requestFocus(),
                ),

              FlyingBadgeOverlay(flyingBadges: _reward.flyingBadges),

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
                              horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.black.withOpacity(0.25),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.30),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6)),
                              BoxShadow(
                                  color: const Color(0xFF2ECC71)
                                      .withOpacity(0.15),
                                  blurRadius: 14,
                                  spreadRadius: 2),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2ECC71)
                                      .withOpacity(0.20),
                                  border: Border.all(
                                      color: const Color(0xFF2ECC71)
                                          .withOpacity(0.40),
                                      width: 1),
                                ),
                                child: const Icon(Icons.timer_rounded,
                                    color: Color(0xFF2ECC71), size: 26),
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
                                        offset: Offset(0, 2))
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

  // ── VideoPanel (therapist only) ──────────────
  Widget _videoPanel() {
    return VideoPanel(
      videoProvider: _video,
      screenShareProvider: _screenShare,
      sessionProvider: _session,
      role: widget.role,
      showCharacter: _showCharacter,
      currentPrompt: _currentPrompt,
    );
  }

  // ── Remote camera tile ───────────────────────
  // ValueKey changes when isRemoteScreenSharing flips so Flutter fully
  // destroys + recreates AgoraVideoView — prevents stream stacking.
  Widget _remoteCameraTile({bool large = false}) {
    return KeyedSubtree(
      key: ValueKey('remote_${_session.isRemoteScreenSharing}'),
      child: CameraTile(session: _session, isRemote: true, large: large),
    );
  }

  // ── Shared tile box decorator ────────────────
  Widget _tileBox(Widget child, {double radius = 20}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: const Color(0xff005735)),
        ),
        child: child,
      ),
    );
  }

  // ── Main layout ──────────────────────────────
  Widget _mainLayout(BuildContext context) {
    final isTherapist = widget.role == UserRole.therapist;

    // ══════════════════════════════════════════════════════════════════════════
    // THERAPIST LAYOUT
    // ══════════════════════════════════════════════════════════════════════════
    //  !swap → main: client cam   | side top: video panel
    //   swap → main: video panel  | side top: client cam
    //  Double-tap side top → toggleSwap
    // ══════════════════════════════════════════════════════════════════════════
    if (isTherapist) {
      final Widget mainContent =
          _session.isSwapped ? _videoPanel() : _remoteCameraTile();
      final Widget sideTopContent =
          _session.isSwapped ? _remoteCameraTile(large: true) : _videoPanel();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _tileBox(mainContent)),
          const SizedBox(width: 10),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.2,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: _session.toggleSwap,
                    child: _tileBox(sideTopContent, radius: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _tileBox(
                    CameraTile(session: _session, isRemote: false),
                    radius: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // CLIENT LAYOUT
    // ══════════════════════════════════════════════════════════════════════════
    //
    // Normal (no screen share):
    //   !swap → main: therapist camera  | side top: dark placeholder
    //    swap → main: dark placeholder  | side top: therapist camera
    //
    // Screen share active:
    //   !swap → main: screen share (uid 1001) | side top: "Screen Sharing" banner
    //    swap → main: "Screen Sharing" banner  | side top: screen share (uid 1001)
    //
    // CameraTile(isRemote:true) automatically switches between uid=1 and uid=1001
    // based on isRemoteScreenSharing — handled inside camera_tile.dart.
    //
    // Double-tap side top → toggleSwap (same as therapist)
    // ══════════════════════════════════════════════════════════════════════════

    // Side top content: screen share banner or dark placeholder
    final Widget clientSideTop = _session.isRemoteScreenSharing
        ? _screenShareBanner()
        : _tileBox(Container(color: Colors.black87), radius: 16);

    // Main content: therapist stream (camera or screen share via CameraTile)
    final Widget clientMain = _remoteCameraTile();

    // Apply swap for client
    final Widget mainContent = _session.isSwapped ? clientSideTop : clientMain;
    final Widget sideTopContent = _session.isSwapped ? clientMain : clientSideTop;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: _tileBox(mainContent),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.2,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: GestureDetector(
                  // ✅ Client also gets double-tap swap
                  onDoubleTap: _session.toggleSwap,
                  child: _tileBox(sideTopContent, radius: 16),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _tileBox(
                  CameraTile(session: _session, isRemote: false),
                  radius: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Screen share info banner (client side panel) ──────────────────────────
  Widget _screenShareBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B1A),
          border: Border.all(color: const Color(0xff005735)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.screen_share, color: Color(0xFF00bd74), size: 32),
              SizedBox(height: 8),
              Text(
                'Screen\nSharing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
