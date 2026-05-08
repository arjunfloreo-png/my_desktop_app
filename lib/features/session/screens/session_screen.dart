import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/session_constants.dart';
import '../models/user_role.dart';
import '../provider/reward_provider.dart';
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
  final FocusNode _screenFocusNode = FocusNode(); // ADD

  final _random = Random();
  bool _showCharacter = false;
  String _currentPrompt = kPausePrompts[0];

  @override
  void initState() {
    super.initState();
    _session = SessionProvider(role: widget.role);
    _video = VideoProvider();
    _reward = RewardProvider(vsync: this);

    _session.addListener(_onSessionChange);
    _video.addListener(_onVideoChange);
    _reward.addListener(_onRewardChange);
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
      await _video.stop();
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
    _session.removeListener(_onSessionChange);
    _video.removeListener(_onVideoChange);
    _reward.removeListener(_onRewardChange);
    _session.dispose();
    _video.dispose();
    _reward.dispose();
    _screenFocusNode.dispose(); // ADD
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
        focusNode: _screenFocusNode, // ADD
        child: Scaffold(
          backgroundColor: const Color(0xFFE8F5F0),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(child: _mainLayout()),
                    const SizedBox(height: 10),
                    if (widget.role == UserRole.therapist)
                      ControlsBar(
                        videoProvider: _video,
                        rewardProvider: _reward,
                        onEndSession: _endSession,
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

              // Video library
              if (_video.showLibrary)
                VideoLibraryOverlay(
                  videoProvider: _video,
                  onClose: () => _screenFocusNode.requestFocus(), // ADD
                ),

              // Flying badges
              FlyingBadgeOverlay(flyingBadges: _reward.flyingBadges),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainLayout() {
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
                      showCharacter: _showCharacter,
                      currentPrompt: _currentPrompt,
                    ))
            : VideoPanel(
                videoProvider: _video,
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