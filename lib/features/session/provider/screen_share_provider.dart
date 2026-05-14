import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

const _kAppId = '9bbcfb22bb73429fa08643c4da2fcc0b';
const _kToken =
    '007eJxTYPgYNU/O/aqZUQIrj2S2xZYtZqwrJqx1aZH5+S/LUXB3T5gCg6lJUppFoqmBpamxuYmxgXFioqFJWpqRcbK5cVJiskHK8lLWrIZARoZkniQWRgYIBPG5GUoyUosKMotLHAsKGBgAQ0AfDA==';
const _kChannel = 'therpistApp';

class ScreenShareProvider extends ChangeNotifier {
  RtcEngine? _engine;

  bool isSharing = false;
  bool isInitializing = false;
  String? error;

  // ── INIT ENGINE ──────────────────────────────
  Future<void> _ensureEngine() async {
    if (_engine != null) return;

    _engine = createAgoraRtcEngine();

    await _engine!.initialize(
      const RtcEngineContext(
        appId: _kAppId,
        channelProfile:
            ChannelProfileType.channelProfileCommunication,
      ),
    );

    await _engine!.enableVideo();

    await _engine!.joinChannel(
      token: _kToken,
      channelId: _kChannel,
      uid: 1, // uid:1 avoids conflict with SessionProvider (uid:0)
      options: const ChannelMediaOptions(
        publishScreenCaptureVideo: false,
        publishScreenCaptureAudio: false,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
      ),
    );
  }

  // ── START SHARE ──────────────────────────────
  Future<void> startShare() async {
    if (isSharing || isInitializing) return;

    isInitializing = true;
    error = null;
    notifyListeners();

    try {
      await _ensureEngine();

      // Enumerate all screens & windows
      final sources = await _engine!.getScreenCaptureSources(
        thumbSize: const SIZE(width: 320, height: 180),
        iconSize: const SIZE(width: 64, height: 64),
        includeScreen: true,
      );

      if (sources.isEmpty) throw Exception('No screen sources found');

      // Prefer a monitor/screen over a window
      final screen = sources.firstWhere(
        (s) =>
            s.type ==
            ScreenCaptureSourceType.screencapturesourcetypeScreen,
        orElse: () => sources.first,
      );

      await _engine!.startScreenCaptureByWindowId(
        windowId: screen.sourceId!,
        regionRect: const Rectangle(
          x: 0,
          y: 0,
          width: 0,
          height: 0,
        ),
        captureParams: const ScreenCaptureParameters(
          frameRate: 15,
          bitrate: 0,
          captureMouseCursor: true,
          windowFocus: true,
        ),
      );

      // Publish the screen track
      await _engine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenCaptureVideo: true,
          publishScreenCaptureAudio: true,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
        ),
      );

      isSharing = true;
    } catch (e) {
      error = 'Screen share failed: $e';
      debugPrint(error);
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  // ── STOP SHARE ───────────────────────────────
  Future<void> stopShare() async {
    if (!isSharing) return;

    try {
      await _engine?.stopScreenCapture();

      await _engine?.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
        ),
      );
    } catch (e) {
      debugPrint('stopShare error: $e');
    }

    isSharing = false;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await stopShare();
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    super.dispose();
  }
}
