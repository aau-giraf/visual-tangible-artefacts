import 'dart:math' as math;
import 'package:flutter/material.dart';

class OptionWheel extends StatefulWidget {
  final String artefactName;
  final VoidCallback? onPressed;
  const OptionWheel({
    Key? key,
    required this.artefactName,
    this.onPressed,
  }) : super(key: key);

  @override
  _OptionWheelState createState() => _OptionWheelState();
}

class _OptionWheelState extends State<OptionWheel> {

  @override
  Widget build(BuildContext context) {
    // Buttons for the wheel
    final options = [
      _OptionWheelButton(
        icon: Icons.radio_button_checked,
        label: 'Audio',
        onPressed: () {},
      ),
      _OptionWheelButton(
        icon: Icons.radio_button_checked,
        label: 'Random',
        onPressed: () {},
      ),
      _OptionWheelButton(
        icon: Icons.radio_button_checked,
        label: 'Test',
        onPressed: () {},
      ),
      _OptionWheelButton(
        icon: Icons.radio_button_checked,
        label: 'Remove',
        onPressed: () {},
      ),
      _OptionWheelButton(
        icon: Icons.radio_button_checked,
        label: 'Combine',
        onPressed: () {},
      ),
    ];
    final int buttonCount = options.length;

    final double baseRadius = 150;
    final double radius = baseRadius;
    final double centerSize = 5;
    final double angleStep = 2 * math.pi / buttonCount;

    // Wheel offset to center
    final double wheelOffsetLeft = -120;
    final double wheelOffsetTop = -30;

    final double buttonSize = 90;
  final double wheelWidth = ((radius + buttonSize / 2 + 30) * 2);
    final double wheelHeight = ((radius + buttonSize / 2 + 30) * 2);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: wheelWidth,
        height: wheelHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Artefact name position
            Positioned(
              top: 10 + wheelOffsetTop,
              left: 0 + wheelOffsetLeft,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 140,
                  child: Text(
                    widget.artefactName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  )
                ),
              ),
            ),
            // Option buttons in a circle
            for (int i = 0; i < buttonCount; i++)
              Positioned(
                left: (wheelWidth / 2) + radius * math.cos(angleStep * i - math.pi / 2) - buttonSize / 2 + wheelOffsetLeft,
                top: (wheelHeight / 2) + radius * math.sin(angleStep * i - math.pi / 2) - 22 + wheelOffsetTop,
                child: options[i],
              ),
            // Center artefact for centering for now (no shadow)
            Positioned(
              left: (wheelWidth / 2) - centerSize / 2 + wheelOffsetLeft,
              top: (wheelHeight / 2) - centerSize / 2 + wheelOffsetTop,
              child: Container(
                width: centerSize,
                height: centerSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _OptionWheelButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _OptionWheelButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  State<_OptionWheelButton> createState() => _OptionWheelButtonState();
}

class _OptionWheelButtonState extends State<_OptionWheelButton> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 90, minWidth: 60),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Colors.transparent,
              width: 2,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 4, // static slight shadow
          shadowColor: Colors.black26,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        onPressed: widget.onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 18),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.label,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


