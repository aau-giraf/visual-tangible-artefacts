import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/option_wheel.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';

class LongPressOptionWheel extends StatefulWidget {
  final BoardArtefact artifact;
  final Widget child;

  const LongPressOptionWheel({
    Key? key,
    required this.artifact,
    required this.child,
  }) : super(key: key);

  @override
  State<LongPressOptionWheel> createState() => LongPressOptionWheelState();
}

class LongPressOptionWheelState extends State<LongPressOptionWheel> {
  OverlayEntry? _overlayEntry;
  Offset? _artifactCenterGlobal;
  Size? _wheelSize;
  final GlobalKey _optionWheelKey = GlobalKey();

  // Finding artifact center and showing wheel
  void _onLongPressStart(LongPressStartDetails details) {
    _showPersistentWheel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      child: widget.child,
    );
  }

  void _showPersistentWheel() {
    final artifactContext = widget.artifact.key.currentContext;
    if (artifactContext == null) return;

    final RenderBox artifactBox = artifactContext.findRenderObject() as RenderBox;
    _artifactCenterGlobal = artifactBox.localToGlobal(artifactBox.size.center(Offset.zero));

    // Create overlay
    _overlayEntry = OverlayEntry(builder: (context) {
      // Fallback sizes (if this happens... fix it)
      final double fallbackWidth = (150 + 90 / 2 + 30) * 2;
      final Size ws = _wheelSize ?? Size(fallbackWidth, fallbackWidth);
  final double left = _artifactCenterGlobal!.dx - ws.width / 2;
  final double top = _artifactCenterGlobal!.dy - ws.height / 2;
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
              onPressed: _hidePersistentWheel,
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
  // Remove the overlay wheel
  void _hidePersistentWheel() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _wheelSize = null;
  }
}