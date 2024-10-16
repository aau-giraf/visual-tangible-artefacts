import 'package:flutter/material.dart';
import 'linear_board_button.dart';

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
      home: const FloatingActionButtonExample(),
    );
  }
}

class FloatingActionButtonExample extends StatefulWidget {
  const FloatingActionButtonExample({Key? key}) : super(key: key);

  @override
  State<FloatingActionButtonExample> createState() =>
      _FloatingActionButtonExampleState();
}

class _FloatingActionButtonExampleState
    extends State<FloatingActionButtonExample> {
  // The FAB's foregroundColor, backgroundColor, and shape
  static const List<(Color?, Color? background, ShapeBorder?)> customizations =
      <(Color?, Color?, ShapeBorder?)>[
    (null, null, null), // The FAB uses its default for null parameters.
    (Colors.black, Colors.white, CircleBorder()),
  ];
  int index = 3; // Selects the customization.

  static const IconData calendarViewWeekRounded = IconData(0xf601, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: const Center(child: Text('This is the relational board page')),
      floatingActionButton: Align(
        alignment: const Alignment(-0.9, -0.8), // Adjust the alignment as needed
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const LinearBoard(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          foregroundColor: customizations[index].$1,
          backgroundColor: customizations[index].$2,
          shape: customizations[index].$3,
          child: const Icon(
            calendarViewWeekRounded,
            size: 24.0,
          ),
        ),
      ),
    );
  }
}