import 'package:flutter/material.dart';

class TeachersHubPanel extends StatelessWidget {
  const TeachersHubPanel({
    super.key,
    required this.onBoards,
    required this.onSettings,
    required this.onLogout,
    this.onImages,
    this.onPersonalization,
    this.borderRadius = BorderRadius.zero,
  });

  final VoidCallback onBoards;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final VoidCallback? onImages; // TODO: wire up when the screen exists
  final VoidCallback? onPersonalization; // TODO: wire up when the screen exists
  final BorderRadius borderRadius;

  static const Color _logoutColor = Color(0xFFC2185B);
  static const Color _textColor = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 600;
    final itemFontSize = wide ? 18.0 : 15.0;

    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, wide ? 28 : 22, 16, 16),
        child: Column(
          children: [
            // Title with underline
            Container(
              padding: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFFEC377), width: 1),
                ),
              ),
              child: Text(
                'Lærer Hub',
                style: TextStyle(
                  fontSize: wide ? 24 : 20,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: wide ? 36 : 28),
            _MenuItem('Boards', onBoards, itemFontSize),
            _MenuItem('Billeder', onImages, itemFontSize),
            _MenuItem('Indstillinger', onSettings, itemFontSize),
            _MenuItem('Personlig Tilpasning', onPersonalization, itemFontSize),
            const Spacer(),
            TextButton(
              onPressed: onLogout,
              child: Text(
                'Log Ud',
                style: TextStyle(
                  fontSize: itemFontSize,
                  color: _logoutColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(this.label, this.onTap, this.fontSize);

  final String label;
  final VoidCallback? onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            color: TeachersHubPanel._textColor,
          ),
        ),
      ),
    );
  }
}