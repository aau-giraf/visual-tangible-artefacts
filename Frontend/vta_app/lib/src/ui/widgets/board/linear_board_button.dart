import 'package:flutter/material.dart';
import 'relational_board_button.dart'; // Import the switch_modes page

class LinearBoard extends StatelessWidget {
  const LinearBoard({Key? key}) : super(key: key);

// ignore: constant_identifier_names
static const IconData crop_landscape_rounded = IconData(0xf685, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('This is the linear Board page'),
      ),
      floatingActionButton: Align(
        alignment: const Alignment(-0.9, -0.8), // Adjust the alignment as needed
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const RelationalBoardButton(),
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
        ),
      ),
    );
  }
}