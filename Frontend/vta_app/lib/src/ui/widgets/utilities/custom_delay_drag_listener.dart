import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';


/// A custom drag listener that allows for a configurable delay before starting the drag operation.
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
