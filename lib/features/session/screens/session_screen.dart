import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/socket_service.dart';
import '../models/session_constants.dart';
import '../models/user_role.dart';
import '../models/video_item.dart';
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
  final String? screenShareToken;

  const SessionScreen({
    super.key,
    required this.role,
    this.channelName,
    this.token,
    this.screenShareToken,
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
  bool _wasSharing = false;
  int _localCamRebuildKey = 0;
  int _remoteCamRebuildKey = 0; // ← NEW

  @override
  void initState() {
    super.initState();
    _session = SessionProvider(
      role: widget.role,
      token: widget.token!,
      channelName: widget.channelName!,
    );
    _video = VideoProvider();
    _reward = RewardProvider(vsync: this);
    _reward.loadRewardBox(); // ← ADD THIS

    _screenShare = ScreenShareProvider(
      token: widget.screenShareToken ?? '',
      channelName: widget.channelName!,
    );

    _session.addListener(_onSessionChange);
    _video.addListener(_onVideoChange);
    _reward.addListener(_onRewardChange);
    _screenShare.addListener(_onScreenShareChange);

    if (widget.role == UserRole.therapist) {
      _screenShare.init();
    }
    setupSocket();
  }

  void setupSocket() {
    final socket = SocketService();

    socket.onVideoSelect = (d) {
      _video.playFromUrl(
        d['videoUrl'],
        type: d['videoUrl'].toString().contains('youtube')
            ? VideoType.external
            : VideoType.mp4,
      );
    };

    socket.onVideoPlay = (d) {
      final t = (d['currentTime'] as num).toDouble();
      _video.seek(Duration(milliseconds: (t * 1000).toInt()));
      _video.resume();
    };

    socket.onVideoPause = (d) {
      final t = (d['currentTime'] as num).toDouble();
      _video.seek(Duration(milliseconds: (t * 1000).toInt()));
      _video.pause();
    };

    socket.onVideoSeek = (d) {
      final t = (d['currentTime'] as num).toDouble();
      _video.seek(Duration(milliseconds: (t * 1000).toInt()));
    };

    socket.onVideoVolume = (d) {
      final v = (d['volume'] as num).toDouble();
      _video.setVolume(v);
    };

    socket.onButtonAction = (d) {
      _handleButtonAction(d['action']);
    };

    socket.onPeerConnected = (d) => setState(() {});
    socket.onPeerDisconnected = (d) => setState(() {});

    // Client: sync on join
    if (widget.role == UserRole.client) {
      socket.syncRequest();
    }
  }

  void _handleButtonAction(String action) {
    // Map server actions to your existing UI
    switch (action) {
      case 'DIVE_IN': /* show dive in UI */
        break;
      case 'ASKING': /* show asking UI  */
        break;
      case 'LET_ME_SHARE':
        _screenShare.openBrowserAndShare();
        break;
      case 'REWARD_BOX':
        _reward.toggleDrawer();
        break;
      case 'TAKE_ME_BACK': /* navigate back  */
        break;
    }
  }

  void _onScreenShareChange() {
    if (!mounted) return;
    if (_wasSharing && !_screenShare.isSharing) {
      // Share stopped — bump both keys → force AgoraVideoView recreate
      _wasSharing = false;
      setState(() {
        _localCamRebuildKey++;
        _remoteCamRebuildKey++; // ← NEW
      });
    } else {
      if (_screenShare.isSharing) {
        _wasSharing = true;
        setState(
          () => _remoteCamRebuildKey++,
        ); // ← NEW: bump on share start too
      } else {
        setState(() {});
      }
    }
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

  void _onRewardChange() {
    if (!mounted) return;
    if (!_reward.isDrawerOpen) {
      _screenFocusNode.requestFocus(); // ← ADD
    }
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
    SocketService().disconnect();

    try {
      _stopGeneration++;
      _countdownTimer?.cancel();
      setState(() {
        _timerRunning = false;
        _timerVisible = false;
        _timerSeconds = 0;
      });
      await _video.stop();
      await _screenShare.stopShare(mainEngine: _session.engine);
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
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyJ): () =>
            _video.isVideoMode ? _video.skipBack() : null,
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyL): () =>
            _video.isVideoMode ? _video.skipForward() : null,
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyM): () =>
            _video.isVideoMode ? _video.toggleLibrary() : null,
        LogicalKeySet(
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyG,
        ): () =>
            _video.toggleLibrary(),
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
                    onTap: () {
                      _reward.toggleDrawer();
                      _screenFocusNode.requestFocus(); // ← ADD
                    },
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
                    child: RewardDrawer(
                      rewardProvider: _reward,
                      onCharacterSelected: (_) => _video.pause(), // ← ADD
                    ),
                  ),
                ),

              if (_video.showLibrary)
                VideoLibraryOverlay(
                  videoProvider: _video,
                  screenShareProvider: _screenShare,
                  onClose: () => _screenFocusNode.requestFocus(),
                ),

              // ------------ flay reaction on screen -------------------
              //    FlyingBadgeOverlay(flyingBadges: _reward.flyingBadges),
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
                                color: const Color(
                                  0xFF2ECC71,
                                ).withOpacity(0.15),
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
                                  color: const Color(
                                    0xFF2ECC71,
                                  ).withOpacity(0.20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF2ECC71,
                                    ).withOpacity(0.40),
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

  Widget _videoPanel() {
    return VideoPanel(
      rewardProvider: _reward,
      videoProvider: _video,
      screenShareProvider: _screenShare,
      sessionProvider: _session,
      role: widget.role,
      showCharacter: _showCharacter,
      currentPrompt: _currentPrompt,
    );
  }

  Widget _remoteCameraTile({bool large = false}) {
    return KeyedSubtree(
      key: ValueKey(
        'remote_cam_${_session.remoteUid}_$_remoteCamRebuildKey',
      ), // ← UPDATED
      child: CameraTile(session: _session, isRemote: true, large: large),
    );
  }

  Widget _screenShareTile() {
    return KeyedSubtree(
      key: const ValueKey('screen_share_tile'),
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _session.engine,
          canvas: const VideoCanvas(
            uid: kScreenShareUid,
            sourceType: VideoSourceType.videoSourceRemote,
          ),
          connection: RtcConnection(channelId: _session.channelName),
        ),
      ),
    );
  }

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

  Widget _mainLayout(BuildContext context) {
    final isTherapist = widget.role == UserRole.therapist;

    if (isTherapist) {
      final Widget mainContent = _session.isSwapped
          ? _videoPanel()
          : _remoteCameraTile();
      final Widget sideTopContent = _session.isSwapped
          ? _remoteCameraTile(large: true)
          : _videoPanel();

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
                    KeyedSubtree(
                      key: ValueKey('local_cam_$_localCamRebuildKey'),
                      child: CameraTile(session: _session, isRemote: false),
                    ),
                    radius: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── CLIENT LAYOUT ──────────────────────────────
    final bool shareActive = _session.isRemoteScreenSharing;

    final Widget sideTopContent = shareActive
        ? _screenShareTile()
        : _video.isVideoMode
        ? _videoPanel()
        : Container(color: Colors.black87);

    final Widget mainContent = _session.isSwapped
        ? (shareActive
              ? _screenShareTile()
              : _video.isVideoMode
              ? _videoPanel()
              : Container(color: Colors.black87))
        : _remoteCameraTile();

    final Widget sideTop = _session.isSwapped
        ? _remoteCameraTile(large: true)
        : sideTopContent;

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
                  child: _tileBox(sideTop, radius: 16),
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
}
