import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/ui/screens/take_picture_screen.dart';
import 'package:vta_app/src/ui/widgets/categories/addPicture.dart';
import 'package:vta_app/src/utilities/services/camera_service.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:record/record.dart' show AudioEncoder, RecordConfig;
import '../../../utilities/audio/recorder.dart';
import 'package:just_audio/just_audio.dart';

class AddItemPopup extends StatefulWidget {
  final Category? category;
  final bool isCategory;
  final void Function(String name, Uint8List? imageBytes, Uint8List? soundBytes)
      onSubmit;
  final String title;

  const AddItemPopup({
    super.key,
    required this.isCategory,
    required this.onSubmit,
    this.category,
    required this.title,
  });

  @override
  State<AddItemPopup> createState() => _AddItemPopupState();
}

class _LevelBar extends StatelessWidget {
  final double level; // 0.0 - 1.0
  const _LevelBar({Key? key, required this.level}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: level.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.greenAccent.shade400,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddItemPopupState extends State<AddItemPopup> {
  Uint8List? imageBytes;
  Uint8List? soundBytes;
  bool _isRecording = false;
  // Record is implemented via platform interface. Lazily instantiate at
  // runtime inside initState so web/unsupported platforms don't attempt to
  // instantiate an abstract implementation at compile time.
  dynamic _recorder;
  final AudioPlayer _player = AudioPlayer();
  final formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController _textToSpeechController = TextEditingController();
  // Recording UI state
  Duration _recordingDuration = Duration.zero;
  Timer? _recordTimer;
  Timer? _amplitudeTimer;
  double _currentLevel = 0.0; // 0.0 - 1.0
  double _levelPhase = 0.0;
  // AI Text-to-Speech state
  bool _showTextToSpeechField = false;
  bool _isGeneratingSpeech = false;

  void setGeneratedImage(String bytes) {
    final decodedBytes = base64Decode(bytes);
    setState(() {
      imageBytes = decodedBytes;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      nameController.text = widget.category!.name ?? '';
      _loadImageBytes();
    }
    // Lazily create the recorder via platform factory (may return null on web)
    try {
      _recorder = createRecorder();
    } catch (_) {
      _recorder = null;
    }
    // listen for name changes to update submit button state
    nameController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    nameController.dispose();
    _textToSpeechController.dispose();
    try {
      _player.dispose();
    } catch (_) {}
    try {
      // Best-effort stop recorder on dispose, but only if we are currently recording
      if (_isRecording && _recorder != null) {
        try {
          (_recorder as dynamic).stop();
        } catch (_) {}
      }
    } catch (_) {}
    // cancel timers
    try {
      _recordTimer?.cancel();
    } catch (_) {}
    try {
      _amplitudeTimer?.cancel();
    } catch (_) {}
    nameController.removeListener(_onFormChanged);
    super.dispose();
  }

  void _onFormChanged() {
    // Trigger a rebuild when the name changes so submit button updates
    setState(() {});
  }

  bool _canSubmit() {
    final hasName = nameController.text.trim().isNotEmpty;
    final hasImage = imageBytes != null;
    if (widget.isCategory) {
      return hasName && hasImage;
    } else {
      final hasSound = soundBytes != null;
      // return hasName && hasImage && hasSound;   Doesnt' work
      return hasName && hasImage;

    }
  }

  Future<void> _loadImageBytes() async {
    if (widget.category?.imageUrl != null) {
      final bytes = await getImageFromUrl(widget.category!.imageUrl);
      setState(() {
        imageBytes = bytes;
      });
    }
  }

  Future<Uint8List?> getImageFromUrl(String? imageUrl) async {
    if (imageUrl == null) {
      return null;
    }
    var headers = <String, String>{
      "Authorization": "Bearer ${GetIt.instance.get<Token>().value}"
    };
    final response = await http.get(Uri.parse(imageUrl), headers: headers);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var minHeight = screenSize.height * 0.8;
    var minWidth = screenSize.width * 0.6;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: minHeight,
          maxWidth: minWidth,
          minHeight: 0,
          minWidth: 0,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogTheme.backgroundColor ?? 
                 Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(4, 4),
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildForm(minWidth, formKey, nameController),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(double minWidth, GlobalKey<FormState> formKey,
      TextEditingController nameController) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: minWidth * 0.8,
            child: Column(
              children: [
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return widget.isCategory
                          ? 'Et kategori navn er påkrævet'
                          : 'Et artefakt navn er påkrævet';
                    }
                    return null;
                  },
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    hintText:
                        widget.isCategory ? 'Kategori navn' : 'Artefakt navn',
                    hintStyle: TextStyle(color: Color(0xFF7C7C7C)),
                  ),
                ),
                SizedBox(height: 16),
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      imageBytes!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Image.asset(
                    'assets/images/no_image.png',
                    width: 150,
                    height: 150,
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                    'Tag billede', 'assets/images/camera_icon_filled.png',
                    onClick: _onTakePictureButtonPressed),
                SizedBox(width: 16),
                _buildButton('Upload', 'assets/images/folder_icon.png',
                    onClick: () async {
                  var result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                      withData: true);
                  if (result != null) {
                    setState(() {
                      imageBytes = result.files.single.bytes;
                    });
                  }
                }),
                SizedBox(width: 16),
                _buildButton('Lav med AI', 'assets/images/ai_file.png',
                    onClick: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          color: Colors.white,
                          width: 760,
                          height: 500,
                          child: AIPage(onImageProcessed: setGeneratedImage),
                        ),
                      );
                    },
                  );
                }),
                SizedBox(width: 16),
                // Only show the sound button when adding an artefact, not a category
                if (!widget.isCategory)
                  _buildButton('Tilføj lyd', 'assets/images/speaker_icon.png',
                      onClick: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: StatefulBuilder(
                            builder: (context, setDialogState) {
                              // Calculate height based on content visibility
                              double baseHeight = 450;
                              if (_showTextToSpeechField) {
                                baseHeight = 650; // Larger when TTS field is visible
                              } else if (soundBytes != null) {
                                baseHeight = 550; // Medium when sound is added (shows playback controls)
                              }
                              
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).dialogTheme.backgroundColor ?? 
                                         Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                width: 560,
                                constraints: BoxConstraints(
                                  maxHeight: baseHeight,
                                  minHeight: 300,
                                ),
                                padding: EdgeInsets.all(16),
                                child: SingleChildScrollView(
                                  child: _buildSoundModal(setDialogState),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // 0xFF2E7D32 = dark green, 0xFFBADFB5 = light green
                  backgroundColor:
                      _canSubmit() ? Color(0xFF2E7D32) : Color(0xFFBADFB5),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _canSubmit()
                    ? () {
                        if (formKey.currentState!.validate()) {
                          // Categories shouldn't include soundBytes
                          final Uint8List? sendSound =
                              widget.isCategory ? null : soundBytes;
                          widget.onSubmit(
                              nameController.text, imageBytes, sendSound);
                          Navigator.of(context).pop();
                        }
                      }
                    : null,
                child: Text(
                  widget.isCategory ? 'Tilføj kategori' : 'Tilføj artefakt',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Luk'),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _onTakePictureButtonPressed() {
    if (CameraManager().cameras.isEmpty) {
      var snackMessage = 'No cameras available';
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        snackMessage = 'Camera not supported on desktop';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackMessage)),
      );
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => TakePictureScreen(
                camera: CameraManager().cameras.first,
                onImageChosen: (bytes) {
                  setState(() {
                    imageBytes = bytes;
                  });
                },
              )));
    }
  }

  Widget _buildSoundModal(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/speaker_icon.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text('Tilføj lyd til artefakt',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setDialogState(() {
                  _showTextToSpeechField = !_showTextToSpeechField;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: _showTextToSpeechField
                    ? Theme.of(context).colorScheme.primary
                    : null,
                foregroundColor: _showTextToSpeechField ? Colors.white : null,
              ),
              icon: const Icon(Icons.mic),
              label: Text(_showTextToSpeechField
                  ? 'Skjul tekst til tale'
                  : 'Tekst til tale (AI)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  if (_recorder == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Optager ikke tilgængelig på denne platform')),
                    );
                    return;
                  }

                  if (!_isRecording) {
                    final bool hasPermission =
                        await (_recorder as dynamic).hasPermission();
                    if (!hasPermission) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Mangler mikrofon tilladelse')),
                      );
                      return;
                    }
                    final tmpPath =
                        '${Directory.systemTemp.path}/vta_record_${DateTime.now().millisecondsSinceEpoch}.m4a';

                    try {
                      await (_recorder as dynamic).start(
                        RecordConfig(encoder: AudioEncoder.aacLc),
                        path: tmpPath,
                      );

                      setState(() {
                        _isRecording = true;
                        _recordingDuration = Duration.zero;
                        _currentLevel = 0.0;
                        _levelPhase = 0.0;
                      });
                    } catch (startError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Kunne ikke starte optagelse: $startError')),
                      );
                      return;
                    }

                    _recordTimer?.cancel();
                    _recordTimer =
                        Timer.periodic(const Duration(seconds: 1), (_) {
                      setDialogState(() {
                        _recordingDuration =
                            _recordingDuration + const Duration(seconds: 1);
                      });
                    });
                    _amplitudeTimer?.cancel();
                    _amplitudeTimer = Timer.periodic(
                        const Duration(milliseconds: 200), (_) async {
                      try {
                        final amp = await (_recorder as dynamic).getAmplitude();
                        double level = 0.0;
                        if (amp != null) {
                          if (amp is Map && amp.containsKey('current')) {
                            level = (amp['current'] as num).toDouble();
                          } else if (amp is num) {
                            level = amp.toDouble();
                          }
                        }
                        final normalized = (level <= 0)
                            ? 0.0
                            : (level / 32768.0).clamp(0.0, 1.0);
                        setDialogState(() {
                          _currentLevel = normalized;
                        });
                      } catch (_) {
                        // Amplitude not supported, use fake pulse animation
                        _levelPhase += 0.3;
                        final pulse =
                            (0.3 + 0.7 * (0.5 + 0.5 * (sin(_levelPhase))).abs())
                                .clamp(0.0, 1.0);
                        setDialogState(() {
                          _currentLevel = pulse;
                        });
                      }
                    });
                  } else {
                    final path = await (_recorder as dynamic).stop();
                    _recordTimer?.cancel();
                    _amplitudeTimer?.cancel();
                    setDialogState(() {
                      _isRecording = false;
                      _currentLevel = 0.0;
                      _levelPhase = 0.0;
                    });
                    if (path != null) {
                      final file = File(path);
                      if (await file.exists()) {
                        final bytes = await file.readAsBytes();
                        setDialogState(() {
                          soundBytes = bytes;
                        });
                      }
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Optagelse fejlede: $e')),
                  );
                  _recordTimer?.cancel();
                  _amplitudeTimer?.cancel();
                  setDialogState(() {
                    _isRecording = false;
                    _currentLevel = 0.0;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: _isRecording ? Colors.red : null,
                foregroundColor: _isRecording ? Colors.white : null,
              ),
              icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
              label: Text(_isRecording ? 'Stop optagelse' : 'Optag lyd'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.audio,
                  allowMultiple: false,
                  withData: true,
                );
                if (result != null && result.files.single.bytes != null) {
                  setDialogState(() {
                    soundBytes = result.files.single.bytes;
                  });
                }
              },
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload lydfil'),
            ),
      const SizedBox(height: 12),
      // Show text input when AI mode is active
      _showTextToSpeechField
        ? Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Indtast tekst til AI tale:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _textToSpeechController,
                          maxLines: 3,
                          maxLength: 50,
                          onChanged: (text) {
                            // Trigger rebuild when text changes to enable/disable button
                            setDialogState(() {});
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Skriv den tekst du vil konvertere til lyd...',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isGeneratingSpeech ||
                                        _textToSpeechController.text
                                            .trim()
                                            .isEmpty
                                    ? null
                                    : () async {
                                        await _generateSpeechFromText(
                                            setDialogState);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isGeneratingSpeech
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text('Genererer...'),
                                        ],
                                      )
                                    : Text('Generer lyd'),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                setDialogState(() {
                                  _showTextToSpeechField = false;
                                  _textToSpeechController.clear();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Annuller'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      if (_isRecording)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_formatDuration(_recordingDuration)),
                            SizedBox(width: 12),
                            _LevelBar(level: _currentLevel),
                          ],
                        ),
                      if (soundBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_formatDuration(_recordingDuration)),
                              SizedBox(width: 12),
                              _LevelBar(level: _currentLevel),
                            ],
                          ),
                        ),
                      if (soundBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    // Stop and dispose the player, then create a new instance
                                    // This is more reliable on web than trying to reuse the same player
                                    try {
                                      await _player.stop();
                                      await _player.dispose();
                                    } catch (_) {}
                                    
                                    // Create a fresh player instance
                                    final tempPlayer = AudioPlayer();
                                    
                                    try {
                                      // Use data URI - just_audio web should handle this
                                      final uri = Uri.dataFromBytes(
                                        soundBytes!,
                                        mimeType: 'audio/mpeg', // MP3 is most widely supported on web
                                      );
                                      
                                      await tempPlayer.setAudioSource(AudioSource.uri(uri));
                                      await tempPlayer.play();
                                      
                                      // Clean up when done
                                      tempPlayer.playerStateStream.listen((state) {
                                        if (state.processingState == ProcessingState.completed) {
                                          tempPlayer.dispose();
                                        }
                                      });
                                    } catch (e) {
                                      print('Playback error: $e');
                                      tempPlayer.dispose();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Afspilning fejlede. Lydformatet understøttes muligvis ikke i browseren.'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print('Player initialization error: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Kunne ikke initialisere afspiller: $e'),
                                      ),
                                    );
                                  }
                                },
                                child: Text('Afspil lyd'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  try {
                                    _player.stop();
                                  } catch (_) {}
                                  setDialogState(() {
                                    soundBytes = null;
                                    _recordingDuration = Duration.zero;
                                    _currentLevel = 0.0;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  foregroundColor: Colors.red.shade700,
                                ),
                                child: const Text('Slet lyd'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ],
        ),
        const SizedBox(height: 24),
        // Cancel and Confirm buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: soundBytes == null ? null : () {
                // Confirm - keep the changes and close
                // Stop any recording in progress first
                if (_isRecording) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stop optagelsen før du bekræfter'),
                    ),
                  );
                  return;
                }
                
                // Update main state to reflect any changes made in dialog
                setState(() {
                  // soundBytes is already updated by the recording/upload/TTS actions
                  // This setState will trigger _canSubmit() to re-evaluate
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: soundBytes != null ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                foregroundColor: soundBytes != null ? Colors.white : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Bekræft'),
            ),
            ElevatedButton(
              onPressed: () {
                // Cancel - discard any changes and close
                // Stop any recording in progress
                if (_isRecording) {
                  _recordTimer?.cancel();
                  _amplitudeTimer?.cancel();
                  try {
                    (_recorder as dynamic).stop();
                  } catch (_) {}
                }
                
                setDialogState(() {
                  // Reset state
                  _isRecording = false;
                  _showTextToSpeechField = false;
                  _textToSpeechController.clear();
                  _recordingDuration = Duration.zero;
                  _currentLevel = 0.0;
                });
                
                // Note: we don't clear soundBytes on cancel
                // only if user explicitly deleted it
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Annuller'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Future<void> _generateSpeechFromText([StateSetter? setDialogState]) async {
    final text = _textToSpeechController.text.trim();
    if (text.isEmpty) return;

    // Update both dialog state and main popup state
    setState(() {
      _isGeneratingSpeech = true;
    });
    if (setDialogState != null) {
      setDialogState(() {
        _isGeneratingSpeech = true;
      });
    }

    try {
        // generating speech for text (debug log removed)

      // Generate speech using backend API
      final audioData = await _generateSpeechViaBackend(text);

        // audio data received (debug log removed)

      if (audioData != null) {
        // Update main popup state
        setState(() {
          soundBytes =
              audioData; // This is what gets sent when creating artefact
          _showTextToSpeechField = false;
          _textToSpeechController.clear();
        });

        // Update dialog state to hide TTS field and show success
        if (setDialogState != null) {
          setDialogState(() {
            soundBytes = audioData; // Update dialog's view of soundBytes too
            _showTextToSpeechField = false;
            _textToSpeechController.clear();
          });
        }

        _showSuccessMessage(
            'Lyd genereret succesfuldt! Tryk på Bekræft for at gemme.');
        // Don't auto-close the dialog anymore - let user confirm or cancel
      } else {
        _showErrorMessage('Kunne ikke generere lyd fra backend API');
      }
    } catch (e, stackTrace) {
      // exception in _generateSpeechFromText

      String errorMessage = 'Fejl ved generering af lyd';
      if (e.toString().contains('Authentication failed')) {
        errorMessage = 'Du skal logge ind igen for at bruge denne funktion';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Backend serveren kører ikke - kontakt support';
      } else {
        errorMessage = 'Fejl ved generering af lyd: ${e.toString()}';
      }

      _showErrorMessage(errorMessage);
    } finally {
      // Update both states
      setState(() {
        _isGeneratingSpeech = false;
      });
      if (setDialogState != null) {
        setDialogState(() {
          _isGeneratingSpeech = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<Uint8List?> _generateSpeechViaBackend(String text) async {
    try {
      final token = GetIt.instance.get<Token>().value;
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // using token for backend call (debug log removed)

      // Get API base URL from configuration
      final apiProvider = GetIt.instance.get<ApiProvider>();
      final baseUrl = apiProvider.baseUrl;

      // Call backend API to generate speech
      final url = Uri.parse('${baseUrl}Users/Artefacts/generate-speech-simple');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = json.encode({
        'text': text,
        // voiceId removed - backend controls which voice to use
      });

      // making request to backend (debug logs removed)

      final response = await http.post(url, headers: headers, body: body);

      // response received from backend (debug logs removed)

      if (response.statusCode == 200) {
        // success: audio data received
        return response.bodyBytes;
      } else if (response.statusCode == 401) {
        // authentication failed - token might be expired or invalid
        throw Exception('Authentication failed. Please log in again.');
      } else {
        print('Backend API error: ${response.statusCode} ${response.body}');
        throw Exception('Backend API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling backend API: $e');
      rethrow;
    }
  }

  Widget _buildButton(String label, String imageUrl,
      {void Function()? onClick}) {
    return GestureDetector(
      onTap: onClick,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(4, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(imageUrl),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
