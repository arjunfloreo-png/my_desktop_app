// lib/provider/reward_provider.dart

import 'package:flutter/material.dart';
import '../../../services/thumbnail_cache_service.dart';
import '../../../services/vimeo_service.dart';
import '../apis/reward_api.dart';
import '../models/mini_vod.dart';

class RewardProvider extends ChangeNotifier {
  final TickerProvider vsync;

  RewardProvider({required this.vsync});

  late final ThumbnailCacheService _thumbCache = ThumbnailCacheService(
    maxMemoryMB: 150,
    maxPrefetchQueue: 100,
    ttl: const Duration(hours: 24),
  );

  ThumbnailCacheService get thumbnailCache => _thumbCache;

  bool isDrawerOpen = false;

  late final AnimationController drawerCtrl = AnimationController(
    vsync: vsync,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<Offset> drawerSlide = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: drawerCtrl, curve: Curves.easeOutCubic));

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

  late final AnimationController walkCtrl = AnimationController(
    vsync: vsync,
    duration: const Duration(seconds: 6),
  )..repeat();

  late final Animation<double> walkAnim = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(CurvedAnimation(parent: walkCtrl, curve: Curves.linear));

  List<MiniVod> characterVods = [];
  List<MiniVod> reactionVods = [];
  bool isLoading = false;
  String? fetchError;

  Future<void> loadRewardBox() async {
    isLoading = true;
    fetchError = null;
    notifyListeners();
    try {
      characterVods = await _fetchCharacterVods();
      reactionVods = await _fetchReactionVods();
      _prefetchVisibleThumbnails();
    } catch (e) {
      fetchError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  
  Future<List<MiniVod>> _fetchCharacterVods() async {
    final chars = await RewardApi.fetchCharacterVods();
    
    final vods = chars
        .map((char) => MiniVod.fromCharacter(char, type: 'character'))
        .toList();
    
    // Fetch real Vimeo thumbnails in parallel
    await Future.wait(
      vods.map((vod) async {
        try {
          final thumbUrl = await VimeoService.getThumbnailUrl(vod.id);
          if (thumbUrl.isNotEmpty) {
            vod.thumbnailUrl = thumbUrl;
          }
        } catch (e) {
          print('Failed to get thumbnail for ${vod.name}: $e');
        }
      }),
    );
    
    return vods;
  }

  Future<List<MiniVod>> _fetchReactionVods() async {
    final reacts = await RewardApi.fetchReactionVods();
    
    final vods = reacts
        .map((react) => MiniVod.fromCharacter(react, type: 'reaction'))
        .toList();
    
    // Fetch real Vimeo thumbnails in parallel
    await Future.wait(
      vods.map((vod) async {
        try {
          final thumbUrl = await VimeoService.getThumbnailUrl(vod.id);
          if (thumbUrl.isNotEmpty) {
            vod.thumbnailUrl = thumbUrl;
          }
        } catch (e) {
          print('Failed to get thumbnail for ${vod.name}: $e');
        }
      }),
    );
    
    return vods;
  }


  void _prefetchVisibleThumbnails({int visibleCount = 12}) {
    final allVods = [...characterVods, ...reactionVods];
    final visible = allVods
        .take(visibleCount)
        .map((v) => v.thumbnailUrl)
        .toList();
    _thumbCache.prefetch(visible, highPriority: true);
  }

  void prefetchMore(int startIndex, int count) {
    final allVods = [...characterVods, ...reactionVods];
    final batch = allVods
        .skip(startIndex)
        .take(count)
        .map((v) => v.thumbnailUrl)
        .toList();
    _thumbCache.prefetch(batch, highPriority: false);
  }

  MiniVod? selectedVod;

  void selectVod(MiniVod vod) {
    selectedVod = vod;
    notifyListeners();
  }

  void clearSelectedVod() {
    selectedVod = null;
    notifyListeners();
  }

  dynamic selectedCharacter;

  void selectCharacterFromApi(dynamic character) {
    selectedCharacter = character;
    notifyListeners();
  }

  final List<FlyingBadge> flyingBadges = [];
  int _idCounter = 0;

  void launchVod(MiniVod vod) {
    _launchFlyingBadge(thumbnailUrl: vod.thumbnailUrl);
  }

  void _launchFlyingBadge({
    required String thumbnailUrl,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    final id = _idCounter++;
    final ctrl = AnimationController(vsync: vsync, duration: duration);

    final slideY = Tween<double>(
      begin: 1.2,
      end: -0.4,
    ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));

    final opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 72),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(ctrl);

    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.3,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
    ]).animate(ctrl);

    final badge = FlyingBadge(
      id: id,
      thumbnailUrl: thumbnailUrl,
      controller: ctrl,
      slideY: slideY,
      opacity: opacity,
      scale: scale,
    );

    flyingBadges.add(badge);
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
    for (final badge in flyingBadges) {
      badge.controller.dispose();
    }
    flyingBadges.clear();
    _thumbCache.dispose();
    super.dispose();
  }
}

class FlyingBadge {
  final int id;
  final String thumbnailUrl;
  final AnimationController controller;
  final Animation<double> slideY;
  final Animation<double> opacity;
  final Animation<double> scale;

  FlyingBadge({
    required this.id,
    required this.thumbnailUrl,
    required this.controller,
    required this.slideY,
    required this.opacity,
    required this.scale,
  });
}
