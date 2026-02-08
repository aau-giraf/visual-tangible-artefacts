import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:logging/logging.dart';


final _log = Logger('BoardArtifact');
class BoardArtefact {
  final Widget baseContent;
  Offset? position;
  Size? renderedSize;
  Artefact? baseArtefact;
  String? savedArtefactId;
  final ValueNotifier<Size> sizeNotifier;
  final ValueNotifier<bool> showResizeHandle;
  // Used for auto-sizing images on first render
  final String? imageUrlForSizing;
  final Map<String, String>? imageHeadersForSizing;

  BoardArtefact({
    required this.baseContent,
    this.position,
    this.baseArtefact,
    this.imageUrlForSizing,
    this.imageHeadersForSizing,
    Size? initialSize,
    bool? nameVisible, // Kept for backward compatibility but ignored
  })  : sizeNotifier = ValueNotifier<Size>(initialSize ?? const Size(200, 200)),
        showResizeHandle = ValueNotifier<bool>(false);

  String get artefactId => baseArtefact?.artefactId ?? '';
  
  // Always read from baseArtefact.nameShown
  bool get nameVisible => baseArtefact?.nameShown ?? false;
  
  // Setter to update baseArtefact.nameShown
  set nameVisible(bool value) {
    if (baseArtefact != null) {
      baseArtefact!.nameShown = value;
    }
  }

  Widget get content => _BoardArtefactContent(
        baseContent: baseContent,
        sizeNotifier: sizeNotifier,
        showResizeNotifier: showResizeHandle,
    imageUrlForSizing: imageUrlForSizing,
    imageHeadersForSizing: imageHeadersForSizing,
      );

  factory BoardArtefact.fromArtefact(Artefact artefact,
      {Map<String, String>? headers}) {
    Widget innerContent;

    // Check if artefact has an image
    if (artefact.imageUrl != null && artefact.imageUrl!.isNotEmpty) {
      innerContent = FadeInImage(
        imageErrorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/flutter_logo.png');
        },
        image: NetworkImage(artefact.imageUrl!, headers: headers),
        placeholder: const AssetImage('assets/images/flutter_logo.png'),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    }
    // If no image but has sound, show speaker icon
    else if (artefact.soundUrl != null && artefact.soundUrl!.isNotEmpty) {
      innerContent = GestureDetector(
        onTap: () async {
          // Play the sound when clicked
          try {
            final player = AudioPlayer();
            await player.setUrl(artefact.soundUrl!);
            await player.play();
          } catch (e) {
            _log.fine('Error playing sound: $e');
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade300, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/speaker_icon.png',
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.play_circle_fill,
                color: Colors.blue.shade600,
                size: 32,
              ),
            ],
          ),
        ),
      );
    }
    // Fallback to default image
    else {
      innerContent = Image.asset('assets/images/flutter_logo.png');
    }



    return BoardArtefact(
      baseContent: innerContent,
      baseArtefact: artefact,
      imageUrlForSizing: artefact.imageUrl,
      imageHeadersForSizing: headers,
      initialSize: const Size(200, 200),

      nameVisible: artefact.nameShown ?? false,
    );
  }

 
  BoardArtefact clone({bool keepPosition = false}) {
    final cloned = BoardArtefact(
      baseContent: baseContent,
      baseArtefact: baseArtefact,
      imageUrlForSizing: imageUrlForSizing,
      imageHeadersForSizing: imageHeadersForSizing,
      initialSize: sizeNotifier.value,
      // Preserve the current tile's name visibility when cloning
      nameVisible: nameVisible,
    );
    if (keepPosition) {
      cloned.position = position == null ? null : Offset(position!.dx, position!.dy);
    }
    return cloned;
  }

  // (artefactId getter already defined below)
}

class _BoardArtefactContent extends StatefulWidget {
  final Widget baseContent;
  final ValueNotifier<Size> sizeNotifier;
  final ValueNotifier<bool> showResizeNotifier;
  final String? imageUrlForSizing;
  final Map<String, String>? imageHeadersForSizing;

  const _BoardArtefactContent({
    Key? key,
    required this.baseContent,
    required this.sizeNotifier,
    required this.showResizeNotifier,
    this.imageUrlForSizing,
    this.imageHeadersForSizing,
  }) : super(key: key);

  @override
  State<_BoardArtefactContent> createState() => _BoardArtefactContentState();
}

class _BoardArtefactContentState extends State<_BoardArtefactContent> {
  Size? _startSize;
  Offset? _startPointer;
  bool _autoSizedDone = false;

  static const double _minWidth = 100.0;
  static const double _maxWidth = 500.0;
  static const double _handleSize = 36.0;

  @override
  void initState() {
    super.initState();
    _maybeAutoSizeFromImage();
  }

  void _maybeAutoSizeFromImage() {
    // Only for network images, only once, and only if size is still default-ish
    if (_autoSizedDone) return;
    final initial = widget.sizeNotifier.value;
    if (initial.width != 200 || initial.height != 200) return;
    final url = widget.imageUrlForSizing;
    if (url == null || url.isEmpty) return;

    final ImageProvider provider = NetworkImage(url, headers: widget.imageHeadersForSizing);
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo info, bool syncCall) {
      final int w = info.image.width;
      final int h = info.image.height;
      if (w > 0 && h > 0) {
        final double ar = w / h;
        // Choose category and base width for nicer boxes
        double targetWidth;
        if ((ar - 1.0).abs() < 0.1) {
          // square
          targetWidth = 220;
        } else if (ar > 1.0) {
          // landscape
          targetWidth = 260;
        } else {
          // portrait
          targetWidth = 180;
        }
        double targetHeight = targetWidth / ar;
        // Clamp to limits
        targetWidth = targetWidth.clamp(_minWidth, _maxWidth);
        targetHeight = targetHeight.clamp(_minWidth * (1 / 3), _maxWidth * 2);
        // Apply
        try {
          widget.sizeNotifier.value = Size(targetWidth, targetHeight);
          _autoSizedDone = true;
        } catch (e) { _log.fine('Error setting artifact size: $e'); }
      }
      try { stream.removeListener(listener!); } catch (e) { _log.fine('Error removing stream listener: $e'); }
    }, onError: (dynamic _, __) {
      try { stream.removeListener(listener!); } catch (e) { _log.fine('Error removing stream listener: $e'); }
    });
    stream.addListener(listener);
  }

  void _onPointerDown(PointerDownEvent event) {
    _startSize = widget.sizeNotifier.value;
    _startPointer = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_startSize == null || _startPointer == null) return;
    final dx = event.position.dx - _startPointer!.dx;
    final double aspect = _startSize!.height / _startSize!.width;
    double newWidth = (_startSize!.width + dx).clamp(_minWidth, _maxWidth);
    final double newHeight = (newWidth * aspect).clamp(_minWidth * aspect, _maxWidth * aspect);
    widget.sizeNotifier.value = Size(newWidth, newHeight);
  }

  void _onPointerUp(PointerUpEvent event) {
    _startSize = null;
    _startPointer = null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Size>(
      valueListenable: widget.sizeNotifier,
      builder: (context, size, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: size.width, 
              height: size.height, 
              child: FittedBox(
                fit: BoxFit.contain,
                child: child,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: widget.showResizeNotifier,
              builder: (context, visible, _) {
                if (!visible) return const SizedBox.shrink();
                return Positioned(
                  right: 0,
                  bottom: 0,
          child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerUp,
                    child: Container(
                      width: _handleSize + 12,
                      height: _handleSize + 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                        ],
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.open_with,
                          size: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      child: widget.baseContent,
    );
  }
}