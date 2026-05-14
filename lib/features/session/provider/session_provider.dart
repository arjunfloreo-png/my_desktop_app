import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user_role.dart';

const String appId = "54bf8a5095374303aa14ff23c73bac0d";
const String token =
    "007eJxTYHC7e6Vn27QVr/Kd9T0tg+deY0+7s2g2n+XSqBMsF0wVCo0VGExNktIsEk0NLE2NzU2MDYwTEw1N0tKMjJPNjZMSkw1S5KtYsxoCGRkuCygwMEIhiM/HkJKamx+emlScn5ydWlLMwAAAPtwhXA==";
const String channel = "demoWebsockets";

class SessionProvider extends ChangeNotifier {
  final UserRole role;

  SessionProvider({required this.role}) {
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
  bool isScreenSharing = false;
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
          remoteUid = uid;
          notifyListeners();
        },
        onUserOffline: (_, __, ___) {
          remoteUid = null;
          notifyListeners();
        },
        onError: (err, msg) => debugPrint('❌ Agora: $err – $msg'),
      ),
    );

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.enableVideo();
    await engine.startPreview();
    await engine.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
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

      debugPrint("Screen share started");
    } catch (e) {
      debugPrint("Screen Share Error: $e");
    }
  }

  Future<void> stopScreenShare() async {
    try {
      // Stop screen capture
      await engine.stopScreenCapture();

      // Switch back to camera
      await engine.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenTrack: false,
          publishCameraTrack: true,
        ),
      );

      isScreenSharing = false;

      notifyListeners();

      debugPrint("Screen sharing stopped");
    } catch (e) {
      debugPrint("Stop Share Error: $e");
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
