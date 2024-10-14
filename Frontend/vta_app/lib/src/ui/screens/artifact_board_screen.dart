import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vta_app/src/ui/widgets/board/artifact.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';

class ArtifactBoardScreen extends StatelessWidget {
  const ArtifactBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the height of the bottom bar (if any)

    double padding = 40; // Padding around the ArtifactBoard
    final GlobalKey<TalkingMatState> talkingmatKey =
        GlobalKey<TalkingMatState>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Center the ArtifactBoard with appropriate padding
            Padding(
              padding: EdgeInsets.all(padding),
              child: Center(
                child: TalkingMat(
                  key: talkingmatKey,
                  artifacts: [
                    Artifact(
                      position: const Offset(500, 500),
                      content: SvgPicture.asset('assets/icons/sillyface.svg'),
                    ),
                    Artifact(
                      position: const Offset(500, 500),
                      content: SvgPicture.asset('assets/icons/sillyface.svg'),
                    )
                  ], // Full width with padding
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Create a new artifact and add it
                Artifact newArtifact = Artifact(
                  content: SvgPicture.asset('assets/icons/sillyface.svg'),
                  position: const Offset(100, 100),
                );
                // Call the addArtifact method directly
                talkingmatKey.currentState?.addArtifact(newArtifact);
              },
              child: const Text('Add Artifact'),
            ),
            // Add more widgets here as needed
          ],
        ),
      ),
    );
  }
}
