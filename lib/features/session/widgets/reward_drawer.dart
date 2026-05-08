import 'package:flutter/material.dart';

import '../models/reward_badge.dart';
import '../provider/reward_provider.dart';

class RewardDrawer extends StatelessWidget {
  final RewardProvider rewardProvider;

  const RewardDrawer({super.key, required this.rewardProvider});

  @override
  Widget build(BuildContext context) {
    final visible = rewardProvider.showAllBadges
        ? rewardProvider.badges
        : rewardProvider.badges.take(6).toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xff00bd74), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(-4, 0))],
        ),
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: visible.map((b) => _badgeTile(b)).toList(),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: rewardProvider.toggleShowAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(rewardProvider.showAllBadges ? Icons.expand_less : Icons.expand_more,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(rewardProvider.showAllBadges ? 'Show Less' : 'Show All',
                                style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF00796B),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
      ),
      child: Row(
        children: [
          const Text('🏅  REWARD BOX',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5)),
          const Spacer(),
          GestureDetector(
            onTap: rewardProvider.toggleDrawer,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _badgeTile(RewardBadge badge, {double size = 100}) {
    final isDark = badge.bgColor.computeLuminance() < 0.4;
    return GestureDetector(
      onTap: () => rewardProvider.launchBadge(badge),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: badge.bgColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: badge.bgColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(badge.label,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 9, fontWeight: FontWeight.w700, height: 1.1)),
            const SizedBox(height: 4),
            Text(badge.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(badge.name,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 8)),
          ],
        ),
      ),
    );
  }
}
