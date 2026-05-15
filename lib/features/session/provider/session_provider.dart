import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user_role.dart';

const String appId = "54bf8a5095374303aa14ff23c73bac0d";
// const String token =
//     "007eJxTYPA4zhd6ue/9qycW3b9XeVoE1ITmVZzUWHKx68V78Xa1heUKDKYmSWkWiaYGlqbG5ibGBsaJiYYmaWlGxsnmxkmJyQYpYvfYshoCGRm8VZkZGKEQxOdjSEnNzQ9PTSrOT85OLSlmYAAA8uUjYA==";
// const String channel = "demoWebsockets";

/// UID reserved for the therapist's screen-share Agora engine (ScreenShareProvider).
/// When the client sees this UID join/leave it knows screen sharing started/stopped.
const int kScreenShareUid = 1001;

class SessionProvider extends ChangeNotifier {
  final UserRole role;
  final String token;
  final String channelName;
  SessionProvider({
    required this.role,
    required this.token,
    required this.channelName,
  }) {
    _initAgora();
  }

  late RtcEngine engine;

  int? remoteUid;
  bool localUserJoined = false;
  bool isSwapped = false;

  bool isTherapistMuted = false;
  bool isClientMuted = false;
  bool isTherapistVideoMuted = false;
  bool isClientVideoMuted = false;

  /// Whether the LOCAL user is sharing their screen.
  bool isScreenSharing = false;

  /// Whether the REMOTE peer is sharing their screen.
  /// Set to true when uid [kScreenShareUid] joins the channel,
  /// false when it leaves — no ambiguous video-state heuristics needed.
  bool isRemoteScreenSharing = false;

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    engine = createAgoraRtcEngine();
    await engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          localUserJoined = true;
          notifyListeners();
        },

        onUserJoined: (_, uid, __) {
          if (uid == kScreenShareUid) {
            // Therapist's screen-share engine joined → screen share started.
            isRemoteScreenSharing = true;
            debugPrint(
              '📡 Screen share UID $uid joined → isRemoteScreenSharing=true',
            );
          } else {
            // Regular camera participant (client uid=2 or therapist uid=1).
            remoteUid = uid;
            debugPrint('📡 Camera UID $uid joined → remoteUid=$remoteUid');
          }
          notifyListeners();
        },

        onUserOffline: (_, uid, __) {
          if (uid == kScreenShareUid) {
            // Screen-share engine left → screen share stopped.
            isRemoteScreenSharing = false;
            debugPrint(
              '📡 Screen share UID $uid left → isRemoteScreenSharing=false',
            );
          } else {
            remoteUid = null;
            isRemoteScreenSharing = false;
            debugPrint('📡 Camera UID $uid left → remoteUid=null');
          }
          notifyListeners();
        },

        onError: (err, msg) => debugPrint('❌ Agora: $err – $msg'),
      ),
    );

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.enableVideo();
    await engine.startPreview();

    debugPrint("TOKEN => $token");
    debugPrint("CHANNEL => $channelName");

    await engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: role == UserRole.therapist ? 1 : 2,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> startAreaScreenShare() async {
    try {
      await engine.startScreenCaptureByScreenRect(
        screenRect: const Rectangle(x: 0, y: 0, width: 1920, height: 1080),
        regionRect: const Rectangle(x: 100, y: 100, width: 800, height: 600),
        captureParams: const ScreenCaptureParameters(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 15,
          bitrate: 0,
          captureMouseCursor: true,
          windowFocus: false,
        ),
      );

      await engine.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenTrack: true,
          publishCameraTrack: false,
        ),
      );

      isScreenSharing = true;
      notifyListeners();

      debugPrint('Screen share started');
    } catch (e) {
      debugPrint('Screen Share Error: $e');
    }
  }

  Future<void> stopScreenShare() async {
    try {
      await engine.stopScreenCapture();

      await engine.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenTrack: false,
          publishCameraTrack: true,
        ),
      );

      isScreenSharing = false;
      notifyListeners();

      debugPrint('Screen sharing stopped');
    } catch (e) {
      debugPrint('Stop Share Error: $e');
    }
  }

  void toggleSwap() {
    isSwapped = !isSwapped;
    notifyListeners();
  }

  void toggleLocalAudio() {
    if (role == UserRole.therapist) {
      isTherapistMuted = !isTherapistMuted;
      engine.muteLocalAudioStream(isTherapistMuted);
    } else {
      isClientMuted = !isClientMuted;
      engine.muteLocalAudioStream(isClientMuted);
    }
    notifyListeners();
  }

  void toggleLocalVideo() {
    if (role == UserRole.therapist) {
      isTherapistVideoMuted = !isTherapistVideoMuted;
      engine.muteLocalVideoStream(isTherapistVideoMuted);
    } else {
      isClientVideoMuted = !isClientVideoMuted;
      engine.muteLocalVideoStream(isClientVideoMuted);
    }
    notifyListeners();
  }

  Future<void> endSession() async {
    await engine.leaveChannel();
    await engine.release();
  }

  @override
  void dispose() {
    engine.leaveChannel();
    engine.release();
    super.dispose();
  }
}
