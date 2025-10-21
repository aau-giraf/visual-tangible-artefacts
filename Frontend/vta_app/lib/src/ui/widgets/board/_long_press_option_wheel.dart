import 'package:flutter/material.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/ui/widgets/board/option_wheel.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';


class LongPressOptionWheel extends StatefulWidget {
  final BoardArtefact artifact;
  final Widget child;
  final ArtefactController artifactController;

  const LongPressOptionWheel({
    Key? key,
    required this.artifact,
    required this.child,
    required this.artifactController,
  }) : super(key: key);

  @override
  State<LongPressOptionWheel> createState() => LongPressOptionWheelState();
}

class LongPressOptionWheelState extends State<LongPressOptionWheel> {
  OverlayEntry? _overlayEntry;
  Offset? _artifactCenterGlobal;
  Size? _wheelSize;
  final GlobalKey _optionWheelKey = GlobalKey();
  late bool _showName;

  @override
  void initState() {
    super.initState();
    _showName = widget.artifact.baseArtefact?.nameShown ?? false;
  }

  // finding artifact center and showing wheel
  void _onLongPressStart(LongPressStartDetails details) {
    _showPersistentWheel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedOpacity(
          opacity: _showName ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: true,
            child: Container(
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
        GestureDetector(
          onLongPressStart: _onLongPressStart,
          child: widget.child,
        ),
      ],
    );
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
              artefactId: widget.artifact.artefactId,
              artefactName: widget.artifact.baseArtefact?.name ?? '',
              showName: widget.artifact.baseArtefact?.nameShown ?? false,
              onToggleName: (val) async {
                widget.artifact.baseArtefact?.nameShown = val;
                setState(() {
                  _showName = val;
                });
                // Persist the change to backend
                await widget.artifactController.updateArtifacts(context: context);
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