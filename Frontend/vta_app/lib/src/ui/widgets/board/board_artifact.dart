import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';

/// Internal widget that wraps the base content with size notifiers
class _BoardArtefactContent extends StatelessWidget {
  final Widget baseContent;
  final ValueNotifier<Size> sizeNotifier;
  final ValueNotifier<bool> showResizeNotifier;
  final String? imageUrlForSizing;
  final Map<String, String>? imageHeadersForSizing;

  const _BoardArtefactContent({
    required this.baseContent,
    required this.sizeNotifier,
    required this.showResizeNotifier,
    this.imageUrlForSizing,
    this.imageHeadersForSizing,
  });

  @override
  Widget build(BuildContext context) {
    return baseContent;
  }
}

class BoardArtefact {
  final Widget baseContent;
  Offset? position;
  Size? renderedSize;
  Artefact? baseArtefact;
  String? savedArtefactId;
  final ValueNotifier<Size> sizeNotifier;
  final ValueNotifier<bool> showResizeHandle;
  // Per-instance display state (e.g., show name above the artefact)
  bool nameVisible;
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
    bool? nameVisible,
  })  : sizeNotifier = ValueNotifier<Size>(initialSize ?? const Size(200, 200)),
        showResizeHandle = ValueNotifier<bool>(false),
        nameVisible = nameVisible ?? false;

  String get artefactId => baseArtefact?.artefactId ?? '';

  Widget get content => _BoardArtefactContent(
        baseContent: baseContent,
        sizeNotifier: sizeNotifier,
        showResizeNotifier: showResizeHandle,
    imageUrlForSizing: imageUrlForSizing,
    imageHeadersForSizing: imageHeadersForSizing,
      );

  factory BoardArtefact.fromArtefact(Artefact artefact,
      {Map<String, String>? headers, BuildContext? context}) {
    
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
            debugPrint('Error playing sound: $e');
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
    
    // Create flexible content that adapts to parent constraints
    // Use AspectRatio with proper constraints to ensure valid sizing
    Widget responsiveContent = AspectRatio(
      aspectRatio: 1.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 50,
          minHeight: 50,
          maxWidth: 500,
          maxHeight: 500,
        ),
        child: artefact.imageUrl != null && artefact.imageUrl!.isNotEmpty
            ? FadeInImage(
                imageErrorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/images/flutter_logo.png');
                },
                image: NetworkImage(artefact.imageUrl ?? "", headers: headers),
                placeholder: AssetImage('assets/images/flutter_logo.png'),
                fit: BoxFit.contain,
              )
            : FittedBox(
                fit: BoxFit.contain,
                child: innerContent,
              ),
      ),
    );
    
    return BoardArtefact(
        baseContent: responsiveContent,
        baseArtefact: artefact);
  }
}
