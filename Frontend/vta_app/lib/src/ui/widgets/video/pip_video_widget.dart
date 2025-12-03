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
            child: widget.remoteRenderer.srcObject != null
                ? Stack(
                    children: [
                      RTCVideoView(
                        widget.remoteRenderer,
                        mirror: false,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
                  )
                : Container(
                    color: Colors.grey[800],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
