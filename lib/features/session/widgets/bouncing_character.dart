import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/chaacter_mpdel.dart';

const double kCharacterWidth = 130.0;

class BouncingCharacter extends StatefulWidget {
  final Character? character;
  final bool faceOnly; // ← NEW: hides name/role badge

  const BouncingCharacter({
    super.key,
    this.character,
    this.faceOnly = false,
  });

  @override
  State<BouncingCharacter> createState() => _BouncingCharacterState();
}

class _BouncingCharacterState extends State<BouncingCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0.0, end: -12.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _bounce.value), child: child),
      child: widget.character != null
          ? _networkCharacter(widget.character!)
          : _lottieCharacter(),
    );
  }

  Widget _networkCharacter(Character character) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: kCharacterWidth,
          height: kCharacterWidth,
       
          child: Image.network(
            character.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: character.bgColor,
                    ),
                  ),
            errorBuilder: (_, __, ___) =>
                Icon(Icons.person, size: 60, color: character.bgColor),
          ),
        ),
        // ← only show badge when not faceOnly
        if (!widget.faceOnly) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: character.bgColor.withOpacity(0.6), width: 1),
            ),
            child: Column(
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  character.role,
                  style: TextStyle(color: character.bgColor, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _lottieCharacter() {
    return SizedBox(
      width: kCharacterWidth,
      child: Lottie.asset('assets/lottie/character.json'),
    );
  }
}
