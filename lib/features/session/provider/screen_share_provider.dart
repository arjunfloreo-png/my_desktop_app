import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_windows/webview_windows.dart';

import '../provider/session_provider.dart';

const _kAppId = '54bf8a5095374303aa14ff23c73bac0d';

class ScreenShareProvider extends ChangeNotifier {
  final String token;
  final String channelName;

  ScreenShareProvider({
    required this.token,
    required this.channelName,
  });

  RtcEngine? _engine;

  // ── WebView ───────────────────────────────────
  final WebviewController webviewController = WebviewController();
  bool _browserReady = false;

  bool isSharing = false;
  bool showBrowser = false;
  bool isInitializing = false;
  String? error;

  List<ScreenCaptureSourceInfo> _windows = [];

  // ── INIT ─────────────────────────────────────
  Future<void> init() async {
    await _initBrowser();
    await _ensureEngine();
  }

  // ── INIT BROWSER ─────────────────────────────
  Future<void> _initBrowser() async {
    try {
      await webviewController.initialize();

      await webviewController.setPopupWindowPolicy(
        WebviewPopupWindowPolicy.deny,
      );

      await webviewController.loadUrl('about:blank');

      _browserReady = true;
    } catch (e) {
      debugPrint('Browser init failed: $e');
    }
  }

  // ── INIT ENGINE ──────────────────────────────
  Future<void> _ensureEngine() async {
    if (_engine != null) return;

    _engine = createAgoraRtcEngine();

    await _engine!.initialize(
      const RtcEngineContext(
        appId: _kAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    await _engine!.enableVideo();
    await _engine!.enableAudio();

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: kScreenShareUid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
        publishScreenTrack: false,
        publishScreenCaptureAudio: true,
      ),
    );

    debugPrint(
      'ScreenShareProvider joined channel=$channelName uid=$kScreenShareUid',
    );
  }

  // ── LOAD WINDOWS ─────────────────────────────
  Future<void> _loadWindows() async {
    final result = await _engine!.getScreenCaptureSources(
      thumbSize: const SIZE(width: 320, height: 180),
      iconSize: const SIZE(width: 64, height: 64),
      includeScreen: false,
    );

    _windows = result;
  }

  // ── START WINDOW SHARE ───────────────────────
  Future<void> _startWindowShare(
    ScreenCaptureSourceInfo source,
  ) async {
    await _engine!.startScreenCaptureByWindowId(
      windowId: source.sourceId!,
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

    await _engine!.adjustLoopbackSignalVolume(100);

    await _engine!.enableLoopbackRecording(
      enabled: true,
    );

    await _engine!.updateChannelMediaOptions(
      const ChannelMediaOptions(
        publishScreenTrack: true,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
        publishScreenCaptureAudio: true,
      ),
    );

    isSharing = true;

    notifyListeners();
  }

  // ── OPEN BROWSER & SHARE ─────────────────────
  Future<void> openBrowserAndShare() async {
    if (isInitializing) return;

    isInitializing = true;
    error = null;

    notifyListeners();

    try {
      await _ensureEngine();

      if (!_browserReady) {
        await _initBrowser();
      }

      await webviewController.loadUrl(
        'https://www.google.com',
      );

      showBrowser = true;

      notifyListeners();

      await Future.delayed(
        const Duration(seconds: 2),
      );

      await _loadWindows();

      try {
        final browserWindow = _windows.firstWhere(
          (e) {
            final name =
                e.sourceName?.toLowerCase() ?? '';

            return name.contains('chrome') ||
                name.contains('google') ||
                name.contains('edge') ||
                name.contains('firefox');
          },
        );

        await _startWindowShare(browserWindow);
      } catch (e) {
        debugPrint('Browser window not found: $e');

        error =
            'Browser window not found. Please open browser first.';
      }
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
      await _engine?.enableLoopbackRecording(
        enabled: false,
      );

      await _engine?.stopScreenCapture();

      await _engine?.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenTrack: false,
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
        ),
      );

      await _engine?.leaveChannel();

      await _engine?.release();

      _engine = null;
    } catch (e) {
      debugPrint('stopShare error: $e');
    }

    isSharing = false;
    showBrowser = false;

    notifyListeners();

    try {
      await webviewController.loadUrl('about:blank');
    } catch (e) {
      debugPrint('Failed to reset webview: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (isSharing) {
      await stopShare();
    }

    await _engine?.leaveChannel();

    await _engine?.release();

    _engine = null;

    webviewController.dispose();

    super.dispose();
  }
}