import 'package:flutter/material.dart';

class Artifact {
  final Widget content;
  Offset position;
  final GlobalKey key; // GlobalKey for accessing the widget's context
  final double height; // Height of the artifact
  final double width; // Width of the artifact
  Size? _renderedSize; // Private property to store the rendered size

  Artifact({
    required this.content,
    required this.position,
    required this.height,
    required this.width,
  }) : key = GlobalKey(); // Initialize the GlobalKey

  // Getter for rendered size
  Size? get renderedSize => _renderedSize;

  // Method to update the rendered size (can be called internally)
  set renderedSize(Size? size) {
    _renderedSize = size;
  }
}
