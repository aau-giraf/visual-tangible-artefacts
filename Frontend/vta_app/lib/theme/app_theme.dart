import 'package:flutter/material.dart';

/// The theme for this specific app.
class AppTheme {
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade100, // Background color for fields
    labelStyle: TextStyle(
      fontSize: 16,
      color: Colors.grey.shade700, // Label color
    ),
    hintStyle: TextStyle(
      fontSize: 14,
      color: Colors.grey.shade500, // Hint color
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), // Rounded corners
      borderSide: BorderSide.none, // No border by default
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.grey.shade300, // Subtle border when not focused
        width: 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.blue.shade300, // Highlight color when focused
        width: 2.0,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.red.shade300, // Error color
        width: 1.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.red.shade600, // Focused error color
        width: 2.0,
      ),
    ),
    contentPadding: EdgeInsets.symmetric(
      vertical: 16,
      horizontal: 20,
    ), // Padding inside the field
  );
}
