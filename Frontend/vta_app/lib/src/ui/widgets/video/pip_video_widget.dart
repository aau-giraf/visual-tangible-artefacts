import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Picture-in-Picture video widget showing remote feed in a corner
class PipVideoWidget extends StatefulWidget {
  final RTCVideoRenderer remoteRenderer;
  final VoidCallback onTap;

  const PipVideoWidget({
    Key? key,
    required this.remoteRenderer,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PipVideoWidget> createState() => _PipVideoWidgetState();
}

class _PipVideoWidgetState extends State<PipVideoWidget> {
  Offset _position = Offset(20, 20); // Default top-right position
  
  Widget _buildVideoOrPlaceholder() {
    final stream = widget.remoteRenderer.srcObject;
    final hasVideo = stream?.getVideoTracks().isNotEmpty ?? false;
    final hasAudio = stream?.getAudioTracks().isNotEmpty ?? false;
    
    if (stream == null) {
      return _buildPlaceholder(hasAudio);
    }
    
    if (hasVideo) {
      // Show actual video with controls
      return Stack(
        children: [
          RTCVideoView(
            widget.remoteRenderer,
            mirror: false,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          // No audio indicator in top-left corner
          if (!hasAudio)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic_off,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Ingen lyd',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Small tap hint icon in bottom-right corner
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          // Drag handle indicator at top center
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Show placeholder for audio-only
      return _buildPlaceholder(hasAudio);
    }
  }
  
  Widget _buildPlaceholder(bool hasAudio) {
    return Stack(
      children: [
        Container(
          color: Colors.grey[800],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white70,
                ),
                // Show "No audio" indicator if no audio either
                if (!hasAudio)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_off,
                          color: Colors.red,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Ingen lyd',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Small tap hint icon in bottom-right corner
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.fullscreen,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        // Drag handle indicator at top
        Positioned(
          top: 4,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const videoWidth = 150.0;
    const videoHeight = 200.0;
    
    // Ensure position stays within screen bounds
    _position = Offset(
      _position.dx.clamp(0, screenSize.width - videoWidth),
      _position.dy.clamp(0, screenSize.height - videoHeight),
    );

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        child: Container(
          width: 150,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: _buildVideoOrPlaceholder(),
          ),
        ),
      ),
    );
  }
}
