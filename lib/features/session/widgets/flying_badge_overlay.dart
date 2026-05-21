import 'package:flutter/material.dart';

import '../apis/reward_api.dart';
import '../models/flying_badge.dart';
import '../models/reward_badge.dart';
import '../models/reward_box_model.dart';

class FlyingBadgeOverlay extends StatelessWidget {
  final List<FlyingBadge> flyingBadges;

  const FlyingBadgeOverlay({super.key, required this.flyingBadges});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: flyingBadges.map((fb) {
        return AnimatedBuilder(
          animation: fb.controller,
          builder: (_, __) => Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: fb.opacity.value,
                child: Align(
                  alignment: Alignment(0, fb.slideY.value),
                  child: Transform.scale(
                    scale: fb.scale.value,
                    child: fb.badge != null
                        ? 
                        _badgeWidget(fb.badge!)
                        : _reactionWidget(fb.reaction!),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _badgeWidget(RewardBadge badge) {
    final isDark = badge.bgColor.computeLuminance() < 0.4;
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        color: badge.bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: badge.bgColor.withOpacity(0.65),
              blurRadius: 35,
              spreadRadius: 8,
              offset: const Offset(0, 4)),
          BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 16,
              offset: const Offset(0, 8)),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 3.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badge.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Text(badge.emoji, style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 4),
          Text(badge.name,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _reactionWidget(ReactionItem reaction) {
    return Container(
      width: 170,
      height: 170,
      // decoration: BoxDecoration(
      //   color: const Color(0xFF00796B),
      //   shape: BoxShape.circle,
      //   boxShadow: [
      //     BoxShadow(
      //         color: const Color(0xFF00796B).withOpacity(0.65),
      //         blurRadius: 35,
      //         spreadRadius: 8,
      //         offset: const Offset(0, 4)),
      //     BoxShadow(
      //         color: Colors.black.withOpacity(0.22),
      //         blurRadius: 16,
      //         offset: const Offset(0, 8)),
      //   ],
      //   border: Border.all(color: Colors.white.withOpacity(0.35), width: 3.5),
      // ),
      child: 
       Image.network(
            RewardApi.fullUrl(reaction.gifPath),
            width: 80,
            height: 80,
            headers: const {'ngrok-skip-browser-warning': 'true'},
            errorBuilder: (_, __, ___) => const Icon(
              Icons.emoji_emotions,
              color: Colors.white,
              size: 60,
            ),
          ),
    );
  }
}
