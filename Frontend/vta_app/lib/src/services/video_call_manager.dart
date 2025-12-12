import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:vta_app/src/services/webrtc_service.dart';

//Service to manage video call state across screens
class VideoCallManager {
  static final VideoCallManager _instance = VideoCallManager._internal();
  factory VideoCallManager() => _instance;
  VideoCallManager._internal();

  WebRTCService? _webrtcService;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  String? _currentSessionId;
  bool _isCallActive = false;

  bool get isCallActive => _isCallActive;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;
  WebRTCService? get webrtcService => _webrtcService;
  String? get currentSessionId => _currentSessionId;

  // Initialize a new call
  Future<void> initializeCall({
    required WebRTCService webrtcService,
    required RTCVideoRenderer localRenderer,
    required RTCVideoRenderer remoteRenderer,
    required String sessionId,
  }) async {
    _webrtcService = webrtcService;
    _localRenderer = localRenderer;
    _remoteRenderer = remoteRenderer;
    _currentSessionId = sessionId;
    _isCallActive = true;
  }

  // End the current call and dispose resources
  Future<void> endCall() async {
    _webrtcService?.dispose();
    await _localRenderer?.dispose();
    await _remoteRenderer?.dispose();
    
    _webrtcService = null;
    _localRenderer = null;
    _remoteRenderer = null;
    _currentSessionId = null;
    _isCallActive = false;
  }

  void detachRenderers() {
  }
}
