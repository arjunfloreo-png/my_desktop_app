import 'package:floreo/features/session/widgets/youtube_player_view.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../provider/video_provider.dart';
import 'bouncing_character.dart';
import 'bubble_tail_painter.dart';

class VideoPanel extends StatefulWidget {
  final VideoProvider videoProvider;
  final bool showCharacter;
  final String currentPrompt;

  const VideoPanel({
    super.key,
    required this.videoProvider,
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

    // ONLY animate when prompt actually changes
    if (widget.currentPrompt != oldWidget.currentPrompt) {
      _lastPrompt = widget.currentPrompt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = widget.videoProvider;

    if (!videoProvider.isVideoMode) {
      return _placeholder(context);
    }

    return Stack(
      fit: StackFit.expand,
      children: [

        // VIDEO PLAYER
        _buildVideoLayer(),

        // BUFFERING
        if (videoProvider.isBuffering)
          _buildBuffering(),

        // CHARACTER OVERLAY
        if (widget.showCharacter)
          _buildCharacterOverlay(),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // VIDEO LAYER
  // ─────────────────────────────────────────────
  Widget _buildVideoLayer() {
    final videoProvider = widget.videoProvider;

    final url =
        videoProvider.selectedVideoUrl ?? '';

    debugPrint(
      'Selected Video => '
      'external=${videoProvider.isExternal} '
      'url=$url',
    );

    // YOUTUBE / EXTERNAL VIDEO
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

    // MP4 VIDEO
    return _buildMp4Layer();
  }

  // ─────────────────────────────────────────────
  // MP4 PLAYER
  // ─────────────────────────────────────────────
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
              controller:
                  videoProvider.videoController,
              controls: NoVideoControls,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUFFERING
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // CHARACTER OVERLAY
  // ─────────────────────────────────────────────
  Widget _buildCharacterOverlay() {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withOpacity(0.42),
        child: Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(_lastPrompt),
            tween: Tween(
              begin: 0.0,
              end: 1.0,
            ),
            duration: const Duration(
              milliseconds: 450,
            ),
            curve: Curves.easeOutBack,
            builder: (
              context,
              value,
              child,
            ) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0), // FIX: easeOutBack overshoots above 1.0
                child: Transform.scale(
                  scale: value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // CHAT BUBBLE
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.72,
                    ),
                    border: Border.all(
                      color:
                          const Color(0xff00bd74),
                      width: 1.5,
                    ),
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: Text(
                    widget.currentPrompt,
                    style: const TextStyle(
                      color:
                          Color(0xff00e68a),
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                CustomPaint(
                  size: const Size(16, 10),
                  painter: BubbleTailPainter(),
                ),

                const SizedBox(height: 4),

                // CHARACTER
                const BouncingCharacter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EMPTY PLACEHOLDER
  // ─────────────────────────────────────────────
  Widget _placeholder(BuildContext context) {
    final videoProvider = widget.videoProvider;

    return Container(
      color: const Color(0xFFE8F5F0),
      child: Center(
        child: GestureDetector(
          onTap: videoProvider.toggleLibrary,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(
                    0.08,
                  ),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [

                // LIVE DOT
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 10),

                // LABEL
                const Text(
                  'Go LIVE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF1A1A2E),
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
