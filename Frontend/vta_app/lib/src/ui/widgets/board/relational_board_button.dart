import 'package:flutter/material.dart';
import 'linear_board.dart'; // Import the LinearBoard page

void main() {
  runApp(const RelationalBoardButton());
}

class RelationalBoardButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Icon? icon;

  const RelationalBoardButton({super.key, this.onPressed, this.icon});

  static const IconData calendarViewWeekRounded =
      IconData(0xf601, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed ?? () {},
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      shape: const CircleBorder(),
      child: icon,
    );
  }
}

class RelationalBoardHome extends StatelessWidget {
  const RelationalBoardHome({super.key});

  static const IconData calendarViewWeekRounded =
      IconData(0xf601, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relational Board'),
      ),
      body: const Center(child: Text('This is the Relational Board Page')),
      floatingActionButton: Align(
        alignment:
            const Alignment(-0.9, -0.8), // Adjust the alignment as needed
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    const LinearBoard(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(
            calendarViewWeekRounded,
            size: 24.0,
          ),
        ),
      ),
    );
  }
}
