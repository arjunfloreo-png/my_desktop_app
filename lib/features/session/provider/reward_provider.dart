import 'package:flutter/material.dart';
import '../apis/reward_api.dart';
import '../models/chaacter_mpdel.dart';
import '../models/flying_badge.dart';
import '../models/reward_badge.dart';
import '../models/reward_box_model.dart';

class RewardProvider extends ChangeNotifier {
  final TickerProvider vsync;

  RewardProvider({required this.vsync});

  // ── Drawer ────────────────────────────────────────────────────
  bool isDrawerOpen  = false;
  bool showAllBadges = false;

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

  // ── Walking character animation ────────────────────────────────
  late final AnimationController walkCtrl = AnimationController(
    vsync: vsync,
    duration: const Duration(seconds: 6),
  )..repeat();

  late final Animation<double> walkAnim =
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: walkCtrl, curve: Curves.linear),
      );

  // ── API data ───────────────────────────────────────────────────
  List<ReactionItem>  reactions     = [];
  List<CharacterItem> apiCharacters = [];
  bool   isLoading  = false;
  String? fetchError;

  Future<void> loadRewardBox() async {
    isLoading  = true;
    fetchError = null;
    notifyListeners();
    try {
      final data  = await RewardApi.fetchRewardBox();
      reactions     = data.reactions;
      apiCharacters = data.characters;
    } catch (e) {
      fetchError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Selected character (used by VideoPanel / BouncingCharacter) ─
  /// Backed by the old Character model so BouncingCharacter stays unchanged.
  Character? selectedCharacter;

  void selectCharacterFromApi(CharacterItem item) {
    selectedCharacter = Character(
      id:       item.name,
      name:     item.name,
      imageUrl: RewardApi.fullUrl(item.imagePath),
      role:     '',
      bgColor:  const Color(0xFF00bd74),
    );
    notifyListeners();
  }

  // ── Flying animations ─────────────────────────────────────────
  final List<FlyingBadge> flyingBadges = [];
  int _idCounter = 0;

  /// Launch from API reaction
  void launchReaction(ReactionItem reaction) {
    _launch(reaction: reaction);
  }

  /// Legacy: launch from RewardBadge (keep for any existing callers)
  void launchBadge(RewardBadge badge) {
    _launch(badge: badge);
  }

  void _launch({RewardBadge? badge, ReactionItem? reaction}) {
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
      id:        id,
      badge:     badge,
      reaction:  reaction,
      controller: ctrl,
      slideY:    slideY,
      opacity:   opacity,
      scale:     scale,
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
    walkCtrl.dispose();
    for (final fb in flyingBadges) {
      fb.controller.dispose();
    }
    flyingBadges.clear();
    super.dispose();
  }
}
