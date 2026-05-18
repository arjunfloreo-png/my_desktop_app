import 'package:floreo/features/session/widgets/youtube_player_view.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:webview_windows/webview_windows.dart';

import '../models/user_role.dart';
import '../provider/screen_share_provider.dart';
import '../provider/session_provider.dart';
import '../provider/video_provider.dart';
import 'bouncing_character.dart';
import 'bubble_tail_painter.dart';

class VideoPanel extends StatefulWidget {
  final VideoProvider videoProvider;
  final ScreenShareProvider screenShareProvider;
  final SessionProvider sessionProvider;
  final UserRole role;
  final bool showCharacter;
  final String currentPrompt;

  const VideoPanel({
    super.key,
    required this.videoProvider,
    required this.screenShareProvider,
    required this.sessionProvider,
    required this.role,
    required this.showCharacter,
    required this.currentPrompt,
  });

  @override
  State<VideoPanel> createState() => _VideoPanelState();
}

class _VideoPanelState extends State<VideoPanel> {
  String? _lastPrompt;

  @override
  void didUpdateWidget(covariant VideoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPrompt != oldWidget.currentPrompt) {
      _lastPrompt = widget.currentPrompt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenShare = widget.screenShareProvider;
    final session = widget.sessionProvider;
    final videoProvider = widget.videoProvider;

    // ── THERAPIST SCREEN SHARE MODE ──────────────────────────────────────────
    if (widget.role == UserRole.therapist &&
        (screenShare.isSharing || screenShare.showBrowser)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            child: screenShare.showBrowser
                ? Webview(screenShare.webviewController)
                : Container(
                    color: const Color(0xFF1A2B1A),
                    child: const Center(
                      child: Text(
                        'Starting browser...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),

          // Stop Share button — pass mainEngine to restart cam after stop
          Positioned(
            top: 12,
            right: 12,
            child: ElevatedButton.icon(
              onPressed: () => screenShare.stopShare(
                mainEngine: session.engine,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.stop_screen_share, size: 18),
              label: const Text('Stop Share'),
            ),
          ),

          if (screenShare.isInitializing)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00bd74)),
                    SizedBox(height: 12),
                    Text(
                      'Starting screen share...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          if (screenShare.error != null)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  screenShare.error!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }

    // ── CLIENT: therapist is screen sharing ──────────────────────────────────
    if (widget.role == UserRole.client && session.isRemoteScreenSharing) {
      return Container(
        color: const Color(0xFF1A2B1A),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.screen_share, color: Color(0xFF00bd74), size: 40),
              SizedBox(height: 12),
              Text(
                'Therapist is sharing their screen',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── NORMAL VIDEO MODE ────────────────────────────────────────────────────
    if (!videoProvider.isVideoMode) {
      return _placeholder(context);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildVideoLayer(),
        if (videoProvider.isBuffering) _buildBuffering(),
        if (widget.showCharacter) _buildCharacterOverlay(),
      ],
    );
  }

  Widget _buildVideoLayer() {
    final videoProvider = widget.videoProvider;
    final url = videoProvider.selectedVideoUrl ?? '';

    debugPrint(
      'Selected Video => '
      'external=${videoProvider.isExternal} '
      'url=$url',
    );

    if (videoProvider.isExternal) {
      return Container(
        color: Colors.black,
        child: SizedBox.expand(
          child: YoutubePlayerView(
            key: ValueKey(url),
            url: url,
            videoProvider: videoProvider,
          ),
        ),
      );
    }

    return _buildMp4Layer();
  }

  Widget _buildMp4Layer() {
    final videoProvider = widget.videoProvider;

    return Container(
      color: Colors.black,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 1920,
            height: 1080,
            child: Video(
              controller: videoProvider.videoController,
              controls: NoVideoControls,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBuffering() {
    return Container(
      color: Colors.black.withOpacity(0.45),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00bd74),
          strokeWidth: 4,
        ),
      ),
    );
  }

  Widget _buildCharacterOverlay() {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withOpacity(0.42),
        child: Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(_lastPrompt),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.72),
                    border: Border.all(
                      color: const Color(0xff00bd74),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    widget.currentPrompt,
                    style: const TextStyle(
                      color: Color(0xff00e68a),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(16, 10),
                  painter: BubbleTailPainter(),
                ),
                const SizedBox(height: 4),
                const BouncingCharacter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final videoProvider = widget.videoProvider;

    return Container(
      color: const Color(0xFFE8F5F0),
      child: Center(
        child: GestureDetector(
          onTap: videoProvider.toggleLibrary,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}
