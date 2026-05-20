// // ─────────────────────────────────────────────────────────────
// // HEADER LEGEND BADGE
// // ─────────────────────────────────────────────────────────────
// import 'package:flutter/material.dart';
//
// class LegendBadge extends StatelessWidget {
//   final bool isExternal;
//
//   const LegendBadge({
//     required this.isExternal,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final bgColor = isExternal
//         ? const Color(0xFFFFF3E0)
//         : const Color(0xFFE8F5E9);
//
//     final dotColor = isExternal
//         ? const Color(0xFFFF9800)
//         : const Color(0xFF43A047);
//
//     final textColor = isExternal
//         ? const Color(0xFFE65100)
//         : const Color(0xFF1B5E20);
//
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 8,
//         vertical: 5,
//       ),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: dotColor.withOpacity(0.35),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(
//               color: dotColor,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 5),
//           Text(
//             isExternal ? 'External Link' : 'MP4 Video',
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w700,
//               color: textColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }