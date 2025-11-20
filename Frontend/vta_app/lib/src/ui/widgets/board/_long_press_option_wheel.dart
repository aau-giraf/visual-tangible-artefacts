import 'package:flutter/material.dart';
import 'talking_mat.dart';
import 'package:vta_app/src/ui/widgets/board/option_wheel.dart';
import 'package:flutter/gestures.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/controllers/talkingmat_controller.dart';
import '../../../utilities/audio/artefact_sound_player.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/ui/widgets/board/resize_overlay.dart';

class LongPressOptionWheel extends StatefulWidget {
  final BoardArtefact artifact;
  final Widget child;
  final TalkingmatController controller;
  final GlobalKey artifactKey;
  final ArtefactController artifactController;
  static const TextStyle nameTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.1,
  );

  const LongPressOptionWheel({
    super.key,
    required this.artifact,
    required this.child,  
    required this.controller,
    required this.artifactKey,
    required this.artifactController,
  });

  @override
  State<LongPressOptionWheel> createState() => LongPressOptionWheelState();
}

class LongPressOptionWheelState extends State<LongPressOptionWheel> {
  OverlayEntry? _overlayEntry;
  final _resizeOverlay = ResizeOverlay();
  Offset? _artifactCenterGlobal;
  Size? _wheelSize;
  Size? _resizeStartSize;
  Offset? _resizeStartPointer;
  static const double _minResizeWidth = 100.0;
  static const double _maxResizeWidth = 1000.0;
  final GlobalKey _optionWheelKey = GlobalKey();
  late bool _showName;
  final _soundPlayer = _ArtefactSoundPlayerImpl();

  @override
  void initState() {
    super.initState();
    _showName = widget.artifact.nameVisible;
  }

  @override
  void didUpdateWidget(covariant LongPressOptionWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always sync with external changes; the artefact instance is the same and mutated in place
    _showName = widget.artifact.nameVisible;
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
                style: LongPressOptionWheel.nameTextStyle,
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
    final artifactContext = widget.artifactKey.currentContext;
    if (artifactContext == null) return;

    final RenderBox artifactBox = artifactContext.findRenderObject() as RenderBox;
    _artifactCenterGlobal = artifactBox.localToGlobal(artifactBox.size.center(Offset.zero));

    // create overlay
    _overlayEntry = OverlayEntry(builder: (context) {
      // Calculate baseRadius based on artifact size
      final RenderBox artifactBox = widget.artifactKey.currentContext?.findRenderObject() as RenderBox;
      double baseRadius = 165; // default fallback
      final Size artifactSize = artifactBox.size;
      // Use the larger of width/height, scale factor can be tuned
      final double maxDim = artifactSize.width > artifactSize.height ? artifactSize.width : artifactSize.height;
      baseRadius = (maxDim * 0.8).clamp(130, 300); // scale with screen size???

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
              onToggleName: (val) async {
                  // Toggle per-instance visibility and trigger board auto-save so it persists.
                  widget.artifact.nameVisible = val;
                  setState(() { _showName = val; });

                  // Ask the owning TalkingMat (if available) to persist the change.
                  final matState = context.findAncestorStateOfType<TalkingMatState>();
                  await matState?.forceAutoSave();
              },
              playSound: () async {
                await _soundPlayer.playArtefactSound(widget.artifact.baseArtefact!);
              },
              onResize: () {
                widget.artifact.showResizeHandle.value = true;
                _resizeOverlay.show(context, widget.artifact, widget.artifactKey);
                _hidePersistentWheel();
              },
              onPressed: _hidePersistentWheel,
              startDegrees: startDegrees,
              endDegrees: endDegrees,
              baseRadius: baseRadius,
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

class _ArtefactSoundPlayerImpl with ArtefactSoundPlayer {}