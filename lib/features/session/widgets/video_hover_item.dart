
// ── Video item row with hover detection ──────────
import 'package:flutter/material.dart';

import '../models/video_item.dart';

class VideoHoverItem extends StatefulWidget {
  final VideoItem video;
  final VoidCallback onTap;
  final Function(Offset position, Size size) onHoverEnter;
  final VoidCallback onHoverExit;

  const VideoHoverItem({
    required this.video,
    required this.onTap,
    required this.onHoverEnter,
    required this.onHoverExit,
  });

  @override
  State<VideoHoverItem> createState() => VideoHoverItemState();
}

class VideoHoverItemState extends State<VideoHoverItem> {
  bool _isHovered = false;
  final GlobalKey _key = GlobalKey();

  void _onEnter() {
    setState(() => _isHovered = true);
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      widget.onHoverEnter(position, size);
    }
  }

  void _onExit() {
    setState(() => _isHovered = false);
    widget.onHoverExit();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          key: _key,
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(left: 48, right: 12, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFE0F2F1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF00796B)
                  : const Color(0xFFB2DFDB),
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: _isHovered
                    ? const Color(0xFF00796B)
                    : const Color(0xFF80CBC4),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.video.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _isHovered
                        ? const Color(0xFF004D40)
                        : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _isHovered
                    ? const Color(0xFF00796B)
                    : const Color(0xFFB2DFDB),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}