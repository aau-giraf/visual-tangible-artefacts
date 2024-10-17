import 'package:flutter/material.dart';
import 'linear_board.dart'; // Import the LinearBoard page

void main() {
  runApp(const RelationalBoardButton());
}

class RelationalBoardButton extends StatelessWidget {
  const RelationalBoardButton({Key? key}) : super(key: key);

  static const IconData calendarViewWeekRounded = IconData(0xf601, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const RelationalBoardHome(),
    );
  }
}

class RelationalBoardHome extends StatelessWidget {
  const RelationalBoardHome({Key? key}) : super(key: key);

  static const IconData calendarViewWeekRounded = IconData(0xf601, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relational Board'),
      ),
      body: const Center(child: Text('This is the Relational Board Page')),
      floatingActionButton: Align(
        alignment: const Alignment(-0.9, -0.8), // Adjust the alignment as needed
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const LinearBoard(),
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