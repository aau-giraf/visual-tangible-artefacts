import 'package:flutter/material.dart';

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
