import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/artifact_board.dart';

class ArtifactBoardScreen extends StatelessWidget {
  const ArtifactBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the height of the screen
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    // Define the height of the bottom bar (if any)

    double padding = 40.0; // Padding around the ArtifactBoard

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
                child: ArtifactBoard(
                  // Set height to the calculated available height
                  height: screenHeight,
                  width: screenWidth, // Full width with padding
                ),
              ),
            ),
            // Add more widgets here as needed
          ],
        ),
      ),
    );
  }
}
