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

  final WebviewController webviewController = WebviewController();
  bool _browserReady = false;

  bool isSharing = false;
  bool showBrowser = false;
  bool isInitializing = false;
  String? error;

  List<ScreenCaptureSourceInfo> _windows = [];

  Future<void> init() async {
    await _initBrowser();
    await _ensureEngine();
  }

  Future<void> _initBrowser() async {
    try {
      await webviewController.initialize();
      await webviewController.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await webviewController.loadUrl('about:blank');
      _browserReady = true;
    } catch (e) {
      debugPrint('Browser init failed: $e');
    }
  }

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
    debugPrint('ScreenShareProvider joined channel=$channelName uid=$kScreenShareUid');
  }

  Future<void> _loadWindows() async {
    final result = await _engine!.getScreenCaptureSources(
      thumbSize: const SIZE(width: 320, height: 180),
      iconSize: const SIZE(width: 64, height: 64),
      includeScreen: true,
    );
    _windows = result;

    debugPrint('=== ALL WINDOWS ===');
    for (final w in _windows) {
      debugPrint('name=${w.sourceName} | id=${w.sourceId} | type=${w.type}');
    }
    debugPrint('=== END WINDOWS ===');
  }

  // ── FIX: accept mainEngine, suspend cam BEFORE share starts ──
  Future<void> _startWindowShare(ScreenCaptureSourceInfo source, {RtcEngine? mainEngine}) async {
    // Suspend main engine cam first to avoid pipeline conflict
    try {
      if (mainEngine != null) {
        await mainEngine.muteLocalVideoStream(true);
        await mainEngine.enableLocalVideo(false);
        await mainEngine.updateChannelMediaOptions(
          const ChannelMediaOptions(
            publishCameraTrack: false,
            publishMicrophoneTrack: false,
          ),
        );
        debugPrint('Main engine cam suspended before share');
      }
    } catch (e) {
      debugPrint('Main engine suspend error: $e');
    }

    await _engine!.startScreenCaptureByWindowId(
      windowId: source.sourceId!,
      regionRect: const Rectangle(x: 0, y: 0, width: 0, height: 0),
      captureParams: const ScreenCaptureParameters(
        frameRate: 15,
        bitrate: 0,
        captureMouseCursor: true,
        windowFocus: true,
      ),
    );
    await _engine!.adjustLoopbackSignalVolume(100);
    await _engine!.enableLoopbackRecording(enabled: true);
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

  // ── FIX: pass mainEngine through to _startWindowShare ──
  Future<void> openBrowserAndShare({RtcEngine? mainEngine}) async {
    if (isInitializing) return;
    isInitializing = true;
    error = null;
    notifyListeners();

    try {
      await _ensureEngine();
      if (!_browserReady) await _initBrowser();

      await webviewController.loadUrl('https://www.google.com');
      showBrowser = true;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));
      await _loadWindows();

      try {
        final browserWindow = _windows.firstWhere((e) {
          final name = e.sourceName?.toLowerCase() ?? '';
          return name.contains('floreo') ||
              name.contains('chrome') ||
              name.contains('google') ||
              name.contains('edge') ||
              name.contains('firefox') ||
              name.contains('msedge');
        });
        debugPrint('Sharing window: ${browserWindow.sourceName}');
        await _startWindowShare(browserWindow, mainEngine: mainEngine); // ← pass mainEngine
      } catch (e) {
        debugPrint('Window not found: $e');
        error = 'Browser window not found. Please open browser first.';
      }
    } catch (e) {
      error = 'Screen share failed: $e';
      debugPrint(error);
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }
 Future<void> stopShare({RtcEngine? mainEngine}) async {
    if (!isSharing) return;

    try {
      await _engine?.enableLoopbackRecording(enabled: false);
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
      // REMOVED: release() — caused async thread to hold Windows cam lock
      _engine = null;
    } catch (e) {
      debugPrint('stopShare error: $e');
    }

    isSharing = false;
    showBrowser = false;

    await Future.delayed(const Duration(milliseconds: 200));

    try {
      if (mainEngine != null) {
        await mainEngine.stopPreview();
        await mainEngine.enableLocalVideo(true);
        await mainEngine.enableVideo();
        await mainEngine.startPreview();
        await mainEngine.muteLocalVideoStream(false);
        await mainEngine.updateChannelMediaOptions(
          const ChannelMediaOptions(
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
          ),
        );
        debugPrint('Main engine cam fully restored');
      }
    } catch (e) {
      debugPrint('Main engine restart error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 300));

    notifyListeners();

    try {
      await webviewController.loadUrl('about:blank');
    } catch (e) {
      debugPrint('Failed to reset webview: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (isSharing) await stopShare();
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    webviewController.dispose();
    super.dispose();
  }
}
