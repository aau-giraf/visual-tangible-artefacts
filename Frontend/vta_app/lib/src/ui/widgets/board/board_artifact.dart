import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';

class BoardArtefact {
  final Widget content;
  Offset? position;
  final GlobalKey key;
  Size? renderedSize;
  Artefact? baseArtefact;

  BoardArtefact({
    required this.content,
    this.position,
    this.baseArtefact,
  }) : key = GlobalKey();

  String get artefactId => baseArtefact?.artefactId ?? '';

  factory BoardArtefact.fromArtefact(Artefact artefact,
      {Map<String, String>? headers}) {
    
    Widget content;
    
    // Check if artefact has an image
    if (artefact.imageUrl != null && artefact.imageUrl!.isNotEmpty) {
      content = FadeInImage(
        imageErrorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/flutter_logo.png');
        },
        image: NetworkImage(artefact.imageUrl!, headers: headers),
        placeholder: AssetImage('assets/images/flutter_logo.png'),
      );
    } 
    // If no image but has sound, show speaker icon
    else if (artefact.soundUrl != null && artefact.soundUrl!.isNotEmpty) {
      content = GestureDetector(
        onTap: () async {
          // Play the sound when clicked
          try {
            final player = AudioPlayer();
            await player.setUrl(artefact.soundUrl!);
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
    }
    // Fallback to default image
    else {
      content = Image.asset('assets/images/flutter_logo.png');
    }
    
    return BoardArtefact(
        content: SizedBox(
          width: 200,
          height: 200,
          child: content,
        ),
        baseArtefact: artefact);
  }
}
