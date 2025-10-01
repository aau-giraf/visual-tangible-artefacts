import 'dart:math' as math;
import 'package:flutter/material.dart';

class OptionWheel extends StatefulWidget {
  final VoidCallback? onPressed;
  final double startDegrees;
  final double endDegrees;
  final double baseRadius;
  final double verticalNudge;

//Options for setting the degrees of the wheel and give it nudge
  const OptionWheel({
    Key? key,
    this.onPressed,
    this.startDegrees = -80,
    this.endDegrees = 80,
    this.baseRadius = 180,
    this.verticalNudge = 0,
  }) : super(key: key);

  @override
  _OptionWheelState createState() => _OptionWheelState();
}

class _OptionWheelState extends State<OptionWheel> {

  @override
  Widget build(BuildContext context) {
    // Button definitions, right now temporary static ones
    // Could just be icons such icons.audio_file and so on without a name...
    // Right now there is a length limit for box length for 90, if text is longer it will just say "..."
    final OptionWheelButtons = [
      {'icon': Icons.radio_button_checked, 'label': 'Audio must suffer', 'onPressed': () {}},
      {'icon': Icons.radio_button_checked, 'label': 'Random', 'onPressed': () {}},
      {'icon': Icons.radio_button_checked, 'label': 'Test', 'onPressed': () {}},
      {'icon': Icons.radio_button_checked, 'label': 'Remove', 'onPressed': () {}},
      {'icon': Icons.radio_button_checked, 'label': 'Combine', 'onPressed': () {}},
    ];
  final int buttonCount = OptionWheelButtons.length;

  // Radius and center marker
  final double baseRadius = widget.baseRadius;
  double radius = baseRadius;
  final double centerSize = 5;
  final double startDegrees = widget.startDegrees;
  final double endDegrees = widget.endDegrees;
  final double degreesStep = buttonCount > 1 ? (endDegrees - startDegrees) / (buttonCount - 1) : 0.0;

    // Wheel nudge from center
    final double wheelOffsetLeft = 0;
    final double wheelOffsetTop = 40;

    // Button size (width)
    final double buttonSize = 90;
    if (buttonCount > 1) {
      final double deltaAngleRad = (degreesStep.abs()) * math.pi / 180.0; 
  final double desiredArcSpacing = buttonSize + 18; 
      if (deltaAngleRad > 0) {
        final double requiredRadius = desiredArcSpacing / deltaAngleRad;
        if (requiredRadius > radius) {
          radius = requiredRadius;
        }
      }
    }

    // Wheel dimensions
    final double WheelWidth = ((radius + buttonSize / 2 + 30) * 2);
    final double WheelHeight = WheelWidth;

    // MouseRegion/hit area
    final options = OptionWheelButtons.map((d) => _OptionWheelButton(
      icon: d['icon'] as IconData,
      label: d['label'] as String,
      onPressed: d['onPressed'] as VoidCallback,
      preferredWidth: buttonSize,
    )).toList();
    final List<Map<String, dynamic>> _entries = [];
    for (int i = 0; i < buttonCount; i++) {
      final double angleDeg = startDegrees + degreesStep * i;
      final double leftPos = (WheelWidth / 2) + radius * math.cos(angleDeg * math.pi / 180 - math.pi / 2) - buttonSize / 2 + wheelOffsetLeft;
      final double topPos = (WheelHeight / 2) + radius * math.sin(angleDeg * math.pi / 180 - math.pi / 2) + widget.verticalNudge + wheelOffsetTop;
      final Widget positionedWidget = Positioned(
        left: leftPos,
        top: topPos,
        width: buttonSize,
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 60, maxWidth: buttonSize),
            child: options[i],
          ),
        ),
      );
      _entries.add({'top': topPos, 'widget': positionedWidget});
    }
    _entries.sort((a, b) => (a['top'] as double).compareTo(b['top'] as double));
    final List<Widget> childrenWidgets = _entries.map<Widget>((e) => e['widget'] as Widget).toList();

    // Center artefact for centering (remove when not needed)
    childrenWidgets.add(
      Positioned(
        left: (WheelWidth / 2) - centerSize / 2 + wheelOffsetLeft,
        top: (WheelHeight / 2) - centerSize / 2 + wheelOffsetTop,
        child: Container(
          width: centerSize,
          height: centerSize,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    // Build buttons
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: WheelWidth,
        height: WheelHeight,
        child: Stack(
          alignment: Alignment.center,
          children: childrenWidgets,
        ),
      ),
    );
  }
}

// Individual option button in the wheel
class _OptionWheelButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double? preferredWidth;
  const _OptionWheelButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.preferredWidth,
  });

  @override
  State<_OptionWheelButton> createState() => _OptionWheelButtonState();
}

// Individual button style
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


