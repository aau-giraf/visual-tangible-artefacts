import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../services/webrtc_service.dart';
import '../../services/video_call_manager.dart';
import '../../services/signalr_service.dart';
import 'remote_board_screen.dart';

class VideoCallScreen extends StatefulWidget {
  static const String routeName = "/video-call";
  
  final HubConnection hubConnection;
  final String sessionId;
  final String myUserId;
  final String remoteUserId;
  final bool isCaller;
  final bool returnFromBoard;

  const VideoCallScreen({
    Key? key,
    required this.hubConnection,
    required this.sessionId,
    required this.myUserId,
    required this.remoteUserId,
    required this.isCaller,
    this.returnFromBoard = false,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  WebRTCService? _webrtcService;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isMuted = false;
  bool _isCameraOff = false;
  String _status = 'Initializing...';
  bool _hasTransitioned = false;
  bool _showBoardButton = false;

  @override
  void initState() {
    super.initState();
    // Lock to landscape orientation for video calls
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
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
      _status = 'Connected';
      _showBoardButton = true;
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
      debugPrint('[VideoCall] Initializing call - isCaller: ${widget.isCaller}');
      
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
          _status = widget.isCaller ? 'Calling...' : 'Connecting...';
        });
      };

      _webrtcService!.onRemoteStream = (stream) {
        if (!mounted) return;
        setState(() {
          _remoteRenderer.srcObject = stream;
          _status = 'Connected';
        });
        
        // Auto-transition to board screen after connection stabilizes
        _handleConnectionEstablished();
      };

      _webrtcService!.onError = (error) {
        if (!mounted) return;
        setState(() {
          _status = 'Error: $error';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      };

      // Initialize WebRTC
      await _webrtcService!.initialize();

      await Future.delayed(Duration(milliseconds: 500));

      // Start the call
      if (widget.isCaller) {
        debugPrint('[VideoCall] Starting call as caller');
        await _webrtcService!.startCall();
      } else {
        debugPrint('[VideoCall] Waiting for offer as callee');
      }
    } catch (e) {
      debugPrint('[VideoCall] Initialization error: $e');
      if (!mounted) return;
      setState(() {
        _status = 'Failed to initialize: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize call: $e')),
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
    if (_status != 'Connected') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please wait for connection to establish')),
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

  @override
  void dispose() {
    debugPrint('[VideoCall] Disposing - hasTransitioned: $_hasTransitioned, mounted: $mounted');
    
    // Restore all orientations when leaving call
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    if (!_hasTransitioned) {
      debugPrint('[VideoCall] Disposing WebRTC resources');
      _webrtcService?.dispose();
      _localRenderer.dispose();
      _remoteRenderer.dispose();
      VideoCallManager().endCall();
    } else {
      debugPrint('[VideoCall] NOT disposing - transitioning to board');
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
            _remoteRenderer.srcObject != null
                ? RTCVideoView(
                    _remoteRenderer,
                    mirror: false,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          _status,
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
                  child: _localRenderer.srcObject != null
                      ? RTCVideoView(
                          _localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Container(color: Colors.grey[800]),
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
                    onPressed: () {
                      _webrtcService?.toggleMute();
                      setState(() => _isMuted = !_isMuted);
                    },
                    backgroundColor: _isMuted ? Colors. red : Colors.white,
                  ),

                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: () async {
                      await VideoCallManager().endCall();
                      if (mounted) Navigator.pop(context);
                    },
                    backgroundColor: Colors. red,
                    size: 70,
                  ),

                  // Camera toggle button
                  _buildControlButton(
                    icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                    onPressed: () {
                      _webrtcService?.toggleCamera();
                      setState(() => _isCameraOff = !_isCameraOff);
                    },
                    backgroundColor: _isCameraOff ? Colors.red : Colors.white,
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
                    label: Text('Go to Board'),
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
                  _status,
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
    required VoidCallback onPressed,
    Color backgroundColor = Colors.white,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: backgroundColor == Colors.white ? Colors.black : Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}