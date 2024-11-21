import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CustomDelayDragStartListener extends ReorderableDelayedDragStartListener {
  final int delay;

  const CustomDelayDragStartListener({
    super.key,
    required super.child,
    required super.index,
    required this.delay,
    super.enabled,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(
      delay: Duration(milliseconds: delay),
      debugOwner: this,
    );
  }
}
