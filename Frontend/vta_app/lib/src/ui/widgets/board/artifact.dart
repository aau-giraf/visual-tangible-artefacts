import 'package:flutter/material.dart';

class Artifact {
  final Widget content;
  Offset position;
  final GlobalKey key; // GlobalKey for accessing the widget's context
  Size? renderedSize; // Private property to store the rendered size

  Artifact({
    required this.content,
    required this.position,
  }) : key = GlobalKey();
}
