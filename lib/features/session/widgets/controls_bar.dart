import 'package:flutter/material.dart';

import '../provider/video_provider.dart';
import '../provider/reward_provider.dart';

enum _ActionStyle { filled, soft, outline, danger }

class ControlsBar extends StatelessWidget {
  final VideoProvider videoProvider;
  final RewardProvider rewardProvider;
  final VoidCallback onEndSession;
 //inal bool showCharacter;     // kept for compatibility (not used here)
 //inal String currentPrompt;   // kept for compatibility (not used here)

  const ControlsBar({
    super.key,
    required this.videoProvider,
    required this.rewardProvider,
    required this.onEndSession,
//  required this.showCharacter,
   //equired this.currentPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xff00bd74)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (videoProvider.isVideoMode) _scrubRow(),
          const SizedBox(height: 8),
          _actionRow(),
        ],
      ),
    );
  }

  // ── SCRUB ROW ─────────────────────────────────────────────
  Widget _scrubRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: videoProvider.toggleMute,
          child: Icon(
            videoProvider.isVolMuted
                ? Icons.volume_off
                : videoProvider.volume < 0.4
                    ? Icons.volume_down
                    : Icons.volume_up,
            color: const Color(0xff00bd74),
            size: 22,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 100,
          child: _slider(
            value: videoProvider.isVolMuted ? 0 : videoProvider.volume,
            max: 1.0,
            onChanged: videoProvider.setVolume,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _slider(
            value: videoProvider.position.inMilliseconds
                .toDouble()
                .clamp(
                    0,
                    videoProvider.duration.inMilliseconds
                        .toDouble()
                        .clamp(1, double.infinity)),
            max: videoProvider.duration.inMilliseconds
                .toDouble()
                .clamp(1, double.infinity),
            onChanged: (v) =>
                videoProvider.seek(Duration(milliseconds: v.toInt())),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${videoProvider.formatDuration(videoProvider.position)}/${videoProvider.formatDuration(videoProvider.duration)}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── ACTION BUTTONS ─────────────────────────────────────────
  Widget _actionRow() {
    final active = videoProvider.isVideoMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _btn(
          label: 'TAKE ME BACK',
          style: _ActionStyle.soft,
          onTap: active ? videoProvider.skipBack : null,
        ),
        _btn(
          label: videoProvider.isVideoPlaying
              ? 'POSE A QUESTION'
              : 'ASKING...',
          style: _ActionStyle.outline,
          onTap: active ? videoProvider.togglePlayPause : null,
        ),
        _timerBtn(),
        _btn(
          icon: Icons.call_end_sharp,
          label: '',
          style: _ActionStyle.danger,
          onTap: onEndSession,
          isIcon: true,
        ),
        _btn(
          label: 'DIVE IN',
          style: _ActionStyle.filled,
          onTap: active ? videoProvider.skipForward : null,
        ),
        _btn(
          label: 'LET ME SHARE',
          style: _ActionStyle.outline,
          onTap: active ? videoProvider.toggleLibrary : null,
        ),
        _btn(
          label: '🏅 REWARD BOX',
          style: _ActionStyle.outline,
          onTap: rewardProvider.toggleDrawer,
        ),
      ],
    );
  }

  // ── TIMER BUTTON ───────────────────────────────────────────
  Widget _timerBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00bd74),
        border: Border.all(width: 4, color: const Color(0xff005735)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Icon(Icons.timer, color: Colors.white),
    );
  }

  // ── SLIDER ────────────────────────────────────────────────
  Widget _slider({
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: const Color(0xff00bd74),
        inactiveTrackColor: Colors.black12,
        thumbColor: const Color(0xffdaf9ed),
        overlayColor: Colors.black12,
      ),
      child: Slider(
        value: value,
        min: 0,
        max: max,
        onChanged: onChanged,
      ),
    );
  }

  // ── BUTTON ────────────────────────────────────────────────
  Widget _btn({
    IconData? icon,
    required String label,
    required _ActionStyle style,
    VoidCallback? onTap,
    bool isIcon = false,
  }) {
    final disabled = onTap == null;
    BoxDecoration deco;
    TextStyle ts;

    switch (style) {
      case _ActionStyle.filled:
      case _ActionStyle.soft:
        deco = BoxDecoration(
          color: disabled
              ? const Color.fromARGB(255, 200, 238, 223)
              : const Color(0xFF00bd74),
          border: Border.all(
            width: 4,
            color: disabled
                ? const Color.fromARGB(255, 200, 238, 223)
                : const Color(0xff005735),
          ),
          borderRadius: BorderRadius.circular(30),
        );
        ts = const TextStyle(
          color: Color(0xffdaf9ed),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        );
        break;

      case _ActionStyle.outline:
        deco = BoxDecoration(
          color: disabled
              ? const Color.fromARGB(255, 200, 238, 223)
              : const Color(0xFF00bd74),
          border: Border.all(
            width: 4,
            color: disabled
                ? const Color.fromARGB(255, 200, 238, 223)
                : const Color(0xff005735),
          ),
          borderRadius: BorderRadius.circular(30),
        );
        ts = const TextStyle(
          color: Color(0xffdaf9ed),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        );
        break;

      case _ActionStyle.danger:
        deco = BoxDecoration(
          color: disabled ? Colors.red.shade200 : Colors.red,
          border: Border.all(
            width: 4,
            color: disabled
                ? const Color.fromARGB(255, 200, 238, 223)
                : const Color(0xff005735),
          ),
          shape: BoxShape.circle,
        );
        ts = const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        );
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: deco,
        child: isIcon
            ? Icon(icon, color: Colors.white)
            : Text(label, textAlign: TextAlign.center, style: ts),
      ),
    );
  }
}