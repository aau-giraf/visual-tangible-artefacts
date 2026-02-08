import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../services/webrtc_service.dart';
import '../../services/video_call_manager.dart';
import '../../services/signalr_service.dart';
import 'remote_board_screen.dart';
import 'package:logging/logging.dart';


final _log = Logger('VideoCallScreen');
enum ConnectionStatus {
  initializing,
  calling,
  connecting,
  connected,
  error,
}

class VideoCallScreen extends StatefulWidget {
  static const String routeName = "/video-call";
  
  final HubConnection hubConnection;
  final String sessionId;
  final String myUserId;
  final String remoteUserId;
  final bool isCaller;
  final bool returnFromBoard;

  const VideoCallScreen({
    super.key,
    required this.hubConnection,
    required this.sessionId,
    required this.myUserId,
    required this.remoteUserId,
    required this.isCaller,
    this.returnFromBoard = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  WebRTCService? _webrtcService;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isMuted = false;
  bool _isCameraOff = false;
  ConnectionStatus _connectionStatus = ConnectionStatus.initializing;
  String? _errorMessage;
  bool _hasTransitioned = false;
  bool _showBoardButton = false;
  
  // Track media availability
  bool _hasLocalVideo = false;
  bool _hasLocalAudio = false;
  bool _hasRemoteVideo = false;
  bool _hasRemoteAudio = false;

  @override
  void initState() {
    super.initState();    
    // Listen for remote hang-up
    SignalRService().onSessionEnded = () {
      _log.fine('[VideoCall] Remote user ended the session');
      if (mounted) {
        VideoCallManager().endCall();
        
        // Caller (caregiver) goes to contacts list, callee (child) goes to their board
        if (widget.isCaller) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/remote',
            (route) => false,
          );
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/artifact-board',
            (route) => false,
          );
        }
      }
    };
    
