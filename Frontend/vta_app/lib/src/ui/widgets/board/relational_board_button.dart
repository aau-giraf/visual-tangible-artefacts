import 'package:flutter/material.dart';

void main() {
  runApp(const RelationalBoardButton());
}

class RelationalBoardButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Icon? icon;
  final Object? heroTag;

  const RelationalBoardButton({super.key, this.onPressed, this.icon, this.heroTag});

  static const IconData calendarViewWeekRounded =
      IconData(0xf601, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed ?? () {},
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      shape: const CircleBorder(),
      child: icon,
    );
  }
}
