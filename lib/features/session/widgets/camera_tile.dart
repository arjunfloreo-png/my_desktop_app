import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../provider/session_provider.dart';

class CameraTile extends StatelessWidget {
  final SessionProvider session;
  final bool isRemote;
  final bool large;

  const CameraTile({
    super.key,
    required this.session,
    required this.isRemote,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: const Color(0xff00bd74)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _videoView(),
          Positioned(bottom: 6, left: 8, child: _livePill()),
          Positioned(top: 6, right: 6, child: _controls()),
        ],
      ),
    );
  }

  Widget _videoView() {
    // ── REMOTE USER VIEW ──────────────────────────
    if (isRemote) {
      if (session.remoteUid == null && !session.isRemoteScreenSharing) {
        return Center(
          child: Text(
            session.role == UserRole.therapist
                ? 'Waiting for client...'
                : 'Waiting for therapist...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: large ? 15 : 11,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }

      // Only therapist renders the screen-share stream.
      // Client always shows therapist camera — never screen-share UID.
      if (session.isRemoteScreenSharing && session.role == UserRole.therapist) {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: session.engine,
            canvas: const VideoCanvas(
              uid: kScreenShareUid,
              sourceType: VideoSourceType.videoSourceRemote,
            ),
            connection: RtcConnection(channelId: session.channelName),
          ),
        );
      }

      // Normal camera view (client always; therapist when no screen share)
      if (session.remoteUid == null) {
        return Center(
          child: Text(
            session.role == UserRole.therapist
                ? 'Waiting for client...'
                : 'Waiting for therapist...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: large ? 15 : 11,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }

      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: session.engine,
          canvas: VideoCanvas(
            uid: session.remoteUid,
            sourceType: VideoSourceType.videoSourceRemote, // ✅ correct for remote user
          ),
          connection: RtcConnection(channelId: session.channelName),
        ),
      );
    }

    // ── LOCAL USER VIEW ───────────────────────────
    if (!session.localUserJoined) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white54,
          strokeWidth: 2,
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: session.engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _livePill() {
    final label = isRemote
        ? (session.role == UserRole.therapist ? 'Client' : 'Therapist')
        : (session.role == UserRole.therapist ? 'Therapist' : 'Client');

    // Show "Screen Share" label only on therapist side
    final displayLabel =
        (isRemote && session.isRemoteScreenSharing && session.role == UserRole.therapist)
            ? 'Screen Share'
            : label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              // Green dot only on therapist side when screen sharing
              color: (isRemote &&
                      session.isRemoteScreenSharing &&
                      session.role == UserRole.therapist)
                  ? const Color(0xFF00bd74)
                  : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            displayLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    final isMuted = isRemote
        ? (session.role == UserRole.therapist
            ? session.isTherapistMuted
            : session.isClientMuted)
        : (session.role == UserRole.therapist
            ? session.isTherapistMuted
            : session.isClientMuted);

    final isVideoMuted = isRemote
        ? (session.role == UserRole.therapist
            ? session.isTherapistVideoMuted
            : session.isClientVideoMuted)
        : (session.role == UserRole.therapist
            ? session.isTherapistVideoMuted
            : session.isClientVideoMuted);

    return Row(
      children: [
        _tinyBtn(
          icon: isMuted ? Icons.mic_off : Icons.mic,
          onTap: session.toggleLocalAudio,
        ),
        const SizedBox(width: 4),
        _tinyBtn(
          icon: isVideoMuted ? Icons.videocam_off : Icons.videocam,
          onTap: session.toggleLocalVideo,
        ),
      ],
    );
  }

  Widget _tinyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}
