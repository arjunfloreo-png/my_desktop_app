import 'package:flutter/material.dart';

import '../models/flying_badge.dart';
import '../models/reward_badge.dart';

class RewardProvider extends ChangeNotifier {
  final TickerProvider vsync;

  RewardProvider({required this.vsync});

  // ── Drawer ────────────────────────────────────────────────────
  bool isDrawerOpen   = false;
  bool showAllBadges  = false;

  late final AnimationController drawerCtrl = AnimationController(
    vsync: vsync,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<Offset> drawerSlide =
      Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
        CurvedAnimation(parent: drawerCtrl, curve: Curves.easeOutCubic),
      );

  void toggleDrawer() {
    if (isDrawerOpen) {
      drawerCtrl.reverse().then((_) {
        isDrawerOpen = false;
        notifyListeners();
      });
    } else {
      isDrawerOpen = true;
      drawerCtrl.forward();
      notifyListeners();
    }
  }

  void closeDrawer() {
    drawerCtrl.reset();
    isDrawerOpen = false;
    notifyListeners();
  }

  void toggleShowAll() {
    showAllBadges = !showAllBadges;
    notifyListeners();
  }

  // ── ✅ Walking character animation ─────────────────────────────
  late final AnimationController walkCtrl = AnimationController(
    vsync: vsync,
    duration: const Duration(seconds: 6),
  )..repeat(); // loops continuously

  late final Animation<double> walkAnim =
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: walkCtrl, curve: Curves.linear),
      );

  // ── Badge list ────────────────────────────────────────────────
  final List<RewardBadge> badges = [
    RewardBadge(label: 'Good Job',        emoji: '😊', bgColor: const Color(0xFFE53935), name: 'Name Here'),
    RewardBadge(label: "You're A Star",   emoji: '⭐', bgColor: const Color(0xFF1565C0), name: 'Name Here'),
    RewardBadge(label: 'Well Done',       emoji: '😎', bgColor: const Color(0xFF0D1B2A), name: 'Name Here'),
    RewardBadge(label: 'Fantastic Effort',emoji: '🤣', bgColor: const Color(0xFFE3F2FD), name: 'Name Here'),
    RewardBadge(label: 'Keep It Up',      emoji: '💪', bgColor: const Color(0xFF388E3C), name: 'Name Here'),
    RewardBadge(label: 'Super Work',      emoji: '🏆', bgColor: const Color(0xFFF57F17), name: 'Name Here'),
    RewardBadge(label: 'Amazing!',        emoji: '🎉', bgColor: const Color(0xFF6A1B9A), name: 'Name Here'),
    RewardBadge(label: 'Brilliant',       emoji: '🌟', bgColor: const Color(0xFF00838F), name: 'Name Here'),
  ];

  void addBadge(RewardBadge badge) {
    badges.add(badge);
    notifyListeners();
  }

  // ── Flying animations ─────────────────────────────────────────
  final List<FlyingBadge> flyingBadges = [];
  int _idCounter = 0;

  void launchBadge(RewardBadge badge) {
    final id   = _idCounter++;
    final ctrl = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 2000),
    );

    final slideY = Tween<double>(begin: 1.2, end: -0.4)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));

    final opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 72),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(ctrl);

    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
    ]).animate(ctrl);

    final flying = FlyingBadge(
      id: id,
      badge: badge,
      controller: ctrl,
      slideY: slideY,
      opacity: opacity,
      scale: scale,
    );

    flyingBadges.add(flying);
    notifyListeners();

    ctrl.forward().then((_) {
      ctrl.dispose();
      flyingBadges.removeWhere((b) => b.id == id);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    drawerCtrl.dispose();
    walkCtrl.dispose(); // ✅ important

    for (final fb in flyingBadges) {
      fb.controller.dispose();
    }
    flyingBadges.clear();

    super.dispose();
  }
}