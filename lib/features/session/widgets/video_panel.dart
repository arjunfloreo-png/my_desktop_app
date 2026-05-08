import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/user_role.dart';
import '../provider/video_provider.dart';
import 'bouncing_character.dart';
import 'bubble_tail_painter.dart';

class VideoPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (!videoProvider.isVideoMode) {
      return _placeholder(context);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildVideoLayer(),

        if (videoProvider.isBuffering) _buildBuffering(),

        if (showCharacter) _buildCharacterOverlay(),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // VIDEO LAYER (YOUTUBE / MEDIA_KIT)
  // ─────────────────────────────────────────────
  Widget _buildVideoLayer() {
    // if (videoProvider.isYoutube) {
    //   final url = videoProvider.selectedVideoUrl;

    //   if (url == null || url.isEmpty) {
    //     return const Center(child: Text("Invalid YouTube URL"));
    //   }

    //   return KeyedSubtree(
    //     key: ValueKey(url), // ✅ prevents controller reset issues
    //     child: YoutubePlayerView(url: url),
    //   );
    // }
    // return Container();
    return Container(
      color: Colors.black87,
      child: 
      SizedBox.expand(
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

  // ─────────────────────────────────────────────
  // BUFFERING OVERLAY
  // ─────────────────────────────────────────────
  Widget _buildBuffering() {
    return Container(
      color: Colors.black.withOpacity(0.4),
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
    return Container(
      color: Colors.black.withOpacity(0.42),
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(currentPrompt),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: value.clamp(0.0, 1.1),
                child: child,
              ),
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
                  currentPrompt,
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
    );
  }

  // ─────────────────────────────────────────────
  // PLACEHOLDER
  // ─────────────────────────────────────────────
  Widget _placeholder(BuildContext context) {
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
                 Text(
  
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
