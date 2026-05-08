import 'package:flutter/material.dart';
import 'reward_badge.dart';

class FlyingBadge {
  final int id;
  final RewardBadge badge;
  final AnimationController controller;
  final Animation<double> slideY;
  final Animation<double> opacity;
  final Animation<double> scale;

  FlyingBadge({
    required this.id,
    required this.badge,
    required this.controller,
    required this.slideY,
    required this.opacity,
    required this.scale,
  });
}
