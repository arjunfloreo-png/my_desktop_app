
// ── Hover preview popup widget ───────────────────
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class HoverPreviewPopup extends StatefulWidget {
  final VideoController controller;
  final String title;

  const HoverPreviewPopup({required this.controller, required this.title});

  @override
  State<HoverPreviewPopup> createState() => HoverPreviewPopupState();
}

class HoverPreviewPopupState extends State<HoverPreviewPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        width: 280, // CHANGED from 280
        height: 180, // CHANGED from 180
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // CHANGED from 12
          border: Border.all(color: const Color(0xFF00796B), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.50), // CHANGED from 0.35
              blurRadius: 24, // CHANGED from 16
              offset: const Offset(0, 8), // CHANGED from (0, 6)
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14), // CHANGED from 10
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Video preview ──────────────────
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,

                  child: SizedBox(
                    width: 1920,
                    height: 1080,

                    child: Video(
                      controller: widget.controller,
                      controls: NoVideoControls,
                    ),
                  ),
                ),
              ),

              // ── Muted + Preview badge ──────────
              Positioned(
                top: 8, // CHANGED from 6
                right: 8, // CHANGED from 6
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ), // CHANGED from (6, 3)
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6), // CHANGED from 4
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_off,
                        size: 12,
                        color: Colors.white70,
                      ), // CHANGED from 10
                      SizedBox(width: 4), // CHANGED from 3
                      Text(
                        'Preview',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11, // CHANGED from 9
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Title gradient bar ─────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ), // CHANGED from (8, 6)
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13, // CHANGED from 10
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}