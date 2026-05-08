
// ── Walking character widget ────────────────────────────────────────────────

import 'package:flutter/material.dart';

import 'bouncing_character.dart';
import 'bubble_tail_painter.dart';

class WalkingCharacter extends StatelessWidget {
  final Animation<double> walkAnim;
  final String currentPrompt;

  const WalkingCharacter({
    super.key,
    required this.walkAnim,
    required this.currentPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Character+bubble column is ~120 px wide; keep it fully visible
        const charWidth = 120.0;
        final travel = totalWidth - charWidth;

        return SizedBox(
          height: 90, // enough for bubble + character
          child: AnimatedBuilder(
            animation: walkAnim,
            builder: (context, child) {
              final x = walkAnim.value * travel;
              return Stack(
                children: [
                  Positioned(
                    left: x,
                    top: 0,
                    width: charWidth,
                    child: child!,
                  ),
                ],
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Speech bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.72),
                    border: Border.all(
                        color: const Color(0xff00bd74), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    currentPrompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff00e68a),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CustomPaint(
                    size: const Size(14, 8), painter: BubbleTailPainter()),
                const SizedBox(height: 2),
                const BouncingCharacter(),
              ],
            ),
          ),
        );
      },
    );
  }
}