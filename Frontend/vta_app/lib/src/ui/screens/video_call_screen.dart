import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../services/webrtc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final HubConnection hubConnection;
  final String sessionId;
  final String myUserId;
  final String remoteUserId;
  final bool isCaller;

  const VideoCallScreen({
    Key? key,
    required this.hubConnection,
    required this.sessionId,
    required this.myUserId,
    required this.remoteUserId,
    required this.isCaller,
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

  @override
  void initState() {
    super.initState();
    // Lock to landscape orientation for video calls
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
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
        setState(() {
          _localRenderer.srcObject = stream;
          _status = widget.isCaller ? 'Calling...' : 'Connecting...';
        });
      };

      _webrtcService!.onRemoteStream = (stream) {
        setState(() {
          _remoteRenderer.srcObject = stream;
          _status = 'Connected';
        });
      };

      _webrtcService!.onError = (error) {
        setState(() {
          _status = 'Error: $error';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      };

      // Initialize WebRTC
      await _webrtcService!.initialize();

      // Small delay to ensure everything is ready
      await Future.delayed(Duration(milliseconds: 500));

      // If this user is the caller, start the call
      if (widget.isCaller) {
        await _webrtcService!.startCall();
      }
    } catch (e) {
      print('[VideoCall] Initialization error: $e');
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

  @override
  void dispose() {
    // Restore all orientations when leaving call
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _webrtcService?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
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
                    onPressed: () {
                      Navigator.pop(context);
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