import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vta_app/src/ui/widgets/board/artifact.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';

class ArtifactBoardScreen extends StatelessWidget {
  const ArtifactBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double padding = 20; // Padding around the ArtifactBoard
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
              padding: EdgeInsets.only(
                  top: 5, left: padding, right: padding, bottom: 0),
              child: Center(
                child: TalkingMat(
                  key: talkingmatKey,
                  artifacts: [
                    Artifact(
                      position: const Offset(500, 500),
                      content: SvgPicture.asset('assets/icons/sillyface.svg'),
                    ),
                    Artifact(
                      position: const Offset(500, 250),
                      content: SvgPicture.asset('assets/icons/sillyface.svg'),
                    ),
                  ], // Full width with padding
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Create a new artifact and add it
                Artifact newArtifact = Artifact(
                  content: SvgPicture.asset('assets/icons/sillyface.svg'),
                  position: const Offset(299, 200),
                );
                // Call the addArtifact method directly
                talkingmatKey.currentState?.addArtifact(newArtifact);
              },
              child: const Text('Add Artifact'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
          height: 100, // Set the height of the placeholder
          color: Colors.grey[300], // Set a background color for the placeholder
          alignment: Alignment.center,
          child: const Stack(alignment: Alignment.center, children: [
            Placeholder(),
            Text(
              'Categories Bar Placeholder',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ])),
    );
  }
}
