import 'package:flutter/material.dart';
import 'relational_board_button.dart'; // Import the switch_modes page

class LinearBoardButton extends StatelessWidget {
  const LinearBoardButton({super.key});

// ignore: constant_identifier_names
  static const IconData crop_landscape_rounded =
      IconData(0xf685, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                const RelationalBoardHome(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      shape: const CircleBorder(),
      child: const Icon(
        crop_landscape_rounded,
        size: 24.0,
      ),
    );
  }
}
