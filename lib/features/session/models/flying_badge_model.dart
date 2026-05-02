

// ── Flying badge animation model ─────────────────────────────
import 'package:flutter/material.dart';

import 'reward_badge_model.dart';

class _FlyingBadge {
  final int id;
  final RewardBadge badge;
  final AnimationController controller;
  final Animation<double> slideY;
  final Animation<double> opacity;
  final Animation<double> scale;

  _FlyingBadge({
    required this.id,
    required this.badge,
    required this.controller,
    required this.slideY,
    required this.opacity,
    required this.scale,
  });
}
