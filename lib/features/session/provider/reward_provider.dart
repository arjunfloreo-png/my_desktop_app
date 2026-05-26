// lib/provider/reward_provider.dart

import 'package:floreo/cores/media_duration.dart';
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

  /// Fetch character VODs with thumbnail + duration
  Future<List<MiniVod>> _fetchCharacterVods() async {
    final chars = await RewardApi.fetchCharacterVods();
    final vods = chars.map((char) {
      // Convert relative path to full URL
     final gifPath = Uri.encodeFull(
  char.character.startsWith('http')
      ? char.character
      : 'https://fabric-unloader-spray.ngrok-free.dev/${char.character}'
);
      
      var vod = MiniVod.fromCharacter(char);
      vod.thumbnailUrl = gifPath;
      return vod;
    }).toList();
    
    await Future.wait(
      vods.map((vod) async {
        try {
          final dur = await getMediaDuration(vod.videoUrl);
          if (dur != null) vod.duration = dur;
        } catch (e) {
          print('⚠ Failed fetching duration for ${vod.name}: $e');
        }
      }),
    );
    return vods;
  }

  /// Fetch reaction VODs with thumbnail + duration
  Future<List<MiniVod>> _fetchReactionVods() async {
    try {
      print('DEBUG: Calling RewardApi.fetchReactionVods()...');
      final reacts = await RewardApi.fetchReactionVods();
      print('DEBUG: Reactions fetched: ${reacts.length}');
      for (var r in reacts) {
        print('  - ${r.name1} (${r.vimeoId})');
      }
      
      final vods = reacts.map((react) => MiniVod.fromReaction(react)).toList();
      print('DEBUG: MiniVods created: ${vods.length}');
      
      await Future.wait(
        vods.map((vod) async {
          try {
            final info = await VimeoService.getVideoInfo(vod.id);
            print('✓ Vimeo info for ${vod.name}: thumb=${info.thumb}, duration=${info.duration}');
            if (info.thumb.isNotEmpty) {
              vod.thumbnailUrl = info.thumb;
            } else {
              // Fallback to vimeoThumbnailUrl from API
              print('⚠ No thumb from Vimeo, using API thumbnail');
            }
            if (info.duration != null && info.duration!.inSeconds > 0) {
              vod.duration = info.duration!;
            } else {
              final dur = await getMediaDuration(vod.videoUrl);
              if (dur != null) vod.duration = dur;
            }
          } catch (e) {
            print('⚠ Failed fetching vimeo info for ${vod.name}: $e. Using fallback.');
            // Use videoUrl to get duration
            final dur = await getMediaDuration(vod.videoUrl);
            if (dur != null) vod.duration = dur;
          }
        }),
      );
      print('DEBUG: Final vods: ${vods.map((v) => '${v.name}(thumb:${v.thumbnailUrl.isNotEmpty})').join(', ')}');
      return vods;
    } catch (e) {
      print('ERROR in _fetchReactionVods: $e');
      rethrow;
    }
  }

  void clearReactionVod() {
    _selectedReactionVod = null;
    notifyListeners();
  }

  void _prefetchVisibleThumbnails({int visibleCount = 12}) {
    final allVods = [...characterVods, ...reactionVods];
    final visible = allVods.take(visibleCount).map((v) => v.thumbnailUrl).toList();
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

  // ── VOD Selection ─────────────────────────────────────────────────────

  MiniVod? _selectedCharacterVod;
  MiniVod? _selectedReactionVod;

  MiniVod? get selectedCharacterVod => _selectedCharacterVod;
  MiniVod? get selectedReactionVod => _selectedReactionVod;

  void selectVod(MiniVod vod) {
    if (vod.category == 'Character') {
      _selectedCharacterVod = vod;
    } else if (vod.category == 'Reaction') {
      _selectedReactionVod = vod;
      // Auto-clear after reaction duration
      Future.delayed(vod.duration, () {
        _selectedReactionVod = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void clearSelectedVod() {
    _selectedCharacterVod = null;
    _selectedReactionVod = null;
    notifyListeners();
  }

  // ── Character ─────────────────────────────────────────────────────────

  dynamic selectedCharacter;

  void selectCharacterFromApi(dynamic character) {
    selectedCharacter = character;
    notifyListeners();
  }

  // ── Flying Badges ─────────────────────────────────────────────────────

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
