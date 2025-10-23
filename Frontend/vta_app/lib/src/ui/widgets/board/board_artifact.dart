import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/ui/widgets/board/_long_press_option_wheel.dart';

// do NOT store Widgets inside this class; build views on-demand
class BoardArtefact {
  final Widget baseContent;
  Offset? position;
  Size? renderedSize;
  final Artefact? baseArtefact;
  final Map<String, String>? headers;
  final ValueNotifier<Size> sizeNotifier;
  final ValueNotifier<bool> showResizeHandle;

  BoardArtefact({
    required this.baseContent,
    this.position,
    this.baseArtefact,
    this.headers,
    Size? initialSize,
  })  : key = GlobalKey(),
        sizeNotifier = ValueNotifier<Size>(initialSize ?? const Size(200, 200)),
        showResizeHandle = ValueNotifier<bool>(false);

  String get artefactId => baseArtefact?.artefactId ?? '';

  Widget get content => _BoardArtefactContent(
        baseContent: baseContent,
        sizeNotifier: sizeNotifier,
        showResizeNotifier: showResizeHandle,
      );

  factory BoardArtefact.fromArtefact(Artefact artefact,
      {Map<String, String>? headers}) {
    return BoardArtefact(baseArtefact: artefact, headers: headers);
  }
}

// use this in the widget layer to display artefacts.
class BoardArtefactView extends StatelessWidget {
  final BoardArtefact artefact;
  final Map<String, String>? headers;
  final double width;
  final double height;

  const BoardArtefactView({
    Key? key,
    required this.artefact,
    this.headers,
    this.width = 200,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final artefactData = artefact.baseArtefact;

    Widget content;
    // Check if artefact has an image
    if (artefactData != null &&
        artefactData.imageUrl != null &&
        artefactData.imageUrl!.isNotEmpty) {
      final usedHeaders = headers ?? artefact.headers;
      content = FadeInImage(
        imageErrorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/flutter_logo.png');
        },
        image: NetworkImage(artefactData.imageUrl!, headers: usedHeaders),
        placeholder: AssetImage('assets/images/flutter_logo.png'),
        fit: BoxFit.contain,
      );
    }
    // If no image but has sound, show speaker icon
    else if (artefactData != null &&
        artefactData.soundUrl != null &&
        artefactData.soundUrl!.isNotEmpty) {
      content = GestureDetector(
        onTap: () async {
          // Play the sound when clicked
          try {
            final player = AudioPlayer();
            await player.setUrl(artefactData.soundUrl!);
            await player.play();
          } catch (e) {
            print('Error playing sound: $e');
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
    // Fallback to default image
    } 
    else {
      innerContent = Image.asset('assets/images/flutter_logo.png');
    }

    return BoardArtefact(
      baseContent: innerContent,
      baseArtefact: artefact,
      initialSize: const Size(200, 200),
    );
  }
}

class _BoardArtefactContent extends StatefulWidget {
  final Widget baseContent;
  final ValueNotifier<Size> sizeNotifier;
  final ValueNotifier<bool> showResizeNotifier;

  const _BoardArtefactContent({
    Key? key,
    required this.baseContent,
    required this.sizeNotifier,
    required this.showResizeNotifier,
  }) : super(key: key);

  @override
  State<_BoardArtefactContent> createState() => _BoardArtefactContentState();
}

class _BoardArtefactContentState extends State<_BoardArtefactContent> {
  Size? _startSize;
  Offset? _startPointer;

  static const double _minWidth = 100.0;
  static const double _maxWidth = 1000.0;
  static const double _handleSize = 36.0;

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
            SizedBox(width: size.width, height: size.height, child: child),
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
