import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

const double kCharacterWidth = 130.0;

class BouncingCharacter extends StatefulWidget {
  const BouncingCharacter({super.key});

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
      child: SizedBox(
        width: kCharacterWidth,
        child: Lottie.asset('assets/lottie/character.json'),
      ),
    );
  }
}
