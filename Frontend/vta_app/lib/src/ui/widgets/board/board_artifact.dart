import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';

// do NOT store Widgets inside this class; build views on-demand
class BoardArtefact {
  Offset? position;
  Size? renderedSize;
  final Artefact? baseArtefact;
  final Map<String, String>? headers;

  BoardArtefact({
    this.position,
    this.baseArtefact,
    this.headers,
  });

  String get artefactId => baseArtefact?.artefactId ?? '';

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
              SizedBox(height: 8),
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
      content = Image.asset('assets/images/flutter_logo.png');
    }
          height: 200,
        ),

    return SizedBox(width: width, height: height, child: content);
  }
}
