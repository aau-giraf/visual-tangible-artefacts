import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/option_wheel.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/controllers/talkingmat_controller.dart';

class LongPressOptionWheel extends StatefulWidget {
  final BoardArtefact artifact;
  final Widget child;
  final TalkingmatController controller;

  const LongPressOptionWheel({
    super.key,
    required this.artifact,
    required this.child,
    required this.controller,
  });

  @override
  State<LongPressOptionWheel> createState() => LongPressOptionWheelState();
}

class LongPressOptionWheelState extends State<LongPressOptionWheel> {
  OverlayEntry? _overlayEntry;
  Offset? _artifactCenterGlobal;
  Size? _wheelSize;
  final GlobalKey _optionWheelKey = GlobalKey();
  bool _showName = false;
  bool _isScalingMode = false;
  double _initialScale = 1.0;
  Offset? _dragStart;

  // Public getter for scaling mode
  bool get isScalingMode => _isScalingMode;

  // finding artifact center and showing wheel
  void _onLongPressStart(LongPressStartDetails details) {
    if (!_isScalingMode) {
      _showPersistentWheel();
    }
  }

  // Helper method to wrap content with scaling indicator
  Widget wrapWithScalingIndicator(Widget content) {
    if (!_isScalingMode) {
      return content;
    }
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        content,
        Positioned(
          right: -5,
          bottom: -5,
          child: GestureDetector(
            onTap: () {
              // Exit scaling mode when blue handle is clicked
              setState(() {
                _isScalingMode = false;
              });
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.zoom_out_map,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The main gesture detector wrapping the child
        GestureDetector(
          onLongPressStart: _onLongPressStart,
          // Allow tapping to exit scaling mode
          onTap: () {
            if (_isScalingMode) {
              setState(() {
                _isScalingMode = false;
              });
            }
          },
          // Enable pan gestures for scaling when in scaling mode
          onPanStart: _isScalingMode ? (details) {
            setState(() {
              _initialScale = widget.artifact.scale;
              _dragStart = details.globalPosition;
            });
          } : null,
          onPanUpdate: _isScalingMode ? (details) {
            if (_dragStart != null) {
              // Calculate drag direction for scaling
              final dragDirection = details.globalPosition - _dragStart!;
              
              // Scale based on diagonal drag (positive = larger, negative = smaller)
              final scaleDelta = (dragDirection.dx + dragDirection.dy) / 200;
              // Limit scale to reasonable range: 0.5x to 2.0x
              final newScale = (_initialScale + scaleDelta).clamp(0.5, 2.0);
              
              widget.controller.updateArtifactScale(widget.artifact, newScale);
            }
          } : null,
          onPanEnd: _isScalingMode ? (details) {
            _dragStart = null;
          } : null,
          // Wrap child in AbsorbPointer when scaling to prevent Draggable from intercepting
          child: AbsorbPointer(
            absorbing: _isScalingMode,
            child: widget.child,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: AnimatedOpacity(
            opacity: _showName ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              alignment: Alignment.topCenter,
              // Move name up based on image height if available, else default higher
              margin: EdgeInsets.only(top: _getNameTopMargin()),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Text(
                widget.artifact.baseArtefact?.name ?? '',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getNameTopMargin() {
    // TODO: Doesnt work for now, should change height depending on image size, when wheel also scales correctly on image size
    final imageHeight = widget.artifact.baseArtefact?.image?.lengthInBytes ?? 0;
    if (imageHeight > 0) {
      return 100;
    }
    return 0;
  }

  void _showPersistentWheel() {
    final artifactContext = widget.artifact.key.currentContext;
    if (artifactContext == null) return;

    final RenderBox artifactBox = artifactContext.findRenderObject() as RenderBox;
    _artifactCenterGlobal = artifactBox.localToGlobal(artifactBox.size.center(Offset.zero));

    // create overlay
    _overlayEntry = OverlayEntry(builder: (context) {

      // fallback sizes (if this happens... fix it)
      final double fallbackWidth = (150 + 90 / 2 + 30) * 2;
      final Size ws = _wheelSize ?? Size(fallbackWidth, fallbackWidth);
  final double left = _artifactCenterGlobal!.dx - ws.width / 2;
  final double top = _artifactCenterGlobal!.dy - ws.height / 2;

      // decides orientation for overflow
      final media = MediaQuery.of(context).size;
      final double candidateLeft = _artifactCenterGlobal!.dx - ws.width / 2;
      final double candidateTop = _artifactCenterGlobal!.dy - ws.height / 2;

  final bool overflowLeft = candidateLeft < -50;
  final bool overflowRight = candidateLeft + ws.width > media.width;
  final bool overflowTop = candidateTop < -80;
  final bool overflowBottom = candidateTop + ws.height > media.height;
      // Default
      double centerAngleDeg = 0;

      // board edge overflow
      if (overflowLeft && overflowTop) {
        centerAngleDeg = 135; // top-left board edge
      } else if (overflowRight && overflowTop) {
        centerAngleDeg = -135; // top-right board edge
      } else if (overflowLeft && overflowBottom) {
        centerAngleDeg = 45; // bottom-left board edge
      } else if (overflowRight && overflowBottom) {
        centerAngleDeg = -45; // bottom-right board edge
      } else if (overflowLeft) {
        centerAngleDeg = 90; // right board edge
      } else if (overflowRight) {
        centerAngleDeg = -90; // left board edge
      } else if (overflowTop) {
        centerAngleDeg = 180; // bottom board edge
      }

      // uses a semicircle and adjust by the angledeg based on border overflow
      final double arcHalf = 90.0;
      final double startDegrees = centerAngleDeg - arcHalf;
      final double endDegrees = centerAngleDeg + arcHalf;

      return Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hidePersistentWheel,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: left,
          top: top - 40,
          child: Material(
            color: Colors.transparent,
            child: OptionWheel(
              key: _optionWheelKey,
              artefact: widget.artifact.baseArtefact!,
              showName: _showName,
              onToggleName: (val) {
                setState(() {
                  _showName = val;
                });
              },
              onSizeChange: () {
                // Toggle scaling mode
                setState(() {
                  _isScalingMode = !_isScalingMode;
                });
                // Hide the wheel when entering scaling mode
                _hidePersistentWheel();
              },
              onPressed: _hidePersistentWheel,
              startDegrees: startDegrees,
              endDegrees: endDegrees,
            ),
          ),
        ),
      ]);
    });
  Overlay.of(context).insert(_overlayEntry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final optionContext = _optionWheelKey.currentContext;
      if (optionContext != null) {
        final RenderBox optionBox = optionContext.findRenderObject() as RenderBox;
        final Size measured = optionBox.size;
        if (measured != _wheelSize) {
          _wheelSize = measured;
          _overlayEntry?.markNeedsBuild();
        }
      }
    });
  }
  // removes the overlay wheel
    void _hidePersistentWheel() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _wheelSize = null;
  }
}