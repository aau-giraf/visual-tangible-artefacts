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
  /// The [showAtTop] parameter positions the snackbar at the top of the screen when true. Defaults to true.
  ///
  /// The snackbar will automatically color-match to the current theme and [color], if no [iconColor] and/or [textColor] is provided.
  ///
  /// For async contexts where BuildContext might be invalid, you can pass [scaffoldMessenger] and [screenHeight] directly.
  ///
  static show(
    BuildContext? context,
    String message, {
    Color color = Colors.white,
    Color? iconColor,
    Color? textColor,
    bool showAtTop = true,
    ScaffoldMessengerState? scaffoldMessenger,
    double? screenHeight,
  }) {
    // Determine which ScaffoldMessenger to use
    final messenger = scaffoldMessenger ?? ScaffoldMessenger.of(context!);

    // Get color scheme for contrast calculation (if context available)
    ColorScheme? colorScheme;
    if (context != null) {
      colorScheme = Theme.of(context).colorScheme;
    }

    // If no color is provided, default to the primary color (or white if no context)
    final backgroundColor = color;

    // Determine a contrasting color for text and icons
    final contrastColor = _getContrastingColor(backgroundColor, colorScheme);

    // Calculate screen height for top positioning
    final height = screenHeight ??
        (context != null ? MediaQuery.of(context).size.height : 800);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
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
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: showAtTop
            ? EdgeInsets.only(
                top: 10,
                left: 10,
                right: 10,
                bottom: height - 150,
              )
            : EdgeInsets.all(10),
        padding: EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: contrastColor,
          onPressed: () {
            // Handle action if needed
          },
        ),
      ),
    );
  }

  // Helper method to determine contrasting color for action
  static Color _getContrastingColor(
      Color backgroundColor, ColorScheme? colorScheme) {
    // Simple approach to determine if the background is light or dark
    final brightness = backgroundColor.computeLuminance();

    // If we have a color scheme, use its colors for better theming
    if (colorScheme != null) {
      return brightness > 0.5 ? colorScheme.onSurface : colorScheme.onPrimary;
    }

    // Fallback to simple black/white contrast
    return brightness > 0.5 ? Colors.black87 : Colors.white;
  }
}
