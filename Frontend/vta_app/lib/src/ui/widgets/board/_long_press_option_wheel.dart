import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/option_wheel.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';

class LongPressOptionWheel extends StatefulWidget {
  final BoardArtefact artifact;
  final Widget child;

  const LongPressOptionWheel({
    Key? key,
    required this.artifact,
    required this.child,
  }) : super(key: key);

  @override
  State<LongPressOptionWheel> createState() => LongPressOptionWheelState();
}

class LongPressOptionWheelState extends State<LongPressOptionWheel> {
  bool _showWheel = false;
  late final String artefactName;
  @override
  void initState() {
    super.initState();
    // fallback if name is not available
  artefactName = widget.artifact.baseArtefact?.displayName ?? widget.artifact.baseArtefact?.toString() ?? "Artefact";
  }

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _showWheel = true;
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _showWheel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_showWheel)
              Positioned(
                left: 0,
              top: -90,
              child: OptionWheel(
                onPressed: () {},
              ),
            ),
        ],
      ),
    );
  }
}