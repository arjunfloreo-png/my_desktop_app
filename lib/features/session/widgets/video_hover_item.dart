
// ── Video item row with hover detection ──────────
import 'package:flutter/material.dart';

import '../models/video_item.dart';

class VideoHoverItem extends StatefulWidget {
  final VideoItem video;
  final VoidCallback onTap;
  final Function(Offset position, Size size) onHoverEnter;
  final VoidCallback onHoverExit;

  const VideoHoverItem({
    super.key,
    required this.video,
    required this.onTap,
    required this.onHoverEnter,
    required this.onHoverExit,
  });

  @override
  State<VideoHoverItem> createState() => _VideoHoverItemState();
}

class _VideoHoverItemState extends State<VideoHoverItem> {
  bool _isHovered = false;
  final GlobalKey _key = GlobalKey();

  void _onEnter() {
    setState(() => _isHovered = true);
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      widget.onHoverEnter(box.localToGlobal(Offset.zero), box.size);
    }
  }

  void _onExit() {
    setState(() => _isHovered = false);
    widget.onHoverExit();
  }

  @override
  Widget build(BuildContext context) {
    final isExternal = widget.video.isExternal;

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
              // ── Play / Link icon based on type ─────
              Icon(
                isExternal
                    ? Icons.open_in_new_rounded
                    : Icons.play_circle_outline_rounded,
                color: _isHovered
                    ? const Color(0xFF00796B)
                    : const Color(0xFF80CBC4),
                size: 22,
              ),
              const SizedBox(width: 10),

              // ── Title ──────────────────────────────
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // ── Type badge (MP4 / Link) ─────────────
              _TypeBadge(isExternal: isExternal),
              const SizedBox(width: 6),

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

// ─────────────────────────────────────────────────────────────
// TYPE BADGE
// ─────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final bool isExternal;

  const _TypeBadge({required this.isExternal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isExternal
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isExternal
              ? const Color(0xFFFFB74D)
              : const Color(0xFF81C784),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExternal ? Icons.link_rounded : Icons.videocam_rounded,
            size: 9,
            color: isExternal
                ? const Color(0xFFE65100)
                : const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 3),
          Text(
            isExternal ? 'Link' : 'MP4',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isExternal
                  ? const Color(0xFFE65100)
                  : const Color(0xFF2E7D32),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
