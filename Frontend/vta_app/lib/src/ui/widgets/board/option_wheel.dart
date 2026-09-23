// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/config/elevenlabs_config.dart';
import 'package:vta_app/src/utilities/config/voice_config_validator.dart';
import 'package:record/record.dart' show AudioEncoder, RecordConfig;
import 'package:vta_app/src/utilities/audio/recorder.dart';
import 'package:logging/logging.dart';

final _log = Logger('OptionWheel');

enum _SoundOption { textToSpeech, record, upload }

class OptionWheel extends StatefulWidget {
  final Artefact artefact;
  final VoidCallback? onPressed;
  final bool showName;
  final VoidCallback? playSound;
  final VoidCallback? onResize;
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
    required this.playSound,
    this.onResize,
    this.onToggleName,
    this.onPressed,
    this.onSizeChange, // Add size change callback
    this.startDegrees = -80,
    this.endDegrees = 80,
    this.baseRadius = 165,
    this.verticalNudge = 0,
  });

  @override
  State<OptionWheel> createState() => _OptionWheelState();
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
    final double wheelOffsetTop = 60;

    // button size (width)
    final double buttonSize = 100;

    // buttons for the wheel
    final options = [
      _OptionWheelButton(
        icon: Icons.volume_up,
        label: 'Audio',
        onPressed: () {
          widget.playSound?.call();
        },
        preferredWidth: buttonSize,
      ),
      _OptionWheelButton(
        icon: Icons.edit,
        label: 'skift lyd',
        onPressed: () async {
          final dialogFuture = _showChangeSoundDialog(context);
          widget.onPressed?.call(); // Close wheel after dialog launched
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
        icon: Icons.open_in_full,
        label: 'Størrelse',
        onPressed: () {
          widget.onResize?.call();
          widget.onPressed?.call();
        },
        preferredWidth: buttonSize,
      ),
    ];
    final int buttonCount = options.length;
    final double degreesStep =
        buttonCount > 1 ? (endDegrees - startDegrees) / (buttonCount - 1) : 0.0;

    // wheel dimensions
    final double wheelWidth = ((radius + buttonSize / 2 + 30) * 2);
    final double wheelHeight = wheelWidth;

    // animation for buttons (go from center to radius) vibe
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: wheelWidth,
        height: wheelHeight,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final double t = Curves.easeOut.transform(_ctrl.value);
            final double animatedRadius = radius * t;

            final List<Map<String, dynamic>> entries = [];
            for (int i = 0; i < buttonCount; i++) {
              final double angleDeg = startDegrees + degreesStep * i;
              final double leftPos = (wheelWidth / 2) +
                  animatedRadius *
                      math.cos(angleDeg * math.pi / 180 - math.pi / 2) -
                  buttonSize / 2 +
                  wheelOffsetLeft;
              double topPos = (wheelHeight / 2) +
                  animatedRadius *
                      math.sin(angleDeg * math.pi / 180 - math.pi / 2) +
                  widget.verticalNudge +
                  wheelOffsetTop +  
                  -36;
              // if the button is near the wheel's left or right edge, nudge it up
              // slightly to avoid visual clipping with the board edge.
              const double upwardNudge = -48.0; // negative to move up
              
              final bool nearRightEdge =
                  leftPos + buttonSize > wheelWidth;
              if (nearRightEdge) {
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Navnet kan ikke være tomt'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();

              try {
                final controller = GetIt.I.get<ArtefactController>();
                final updatedArtefact = Artefact(
                  artefactId: widget.artefact.artefactId,
                  userId: widget.artefact.userId,
                  categoryId: widget.artefact.categoryId,
                  artefactIndex: widget.artefact.artefactIndex,
                  name: newName,
                );
                if (!context.mounted) return;
                await controller.updateArtefact(context, updatedArtefact);
              } catch (e) {
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
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
    if (!context.mounted) return;
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final rootContext = rootNavigator.context;

    if (!rootContext.mounted) return;
    final result = await showDialog<_SoundOption>(
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
                Navigator.of(dialogContext).pop(_SoundOption.textToSpeech);
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
                Navigator.of(dialogContext).pop(_SoundOption.record);
              },
              icon: const Icon(Icons.fiber_manual_record),
              label: const Text('Optag lyd'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(_SoundOption.upload);
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuller'),
          ),
        ],
      ),
    );

    if (!rootContext.mounted) return;

    if (result == _SoundOption.textToSpeech) {
      await _showTextToSpeechDialog(rootContext);
    } else if (result == _SoundOption.record) {
      await _showRecordSoundDialog(rootContext);
    } else if (result == _SoundOption.upload) {
      await _showUploadSoundDialog(rootContext);
    }
  }

  Future<void> _showTextToSpeechDialog(BuildContext rootContext) async {
    String inputText = '';
    final navigator = Navigator.of(rootContext, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(rootContext);

    final savedVoiceId = VoiceConfigValidator.resolveVoiceId(
        await ElevenLabsConfig.getDefaultVoiceId());
    String selectedVoiceId = savedVoiceId;
    final voiceOptions = VoiceConfigValidator.getVoiceOptions();

    if (!rootContext.mounted) return;

    await showDialog(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Tekst til tale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Indtast tekst',
                  border: OutlineInputBorder(),
                  hintText: 'Teksten vil blive konverteret til tale',
                ),
                maxLines: 3,
                autofocus: true,
                onChanged: (value) => inputText = value,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(dialogContext).unfocus(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vælg stemme',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              ...voiceOptions.map(
                (option) => InkWell(
                  onTap: () {
                    setDialogState(() {
                      selectedVoiceId = VoiceConfigValidator.resolveVoiceId(option['id']!);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: option['id']!,
                          groupValue: selectedVoiceId,
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selectedVoiceId = VoiceConfigValidator.resolveVoiceId(value);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option['label']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                final text = inputText.trim();
                if (text.isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Teksten kan ikke være tom'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final voiceIdToUse = VoiceConfigValidator.resolveVoiceId(selectedVoiceId);

                // Validate voice ID before proceeding
                if (!VoiceConfigValidator.isValidVoiceId(voiceIdToUse)) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Ugyldig stemme valgt. Bruger standardstemme.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }

                FocusScope.of(dialogContext).unfocus();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(); // Close the input dialog

                bool loadingDialogVisible = false;

                // Show loading indicator using the root navigator so it survives wheel closure.
                if (!rootContext.mounted) return;
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
                    'Artefacts/generate-speech-and-save',
                    headers: {'Authorization': 'Bearer ${token.value}'},
                    body: {
                      'artefactId': widget.artefact.artefactId,
                      'text': text,
                      'voiceId': voiceIdToUse,
                    },
                  );

                  closeLoadingDialogIfNeeded();

                  // Only save voice preference after successful API call
                  if (response != null && response.ok) {
                    await ElevenLabsConfig.setDefaultVoiceId(voiceIdToUse);

                    // Refresh artefacts in background without blocking the UI.
                    if (rootContext.mounted) {
                      final controller = GetIt.I.get<ArtefactController>();
                      controller
                          .updateArtifacts(context: rootContext)
                          .catchError((_) {
                        // Silently ignore refresh issues.
                      });
                    }

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
                            'Kunne ikke generere lyd: ${response?.statusCode}. Prøv venligst igen.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  closeLoadingDialogIfNeeded();

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Fejl ved generering af tale: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Generer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecordSoundDialog(BuildContext rootContext) async {
    if (kIsWeb) {
      if (!rootContext.mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('Optagelse er ikke understøttet i browseren.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    dynamic recorder;
    try {
      recorder = createRecorder();
    } catch (_) {
      recorder = null;
    }

    if (recorder == null) {
      if (!rootContext.mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('Optagelse er ikke tilgængelig på denne enhed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool isRecording = false;
    Duration recordingDuration = Duration.zero;
    Timer? recordTimer;
    Uint8List? recordedBytes;
    String? recordingPath;

    void cancelTimer() {
      recordTimer?.cancel();
      recordTimer = null;
    }

    Future<void> startRecording(StateSetter update) async {
      try {
        final hasPermission = await (recorder as dynamic).hasPermission();
        if (!hasPermission) {
          if (!rootContext.mounted) return;
          ScaffoldMessenger.of(rootContext).showSnackBar(
            const SnackBar(
              content: Text('Mangler mikrofon-tilladelse'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final tempFile =
            '${Directory.systemTemp.path}/vta_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
        recordingPath = tempFile;

        await (recorder as dynamic).start(
          RecordConfig(encoder: AudioEncoder.aacLc),
          path: tempFile,
        );

        update(() {
          isRecording = true;
          recordingDuration = Duration.zero;
          recordedBytes = null;
        });

        cancelTimer();
        recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          update(() {
            recordingDuration = recordingDuration + const Duration(seconds: 1);
          });
        });
      } catch (e) {
        recordingPath = null;
        if (!rootContext.mounted) return;
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            content: Text('Kunne ikke starte optagelse: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    Future<void> stopRecording(StateSetter update) async {
      if (!isRecording) {
        return;
      }

      try {
        final path = await (recorder as dynamic).stop();
        cancelTimer();

        final filePath = path ?? recordingPath;
        Uint8List? bytes;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
            try {
              await file.delete();
            } catch (e) { _log.fine('Failed to delete temp file: $e'); }
          }
        }

        update(() {
          isRecording = false;
          recordedBytes = bytes ?? recordedBytes;
        });
        recordingPath = null;
      } catch (e) {
        cancelTimer();
        update(() {
          isRecording = false;
        });
        if (!rootContext.mounted) return;
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            content: Text('Kunne ikke stoppe optagelse: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (!rootContext.mounted) return;
    await showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Optag lyd'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRecording ? Icons.mic : Icons.mic_none,
                    size: 48,
                    color: isRecording ? Colors.red : Colors.black54,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDuration(recordingDuration),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (isRecording) {
                        await stopRecording(setState);
                      } else {
                        await startRecording(setState);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecording ? Colors.red : null,
                      foregroundColor: isRecording ? Colors.white : null,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    icon: Icon(
                        isRecording ? Icons.stop : Icons.fiber_manual_record),
                    label: Text(
                        isRecording ? 'Stop optagelse' : 'Start optagelse'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    recordedBytes != null
                        ? 'Optagelsen er klar til upload.'
                        : isRecording
                            ? 'Optagelse i gang...'
                            : 'Tryk på start for at optage lyd.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (isRecording) {
                      await stopRecording(setState);
                    }
                    setState(() {
                      recordedBytes = null;
                    });
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Annuller'),
                ),
                TextButton(
                  onPressed: (!isRecording && recordedBytes != null)
                      ? () async {
                          if (!rootContext.mounted) return;
                          final navigator =
                              Navigator.of(rootContext, rootNavigator: true);
                          bool loadingVisible = false;

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
                          loadingVisible = true;

                          void closeLoading() {
                            if (loadingVisible && navigator.mounted) {
                              navigator.pop();
                              loadingVisible = false;
                            }
                          }

                          try {
                            final controller =
                                GetIt.I.get<ArtefactController>();
                            final updatedArtefact = Artefact(
                              artefactId: widget.artefact.artefactId,
                              userId: widget.artefact.userId,
                              categoryId: widget.artefact.categoryId,
                              artefactIndex: widget.artefact.artefactIndex,
                              sound: recordedBytes,
                            );

                            if (!rootContext.mounted) {
                              closeLoading();
                              return;
                            }
                            await controller.updateArtefact(
                                rootContext, updatedArtefact);

                            closeLoading();
                            if (dialogContext.mounted && Navigator.of(dialogContext).mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            closeLoading();
                            if (!rootContext.mounted) return;
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Kunne ikke gemme optagelsen: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text('Gem'),
                ),
              ],
            );
          },
        );
      },
    );

    cancelTimer();
    if (isRecording) {
      try {
        await (recorder as dynamic).stop();
      } catch (e) { _log.fine('Error stopping recorder: $e'); }
    }
    if (recordingPath != null) {
      try {
        final file = File(recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) { _log.fine('Error cleaning up recording file: $e'); }
    }
  }

  Future<void> _showUploadSoundDialog(BuildContext rootContext) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFile = result.files.single;
    final bytes = pickedFile.bytes;
    if (bytes == null) {
      if (!rootContext.mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke læse den valgte lydfil.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!rootContext.mounted) return;
    final navigator = Navigator.of(rootContext, rootNavigator: true);
    bool loadingVisible = false;

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
    loadingVisible = true;

    void closeLoading() {
      if (loadingVisible && navigator.mounted) {
        navigator.pop();
        loadingVisible = false;
      }
    }

    try {
      final controller = GetIt.I.get<ArtefactController>();
      final updatedArtefact = Artefact(
        artefactId: widget.artefact.artefactId,
        userId: widget.artefact.userId,
        categoryId: widget.artefact.categoryId,
        artefactIndex: widget.artefact.artefactIndex,
        sound: Uint8List.fromList(bytes),
      );

      if (!rootContext.mounted) {
        closeLoading();
        return;
      }
      await controller.updateArtefact(rootContext, updatedArtefact);

      closeLoading();
      if (!rootContext.mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text('Lydfilen "${pickedFile.name}" er uploadet.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      closeLoading();
      if (!rootContext.mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke uploade lydfilen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
