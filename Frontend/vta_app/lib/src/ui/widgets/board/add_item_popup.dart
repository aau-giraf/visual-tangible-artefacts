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
import 'package:record/record.dart' show AudioEncoder;
import '../../../utilities/audio/recorder.dart';
import 'package:just_audio/just_audio.dart';

class AddItemPopup extends StatefulWidget {
  Category? category;
  final bool isCategory;
  final void Function(String name, Uint8List? imageBytes, Uint8List? soundBytes) onSubmit;
  final String title;

  AddItemPopup({
    super.key,
    required this.isCategory,
    required this.onSubmit,
    this.category,
    this.title = 'Tilføj kategori',
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
  dynamic? _recorder;
  final AudioPlayer _player = AudioPlayer();
  final formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  // Recording UI state
  Duration _recordingDuration = Duration.zero;
  Timer? _recordTimer;
  Timer? _amplitudeTimer;
  double _currentLevel = 0.0; // 0.0 - 1.0
  bool _amplitudeSupported = true;
  double _levelPhase = 0.0;

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
      return hasName && hasImage && hasSound;
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
          color: Color(0xFFF5F2E7),
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
                    'Tag nyt billede', 'assets/images/camera_icon_filled.png',
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
                  _buildButton('Tilføj lyd', 'assets/images/speaker_icon.png', onClick: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            color: Colors.white,
                            width: 560,
                            height: 300,
                            padding: EdgeInsets.all(16),
                            child: _buildSoundModal(),
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
                  backgroundColor: _canSubmit() ? Color(0xFF2E7D32) : Color(0xFFBADFB5),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _canSubmit()
                    ? () {
                        if (formKey.currentState!.validate()) {
                          // Categories shouldn't include soundBytes
                          final Uint8List? sendSound = widget.isCategory ? null : soundBytes;
                          widget.onSubmit(nameController.text, imageBytes, sendSound);
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

  Widget _buildSoundModal() {
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
            Text('Tilføj lyd til artefakt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(height: 12),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    var result = await FilePicker.platform.pickFiles(
                        type: FileType.audio, allowMultiple: false, withData: true);
                    if (result != null && result.files.single.bytes != null) {
                      setState(() {
                        soundBytes = result.files.single.bytes;
                      });
                      // keep the dialog open so user can preview
                    }
                  },
                  child: Text('Upload lyd'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // recording handler (same as before)
                      try {
                      if (_recorder == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Optager ikke tilgængelig på denne platform')));
                        return;
                      }

                      if (!_isRecording) {
                        debugPrint('Permission 1');
                        final bool hasPermission = await (_recorder as dynamic).hasPermission();
                        if (!hasPermission) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Mangler mikrofon tilladelse')));
                          return;
                        }
                        debugPrint('Permission 2');
                        setState(() {
                          _isRecording = true;
                          _recordingDuration = Duration.zero;
                          _currentLevel = 0.0;
                          _amplitudeSupported = true;
                          _levelPhase = 0.0;
                        });
                        debugPrint('Set state true');
                        final tmpPath = '${Directory.systemTemp.path}/vta_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
                        debugPrint('TEMP PATH: $tmpPath');
                        await (_recorder as dynamic).start(path: tmpPath, encoder: AudioEncoder.aacLc);
                        debugPrint('Set temp path');
                        _recordTimer?.cancel();
                        _recordTimer = Timer.periodic(Duration(seconds: 1), (_) {
                          setState(() {
                            _recordingDuration = _recordingDuration + Duration(seconds: 1);
                          });
                        });
                        _amplitudeTimer?.cancel();
                        _amplitudeTimer = Timer.periodic(Duration(milliseconds: 200), (_) async {
                          try {
                            final amp = await (_recorder as dynamic).getAmplitude();
                            double level = 0.0;
                            if (amp != null) {
                              if (amp is Map && amp.containsKey('current')) {
                                level = (amp['current'] as num).toDouble();
                              } else if (amp is num) {
                                level = (amp as num).toDouble();
                              }
                            }
                            final normalized = (level <= 0) ? 0.0 : (level / 32768.0).clamp(0.0, 1.0);
                            setState(() {
                              _currentLevel = normalized;
                            });
                          } catch (_) {
                            _amplitudeSupported = false;
                            _levelPhase += 0.3;
                            final pulse = (0.3 + 0.7 * (0.5 + 0.5 * (sin(_levelPhase))).abs()).clamp(0.0, 1.0);
                            setState(() {
                              _currentLevel = pulse;
                            });
                          }
                        });
                      } else {
                        final path = await (_recorder as dynamic).stop();
                        _recordTimer?.cancel();
                        _amplitudeTimer?.cancel();
                        setState(() {
                          _isRecording = false;
                          _currentLevel = 0.0;
                          _amplitudeSupported = true;
                          _levelPhase = 0.0;
                        });
                        if (path != null) {
                          final file = File(path);
                          if (await file.exists()) {
                            final bytes = await file.readAsBytes();
                            setState(() {
                              soundBytes = bytes;
                            });
                          }
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Optagelse fejlede: $e')));
                      _recordTimer?.cancel();
                      _amplitudeTimer?.cancel();
                      setState(() {
                        _isRecording = false;
                        _currentLevel = 0.0;
                      });
                    }
                  },
                  child: Text(_isRecording ? 'Stop optagelse' : 'Start optagelse'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generer lyd med AI - ikke implementeret')));
                  },
                  child: Text('Generer lyd (AI)'),
                ),
              ],
            ),
            SizedBox(height: 12),
            // timer, level bar and play button below the main buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_formatDuration(_recordingDuration)),
                SizedBox(width: 12),
                _LevelBar(level: _currentLevel),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: soundBytes == null
                      ? null
                      : () async {
                          try {
                            final uri = Uri.dataFromBytes(soundBytes!, mimeType: 'audio/m4a');
                            await _player.setAudioSource(AudioSource.uri(uri));
                            _player.play();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Afspilning fejlede: $e')));
                          }
                        },
                  child: Text('Afspil lyd'),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
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
