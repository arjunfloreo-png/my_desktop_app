import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _i = SocketService._internal();
  factory SocketService() => _i;
  SocketService._internal();

  IO.Socket? _socket;
  static const _url = 'https://floreo-server.onrender.com';
  // Callbacks — set these before connect()
  Function(Map<String, dynamic>)? onSessionJoined;
  Function(Map<String, dynamic>)? onPeerConnected;
  Function(Map<String, dynamic>)? onPeerDisconnected;
  Function(Map<String, dynamic>)? onVideoSelect;
  Function(Map<String, dynamic>)? onVideoPlay;
  Function(Map<String, dynamic>)? onVideoPause;
  Function(Map<String, dynamic>)? onVideoSeek;
  Function(Map<String, dynamic>)? onVideoVolume;
  Function(Map<String, dynamic>)? onButtonAction;
  Function(Map<String, dynamic>)? onSyncResponse;
  Function(Map<String, dynamic>)? onError;

  void connect() {
    _socket = IO.io(_url,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(5)
        .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_)      => print('[WS] connected'));
    _socket!.onDisconnect((_)   => print('[WS] disconnected'));
    _socket!.onConnectError((e) => print('[WS] error: $e'));

    _socket!.on('session_joined',    (d) => onSessionJoined?.call(_m(d)));
    _socket!.on('peer_connected',    (d) => onPeerConnected?.call(_m(d)));
    _socket!.on('peer_disconnected', (d) => onPeerDisconnected?.call(_m(d)));
    _socket!.on('video_select',      (d) => onVideoSelect?.call(_m(d)));
    _socket!.on('video_play',        (d) => onVideoPlay?.call(_m(d)));
    _socket!.on('video_pause',       (d) => onVideoPause?.call(_m(d)));
    _socket!.on('video_seek',        (d) => onVideoSeek?.call(_m(d)));
    _socket!.on('video_volume',      (d) => onVideoVolume?.call(_m(d)));
    _socket!.on('button_action',     (d) => onButtonAction?.call(_m(d)));
    _socket!.on('sync_response',     (d) => onSyncResponse?.call(_m(d)));
    _socket!.on('error',             (d) => onError?.call(_m(d)));
  }

  Map<String, dynamic> _m(dynamic d) => Map<String, dynamic>.from(d);

  void disconnect() {
    _socket?.disconnect();
    _socket?.destroy();
  }

  bool get isConnected => _socket?.connected ?? false;

  // ── Emits ──────────────────────────────────────────────
  void joinSession(String sessionId, String role) =>
      _socket?.emit('join_session', {'sessionId': sessionId, 'role': role});

  void selectVideo(String videoId, String videoUrl, {String? title, String? category}) =>
      _socket?.emit('video_select', {
        'videoId': videoId,
        'videoUrl': videoUrl,
        if (title != null) 'title': title,
        if (category != null) 'category': category,
      });

  void playVideo(double currentTime) =>
      _socket?.emit('video_play', {'currentTime': currentTime});

  void pauseVideo(double currentTime) =>
      _socket?.emit('video_pause', {'currentTime': currentTime});

  void seekVideo(double currentTime) =>
      _socket?.emit('video_seek', {'currentTime': currentTime});

  void setVolume(double volume) =>
      _socket?.emit('video_volume', {'volume': volume});

  void buttonAction(String action, {Map? meta}) =>
      _socket?.emit('button_action', {
        'action': action,
        if (meta != null) 'meta': meta,
      });

  void syncRequest() => _socket?.emit('sync_request');

  // WebRTC
  void sendOffer(dynamic sdp)      => _socket?.emit('webrtc_offer', {'sdp': sdp});
  void sendAnswer(dynamic sdp)     => _socket?.emit('webrtc_answer', {'sdp': sdp});
  void sendIce(dynamic candidate)  => _socket?.emit('webrtc_ice_candidate', {'candidate': candidate});
}