    if (widget.returnFromBoard && VideoCallManager().isCallActive) {
      _restoreCallState();
    } else {
      _initializeCall();
    }
  }

  // Restore existing call state when returning from board
  Future<void> _restoreCallState() async {
    final videoManager = VideoCallManager();
    
    setState(() {
      _webrtcService = videoManager.webrtcService;
      _connectionStatus = ConnectionStatus.connected;
      _showBoardButton = true;
      
      // Restore media availability from WebRTC service
      if (_webrtcService != null) {
        _hasLocalVideo = _webrtcService!.hasLocalVideo;
        _hasLocalAudio = _webrtcService!.hasLocalAudio;
        _hasRemoteVideo = _webrtcService!.hasRemoteVideo;
        _hasRemoteAudio = _webrtcService!.hasRemoteAudio;
        _log.fine('[VideoCall] Restored media state: local(v:$_hasLocalVideo,a:$_hasLocalAudio) remote(v:$_hasRemoteVideo,a:$_hasRemoteAudio)');
      }
    });
    
    // Reattach renderers
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    
    _localRenderer.srcObject = videoManager.localRenderer?.srcObject;
    _remoteRenderer.srcObject = videoManager.remoteRenderer?.srcObject;
    
    setState(() {});
  }

  Future<void> _initializeCall() async {
    try {
      _log.fine('[VideoCall] Initializing call - isCaller: ${widget.isCaller}');
      
      // Initialize renderers
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      // Create WebRTC service
      _webrtcService = WebRTCService(
        hubConnection: widget.hubConnection,
        sessionId: widget.sessionId,
        myUserId: widget.myUserId,
        remoteUserId: widget.remoteUserId,
      );

      // Set up callbacks
      _webrtcService!.onLocalStream = (stream) {
        if (!mounted) return;
        setState(() {
          _localRenderer.srcObject = stream;
          _connectionStatus = widget.isCaller ? ConnectionStatus.calling : ConnectionStatus.connecting;
          // Update local media from actual stream
          _hasLocalVideo = stream.getVideoTracks().isNotEmpty;
          _hasLocalAudio = stream.getAudioTracks().isNotEmpty;
          _log.fine('[VideoCall] Local stream set: video=$_hasLocalVideo, audio=$_hasLocalAudio');
        });
      };

      _webrtcService!.onRemoteStream = (stream) {
        if (!mounted) return;
        setState(() {
          _remoteRenderer.srcObject = stream;
          _connectionStatus = ConnectionStatus.connected;
          // Update remote media from actual stream
          _hasRemoteVideo = stream.getVideoTracks().isNotEmpty;
          _hasRemoteAudio = stream.getAudioTracks().isNotEmpty;
          _log.fine('[VideoCall] Remote stream set: video=$_hasRemoteVideo, audio=$_hasRemoteAudio');
        });
        
        // Auto-transition to board screen after connection stabilizes
        _handleConnectionEstablished();
      };
      
      _webrtcService!.onConnectionEstablished = () {
        if (!mounted) return;
        _log.fine('[VideoCall] Connection established notification');
        setState(() {
          _connectionStatus = ConnectionStatus.connected;
        });
        _handleConnectionEstablished();
      };
      
      _webrtcService!.onLocalMediaAvailability = (hasVideo, hasAudio) {
        if (!mounted) return;
        // Only update if stream hasn't been set yet
        if (_localRenderer.srcObject == null) {
          setState(() {
            _hasLocalVideo = hasVideo;
            _hasLocalAudio = hasAudio;
            _log.fine('[VideoCall] Local media availability (no stream yet): video=$hasVideo, audio=$hasAudio');
          });
        }
      };
      
      _webrtcService!.onRemoteMediaAvailability = (hasVideo, hasAudio) {
        if (!mounted) return;
        // Only update if stream hasn't been set yet
        if (_remoteRenderer.srcObject == null) {
          setState(() {
            _hasRemoteVideo = hasVideo;
            _hasRemoteAudio = hasAudio;
            _log.fine('[VideoCall] Remote media availability (no stream yet): video=$hasVideo, audio=$hasAudio');
          });
        }
      };

      _webrtcService!.onError = (error) {
        if (!mounted) return;
        setState(() {
          _connectionStatus = ConnectionStatus.error;
          _errorMessage = error;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      };

      await _webrtcService!.initialize();

      await Future.delayed(Duration(milliseconds: 500));

      // Start the call
      if (widget.isCaller) {
        _log.fine('[VideoCall] Starting call as caller');
        await _webrtcService!.startCall();
      } else {
        _log.fine('[VideoCall] Waiting for offer as callee');
      }
    } catch (e) {
      _log.fine('[VideoCall] Initialization error: $e');
      if (!mounted) return;
      setState(() {
        _connectionStatus = ConnectionStatus.error;
        _errorMessage = 'Kunne ikke initialisere: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke initialisere opkald: $e')),
        );
      }
    }
  }

  Future<void> _handleConnectionEstablished() async {
    if (_hasTransitioned) return;
    
    if (mounted) {
      setState(() {
        _showBoardButton = true;
      });
    }
    
    await Future.delayed(Duration(seconds: 2));
    
    if (!mounted || _hasTransitioned || !_showBoardButton) return;
    
    _hasTransitioned = true;
    
    // Store video call state
    await VideoCallManager().initializeCall(
      webrtcService: _webrtcService!,
      localRenderer: _localRenderer,
      remoteRenderer: _remoteRenderer,
      sessionId: widget.sessionId,
    );
    
    // Navigate
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      RemoteBoardScreen.routeName,
      arguments: {
        'sessionId': widget.sessionId,
        'boardId': SignalRService.defaultBoardId,
        'hasVideo': true,
      },
    );
  }

  void _goToBoardScreen() {
    if (_connectionStatus != ConnectionStatus.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vent venligst på forbindelsen etableres')),
      );
      return;
    }
    
    _hasTransitioned = true;
    
    // Store video call state
    VideoCallManager().initializeCall(
      webrtcService: _webrtcService!,
      localRenderer: _localRenderer,
      remoteRenderer: _remoteRenderer,
      sessionId: widget.sessionId,
    );
    
    // Navigate
    Navigator.of(context).pushReplacementNamed(
      RemoteBoardScreen.routeName,
      arguments: {
        'sessionId': widget.sessionId,
        'boardId': SignalRService.defaultBoardId,
        'hasVideo': true,
      },
    );
  }

  String _getStatusText() {
    switch (_connectionStatus) {
      case ConnectionStatus.initializing:
        return 'Initialiserer...';
      case ConnectionStatus.calling:
        return 'Ringer...';
      case ConnectionStatus.connecting:
        return 'Forbinder...';
      case ConnectionStatus.connected:
        return 'Forbundet';
      case ConnectionStatus.error:
        return _errorMessage != null ? 'Fejl: $_errorMessage' : 'Fejl';
    }
  }

  @override
  void dispose() {
    _log.fine('[VideoCall] Disposing - hasTransitioned: $_hasTransitioned, mounted: $mounted');
        
    if (!_hasTransitioned) {
      _log.fine('[VideoCall] Disposing WebRTC resources');
      _webrtcService?.dispose();
      _localRenderer.dispose();
      _remoteRenderer.dispose();
      VideoCallManager().endCall();
    } else {
      _log.fine('[VideoCall] NOT disposing - transitioning to board');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            _remoteRenderer.srcObject != null && _hasRemoteVideo
                ? Stack(
                    children: [
                      RTCVideoView(
                        _remoteRenderer,
                        mirror: false,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      ),
                      // Audio muted indicator
                      if (!_hasRemoteAudio)
                        Positioned(
                          top: 80,
                          left: 20,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic_off, color: Colors.white, size: 20),
                                SizedBox(width: 4),
                                Text('Ingen lyd', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: (_remoteRenderer.srcObject != null && !_hasRemoteVideo) || 
                           (_connectionStatus == ConnectionStatus.connected && !_hasRemoteVideo)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Kamera utilgængeligt',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              if (!_hasRemoteAudio)
                                Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.mic_off, color: Colors.red, size: 20),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ingen lyd',
                                        style: TextStyle(color: Colors.red, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 20),
                              Text(
                                _getStatusText(),
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
                          ),
                  ),

            // Local video (small preview in corner)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 150,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Video or placeholder
                      _localRenderer.srcObject != null && _hasLocalVideo
                          ? RTCVideoView(
                              _localRenderer,
                              mirror: true,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                      // Audio muted indicator
                      if (!_hasLocalAudio)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.mic_off, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ingen mikrofon',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: _hasLocalAudio
                        ? () {
                            _webrtcService?.toggleMute();
                            setState(() => _isMuted = !_isMuted);
                          }
                        : null,
                    backgroundColor: !_hasLocalAudio
                        ? Colors.grey
                        : (_isMuted ? Colors.red : Colors.white),
                  ),

                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: () async {
                      _log.fine('[VideoCall] Hang-up button pressed');
                      await SignalRService().endSession();
                      await VideoCallManager().endCall();
                      if (mounted) {
                        // Caller (caregiver) goes to contacts list, callee (child) goes to their board
                        if (widget.isCaller) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/remote',
                            (route) => false,
                          );
                        } else {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/artifact-board',
                            (route) => false,
                          );
                        }
                      }
                    },
                    backgroundColor: Colors. red,
                    size: 70,
                  ),

                  // Camera toggle button
                  _buildControlButton(
                    icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                    onPressed: _hasLocalVideo
                        ? () {
                            _webrtcService?.toggleCamera();
                            setState(() => _isCameraOff = !_isCameraOff);
                          }
                        : null,
                    backgroundColor: !_hasLocalVideo
                        ? Colors.grey
                        : (_isCameraOff ? Colors.red : Colors.white),
                  ),
                ],
              ),
            ),

            // Go to board button
            if (_showBoardButton && !_hasTransitioned)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _goToBoardScreen,
                    icon: Icon(Icons.dashboard),
                    label: Text('Til Brættet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),

            // Status indicator
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color backgroundColor = Colors.white,
    double size = 60,
  }) {
    final isDisabled = onPressed == null;
    
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Icon(
          icon,
          color: isDisabled
              ? Colors.white54
              : (backgroundColor == Colors.white ? Colors.black : Colors.white),
          size: size * 0.5,
        ),
      ),
    );
  }
}