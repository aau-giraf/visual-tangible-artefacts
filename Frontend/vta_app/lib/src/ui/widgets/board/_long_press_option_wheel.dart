import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/option_wheel.dart';
import 'package:flutter/gestures.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/controllers/talkingmat_controller.dart';
import '../../../utilities/audio/artefact_sound_player.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';

class LongPressOptionWheel extends StatefulWidget {
  final BoardArtefact artifact;
  final Widget child;
  final TalkingmatController controller;
  final GlobalKey artifactKey;

  const LongPressOptionWheel({
    super.key,
    required this.artifact,
    required this.child,  
    required this.controller,
    required this.artifactKey,
  });

  @override
  State<LongPressOptionWheel> createState() => LongPressOptionWheelState();
}

class LongPressOptionWheelState extends State<LongPressOptionWheel> {
  OverlayEntry? _overlayEntry;
  OverlayEntry? _resizeCaptureEntry;
  VoidCallback? _resizeListener;
  PointerRoute? _globalPointerRoute;
  Offset? _artifactCenterGlobal;
  Size? _wheelSize;
  final GlobalKey _optionWheelKey = GlobalKey();
  bool _showName = false;
  final _soundPlayer = _ArtefactSoundPlayerImpl();

  @override
  void initState() {
    super.initState();
    // Initialize showName from the artefact model if available
    _showName = widget.artifact.baseArtefact?.nameShown ?? false;
  }

  // finding artifact center and showing wheel
  void _onLongPressStart(LongPressStartDetails details) {
    _showPersistentWheel();
  }

  void _showResizeCaptureOverlay() {
    if (_resizeCaptureEntry != null) return;

    _resizeCaptureEntry = OverlayEntry(builder: (context) {
      final RenderBox? artifactBox = widget.artifactKey.currentContext?.findRenderObject() as RenderBox?;
      if (artifactBox == null) {
        return const SizedBox.shrink();
      }

      return Stack(children: [
      ]);
    });

    Overlay.of(context).insert(_resizeCaptureEntry!);
    // Install a global pointer route to detect pointer-up events anywhere
    // without blocking hit-testing. This allows stopping resize when the user
    // releases the pointer even if they release outside the artifact area.
    _globalPointerRoute = (PointerEvent event) {
      if (event is PointerUpEvent) {
        try {
          widget.artifact.showResizeHandle.value = false;
        } catch (_) {}
        _hideResizeCaptureOverlay();
      }
    };
    GestureBinding.instance.pointerRouter.addGlobalRoute(_globalPointerRoute!);
    _resizeListener = () {
      _resizeCaptureEntry?.markNeedsBuild();
    };
    try {
      widget.artifact.sizeNotifier.addListener(_resizeListener!);
    } catch (_) {}
  }

  void _hideResizeCaptureOverlay() {
    _resizeCaptureEntry?.remove();
    _resizeCaptureEntry = null;
    if (_globalPointerRoute != null) {
      try {
        GestureBinding.instance.pointerRouter.removeGlobalRoute(_globalPointerRoute!);
      } catch (_) {}
      _globalPointerRoute = null;
    }
    if (_resizeListener != null) {
      try {
        widget.artifact.sizeNotifier.removeListener(_resizeListener!);
      } catch (_) {}
      _resizeListener = null;
    }
    try {
      widget.artifact.showResizeHandle.value = false;
    } catch (_) {}
  }

 @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onLongPressStart: _onLongPressStart,
          child: widget.child,
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
                try {
                  // Update local artefact model
                  widget.artifact.baseArtefact?.nameShown = val;
                  setState(() {
                    _showName = val;
                  });
                  // Persist change using ArtefactController if available
                  try {
                    final controller = GetIt.I.get<ArtefactController>();
                    if (widget.artifact.baseArtefact != null) {
                      await controller.updateArtefact(context, widget.artifact.baseArtefact!);
                    }
                  } catch (_) {
                    // ignore if controller not registered
                  }
                } catch (_) {}
              },
              playSound: () {
                final artefact = widget.artifact.baseArtefact;
                if (artefact != null) {
                  _soundPlayer.playArtefactSound(artefact);
                } else {
                  debugPrint('TODO : Add sound for artefact');
                }
                _hidePersistentWheel();
              },
              onResize: () async {
                widget.artifact.showResizeHandle.value = true;
                _hidePersistentWheel();
                _showResizeCaptureOverlay();
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

// Private implementation that mixes in the ArtefactSoundPlayer functionality
class _ArtefactSoundPlayerImpl with ArtefactSoundPlayer {}