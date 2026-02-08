import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:logging/logging.dart';

final _log = Logger('ResizeOverlay');

class ResizeOverlay {
  OverlayEntry? _resizeCaptureEntry;
  VoidCallback? _resizeListener;
  PointerRoute? _globalPointerRoute;

  bool get isShowing => _resizeCaptureEntry != null;

  void show(BuildContext context, BoardArtefact artifact, GlobalKey artifactKey) {
    if (_resizeCaptureEntry != null) return;

    _resizeCaptureEntry = OverlayEntry(builder: (context) {
      final RenderBox? artifactBox = artifactKey.currentContext?.findRenderObject() as RenderBox?;
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
          artifact.showResizeHandle.value = false;
        } catch (e) { _log.fine('Error hiding resize handle: $e'); }
        hide(artifact);
      }
    };
    GestureBinding.instance.pointerRouter.addGlobalRoute(_globalPointerRoute!);
    
    _resizeListener = () {
      _resizeCaptureEntry?.markNeedsBuild();
    };
    try {
      artifact.sizeNotifier.addListener(_resizeListener!);
    } catch (e) { _log.fine('Error adding size listener: $e'); }
  }

  void hide(BoardArtefact artifact) {
    _resizeCaptureEntry?.remove();
    _resizeCaptureEntry = null;
    
    if (_globalPointerRoute != null) {
      try {
        GestureBinding.instance.pointerRouter.removeGlobalRoute(_globalPointerRoute!);
      } catch (e) { _log.fine('Error removing pointer route: $e'); }
      _globalPointerRoute = null;
    }
    
    if (_resizeListener != null) {
      try {
        artifact.sizeNotifier.removeListener(_resizeListener!);
      } catch (e) { _log.fine('Error removing size listener: $e'); }
      _resizeListener = null;
    }
    
    try {
      artifact.showResizeHandle.value = false;
    } catch (e) { _log.fine('Error hiding resize handle: $e'); }
  }

  void dispose(BoardArtefact artifact) {
    hide(artifact);
  }
}
