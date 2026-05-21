import 'package:flutter/material.dart';
import 'reward_badge.dart';
import 'reward_box_model.dart';

class FlyingBadge {
  final int id;

  /// One of these will be set depending on source
  final RewardBadge? badge;
  final ReactionItem? reaction;

  final AnimationController controller;
  final Animation<double> slideY;
  final Animation<double> opacity;
  final Animation<double> scale;

  FlyingBadge({
    required this.id,
    this.badge,
    this.reaction,
    required this.controller,
    required this.slideY,
    required this.opacity,
    required this.scale,
  }) : assert(badge != null || reaction != null,
            'badge or reaction must be provided');

  /// Display label
  String get label => badge?.label ?? reaction!.name;
}
