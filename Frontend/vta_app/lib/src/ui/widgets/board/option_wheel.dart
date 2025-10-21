import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/singletons/token.dart';

class OptionWheel extends StatefulWidget {
  final Artefact artefact;
  final VoidCallback? onPressed;
  final bool showName;
  final ValueChanged<bool>? onToggleName;
  final VoidCallback? onSizeChange; // Callback for size button
  final double startDegrees;
  final double endDegrees;
  final double baseRadius;
  final double verticalNudge;

  // wheel nudge
  const OptionWheel({
    super.key,
    required this.artefact,
    required this.showName,
    this.onToggleName,
    this.onPressed,
    this.onSizeChange, // Add size change callback
    this.startDegrees = -80,
    this.endDegrees = 80,
    this.baseRadius = 165,
    this.verticalNudge = 0,
  });

  @override
  _OptionWheelState createState() => _OptionWheelState();
}

// states for the option wheel
class _OptionWheelState extends State<OptionWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 360));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // radius and center marker (this is for seeing if wheel is centered, put larger than 0 to see)
    final double baseRadius = widget.baseRadius;
    double radius = baseRadius;
    final double centerSize = 0;
    final double startDegrees = widget.startDegrees;
    final double endDegrees = widget.endDegrees;

    // wheel nudge from center
    final double wheelOffsetLeft = 0;
    final double wheelOffsetTop = 70;

    // button size (width)
    final double buttonSize = 100;

    // buttons for the wheel
    final options = [
      _OptionWheelButton(
        icon: Icons.volume_up,
        label: 'skift lyd',
        onPressed: () async {
          final dialogFuture = _showChangeSoundDialog(context);
          widget.onPressed?.call(); // Close wheel after dialog launched
          await dialogFuture;
        },
        preferredWidth: buttonSize,
      ),
      _OptionWheelButton(
        icon: Icons.edit,
        label: 'skift navn',
        onPressed: () async {
          final dialogFuture = _showChangeNameDialog(context);
          widget.onPressed?.call();
          await dialogFuture;
        },
        preferredWidth: buttonSize,
      ),
      _OptionWheelButton(
        icon: Icons.radio_button_checked,
        label: widget.showName ? 'Skjul Navn' : 'Vis Navn',
        onPressed: () {
          widget.onToggleName?.call(!widget.showName);
          widget.onPressed?.call();
        },
        preferredWidth: buttonSize,
      ),
      _OptionWheelButton(
        icon: Icons.radio_button_checked,
        label: 'slet',
        onPressed: () {},
        preferredWidth: buttonSize,
      ),
      _OptionWheelButton(
        icon: Icons.photo_size_select_small,
        label: 'størrelse',
        onPressed: () {
          widget.onSizeChange?.call();
          widget.onPressed?.call();
        },
        preferredWidth: buttonSize,
      ),
    ];
    final int buttonCount = options.length;
    final double degreesStep =
        buttonCount > 1 ? (endDegrees - startDegrees) / (buttonCount - 1) : 0.0;

    // wheel dimensions
    final double WheelWidth = ((radius + buttonSize / 2 + 30) * 2);
    final double WheelHeight = WheelWidth;

    // animation for buttons (go from center to radius) vibe
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: WheelWidth,
        height: WheelHeight,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final double t = Curves.easeOut.transform(_ctrl.value);
            final double animatedRadius = radius * t;

            final List<Map<String, dynamic>> entries = [];
            for (int i = 0; i < buttonCount; i++) {
              final double angleDeg = startDegrees + degreesStep * i;
              final double leftPos = (WheelWidth / 2) +
                  animatedRadius *
                      math.cos(angleDeg * math.pi / 180 - math.pi / 2) -
                  buttonSize / 2 +
                  wheelOffsetLeft;
              double topPos = (WheelHeight / 2) +
                  animatedRadius *
                      math.sin(angleDeg * math.pi / 180 - math.pi / 2) +
                  widget.verticalNudge +
                  wheelOffsetTop +
                  5;
              // if the button is near the wheel's left or right edge, nudge it up
              // slightly to avoid visual clipping with the board edge.
              const double horizontalEdgeThreshold = 300;
              const double upwardNudge = -48.0; // negative to move up
              final bool nearLeftEdge = leftPos < horizontalEdgeThreshold;
              final bool nearRightEdge =
                  leftPos + buttonSize > WheelWidth - horizontalEdgeThreshold;
              if (nearLeftEdge || nearRightEdge) {
                topPos += upwardNudge;
              }

              // per-button staggered scale + opacity
              final double startInterval = (i * 0.08).clamp(0.0, 0.8);
              final double endInterval = (startInterval + 0.45).clamp(0.0, 1.0);
              final Animatable<double> scaleTween = Tween(begin: 0.6, end: 1.0)
                  .chain(CurveTween(
                      curve: Interval(startInterval, endInterval,
                          curve: Curves.easeOut)));
              final Animatable<double> opacityTween =
                  Tween(begin: 0.0, end: 1.0).chain(CurveTween(
                      curve: Interval(startInterval, endInterval,
                          curve: Curves.easeOut)));

              final Animation<double> scaleAnim = _ctrl.drive(scaleTween);
              final Animation<double> opacityAnim = _ctrl.drive(opacityTween);

              final Widget positionedWidget = Positioned(
                left: leftPos,
                top: topPos,
                width: buttonSize,
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minWidth: 60, maxWidth: buttonSize),
                    child: FadeTransition(
                      opacity: opacityAnim,
                      child: ScaleTransition(
                        scale: scaleAnim,
                        child: options[i],
                      ),
                    ),
                  ),
                ),
              );
              entries.add(
                  {'left': leftPos, 'top': topPos, 'widget': positionedWidget});
            }
            entries.sort(
                (a, b) => (a['top'] as double).compareTo(b['top'] as double));
            final List<Widget> childrenWidgets =
                entries.map<Widget>((e) => e['widget'] as Widget).toList();

            // background arc
            childrenWidgets.insert(
              0,
              Positioned.fill(
                child: CustomPaint(
                  painter: _ArcBackgroundPainter(
                    radius: animatedRadius,
                    startDegrees: startDegrees,
                    endDegrees: endDegrees,
                    wheelOffsetLeft: wheelOffsetLeft,
                    wheelOffsetTop: wheelOffsetTop - 20,
                  ),
                ),
              ),
            );

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

            // button hit rects (to dismiss wheel)
            final List<Rect> buttonRects = entries.map((e) {
              final double left = e['left'] as double;
              final double top = e['top'] as double;
              return Rect.fromLTWH(left, top, buttonSize, buttonSize);
            }).toList();

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                final local = details.localPosition;
                final bool tappedOnButton =
                    buttonRects.any((r) => r.contains(local));
                if (!tappedOnButton) {
                  widget.onPressed?.call();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: childrenWidgets,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showChangeNameDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController(
      text: widget.artefact.name ?? '',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skift navn'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nyt navn',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navnet kan ikke være tomt'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(context).pop();

              try {
                final controller = GetIt.I.get<ArtefactController>();
                final updatedArtefact = Artefact(
                  artefactId: widget.artefact.artefactId,
                  userId: widget.artefact.userId,
                  categoryId: widget.artefact.categoryId,
                  artefactIndex: widget.artefact.artefactIndex,
                  name: newName,
                );
                await controller.updateArtefact(context, updatedArtefact);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fejl: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Gem'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeSoundDialog(BuildContext context) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final rootContext = rootNavigator.context;

    final result = await showDialog<bool>(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Skift lyd'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vælg hvordan du vil tilføje lyd:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true); // Return true to indicate text-to-speech
              },
              icon: const Icon(Icons.mic),
              label: const Text('Tekst til tale'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false); // Return false to indicate file upload
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload lydfil'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuller'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _showTextToSpeechDialog(rootContext);
    } else if (result == false) {
      await _showUploadSoundDialog(rootContext);
    }
  }

  Future<void> _showTextToSpeechDialog(BuildContext rootContext) async {
    final TextEditingController textController = TextEditingController();
    final navigator = Navigator.of(rootContext, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(rootContext);

    await showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tekst til tale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Indtast tekst',
                border: OutlineInputBorder(),
                hintText: 'Teksten vil blive konverteret til tale',
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'Dette vil bruge ElevenLabs til at generere tale fra teksten.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Teksten kan ikke være tom'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(dialogContext).pop(); // Close the input dialog

              bool loadingDialogVisible = false;

              // Show loading indicator using the root navigator so it survives wheel closure.
              showDialog(
                context: rootContext,
                barrierDismissible: false,
                builder: (_) => const PopScope(
                  canPop: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
              loadingDialogVisible = true;

              void closeLoadingDialogIfNeeded() {
                if (loadingDialogVisible && navigator.mounted) {
                  navigator.pop();
                  loadingDialogVisible = false;
                }
              }

              try {
                // Call backend to generate speech using ElevenLabs
                final apiProvider = GetIt.I.get<ApiProvider>();
                final token = GetIt.I.get<Token>();

                final response = await apiProvider.postAsJson(
                  'Users/Artefacts/generate-speech-and-save',
                  headers: {'Authorization': 'Bearer ${token.value}'},
                  body: {
                    'artefactId': widget.artefact.artefactId,
                    'text': text,
                  },
                );

                closeLoadingDialogIfNeeded();

                if (response != null && response.ok) {
                  // Refresh artefacts in background without blocking the UI.
                  final controller = GetIt.I.get<ArtefactController>();
                  controller
                      .updateArtifacts(context: rootContext)
                      .catchError((_) {
                    // Silently ignore refresh issues.
                  });

                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Lyden er opdateret'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          'Kunne ikke generere lyd: ${response?.statusCode}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                closeLoadingDialogIfNeeded();

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Fejl: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Generer'),
          ),
        ],
      ),
    );

    textController.dispose();
  }

  Future<void> _showUploadSoundDialog(BuildContext rootContext) async {
    await showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upload lydfil'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Filupload funktionalitet kommer snart.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// background arc painter
class _ArcBackgroundPainter extends CustomPainter {
  final double radius;
  final double startDegrees;
  final double endDegrees;
  final double wheelOffsetLeft;
  final double wheelOffsetTop;

  _ArcBackgroundPainter({
    required this.radius,
    required this.startDegrees,
    required this.endDegrees,
    required this.wheelOffsetLeft,
    required this.wheelOffsetTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color.fromARGB(80, 0, 0, 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 45
      ..strokeCap = StrokeCap.round;

    final center = Offset(
        size.width / 2 + wheelOffsetLeft, size.height / 2 + wheelOffsetTop);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final double startRad = (startDegrees - 90) * math.pi / 180;
    final double sweepRad = (endDegrees - startDegrees) * math.pi / 180;

    canvas.drawArc(rect, startRad, sweepRad, false, paint);
  }

  @override
  bool shouldRepaint(_ArcBackgroundPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.startDegrees != startDegrees ||
        oldDelegate.endDegrees != endDegrees;
  }
}

// button option in the wheel requrements, else throws error
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

// button style
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
