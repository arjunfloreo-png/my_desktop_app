import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../provider/role_selection_provider.dart';
import 'session_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00bd74),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xff005735), width: 3),
                ),
                child: Image.asset(
                  'assets/images/floreo_logo.png',
                  width: 150,
                  height: 150,
                ),
                //  const Center(
                //   child: Text('🌿', style: TextStyle(fontSize: 36)),
                // ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Floreo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF005735),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your role to join the session',
                style: TextStyle(fontSize: 15, color: Colors.black45),
              ),
              const SizedBox(height: 48),

              // Therapist
              _RoleCard(
                emoji: '🩺',
                title: 'Therapist',
                subtitle: 'Manage session, share videos & rewards',
                color: const Color(0xFF00bd74),
                borderColor: const Color(0xff005735),
                textColor: Colors.white,
                onTap: () => _navigate(context, UserRole.therapist),
              ),
              const SizedBox(height: 16),

              // Client
              _RoleCard(
                emoji: '🧒',
                title: 'Client',
                subtitle: 'Join and participate in the session',
                color: Colors.white,
                borderColor: const Color(0xFF00bd74),
                textColor: const Color(0xFF005735),
                onTap: () => _navigate(context, UserRole.client),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigate(BuildContext context, UserRole role) async {
    final provider = Provider.of<RoleSelectionProvider>(context, listen: false);

    final response = await provider.generateAgoraToken(
      channelName: "demoWebsockets",
      uid: role == UserRole.therapist ? 1 : 2,
      role: "publisher",
    );

    if (response != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionScreen(
            role: role,

            token: response.token,
            channelName: response.channelName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Something went wrong')),
      );
    }
  }
}
//   void _navigate(BuildContext context, UserRole role) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => SessionScreen(role: role)),
//     );
//   }
// }

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,

    required this.title,
    required this.subtitle,
    required this.color,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
