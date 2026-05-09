import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user_role.dart';

const String appId = "54bf8a5095374303aa14ff23c73bac0d";
const String token =
    "007eJxTYLgUPuPkjnUpu56/31eYKPx0mnUOp25kavM/v7LcHoemq7EKDKYmSWkWiaYGlqbG5ibGBsaJiYYmaWlGxsnmxkmJyQYpMw79zWwIZGS4laHAzMgAgSA+L0NKam5+eGpScX5ydmoJAwMAFj4k5g==";
const String channel = "demoWebsocket";

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
