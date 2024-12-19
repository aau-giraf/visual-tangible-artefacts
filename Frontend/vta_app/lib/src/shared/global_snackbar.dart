import 'package:flutter/material.dart';

/// A global SnackBar that can be shown from anywhere in the app.
///
/// It provides a consistent look and feel for all SnackBars.
class GlobalSnackbar {
  final String message;

  const GlobalSnackbar({required this.message});

  /// Shows a SnackBar with the provided [message].
  ///
  /// The [color] parameter can be used to set a custom background color for the SnackBar. Defaults to [Colors.white].
  ///
  /// The snackbar will automatically color-match to the current theme and [color], if no [iconColor] and/or [textColor] is provided.
  ///
  static show(BuildContext context, String message,
      {Color color = Colors.white, Color? iconColor, Color? textColor}) {
    // Get the current theme's color scheme
    final colorScheme = Theme.of(context).colorScheme;

    // If no color is provided, default to the primary color
    final backgroundColor = color ?? colorScheme.primary;

    // Determine a contrasting color for the action button (typically a light color)
    final contrastColor = _getContrastingColor(backgroundColor, colorScheme);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline, // You can choose any icon here
              color: iconColor ?? contrastColor,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor ?? contrastColor,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor, // Set the dynamic background color
        behavior: SnackBarBehavior.floating, // Makes it float above the content
        duration: Duration(seconds: 3), // Customize the duration
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        margin: EdgeInsets.all(10), // Adds space around the SnackBar
        padding: EdgeInsets.all(16), // Adds padding inside the SnackBar
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: contrastColor, // Dynamic action color
          onPressed: () {
            // Handle action if needed
          },
        ),
      ),
    );
  }

  // Helper method to determine contrasting color for action
  static Color _getContrastingColor(
      Color backgroundColor, ColorScheme colorScheme) {
    // Simple approach to determine if the background is light or dark
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? colorScheme.onSurface : colorScheme.onPrimary;
  }
}
