import 'dart:convert';
import 'dart:io';
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
import 'package:record/record.dart';
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

class _AddItemPopupState extends State<AddItemPopup> {
  Uint8List? imageBytes;
  Uint8List? soundBytes;
  bool _isRecording = false;
  // Record is implemented via platform interface; the analyzer may report
  // instantiate_abstract_class for the package's Record type. Suppress it
  // and use dynamic calls for methods to avoid static errors.
  // ignore: instantiate_abstract_class
  final Record _recorder = Record();
  final AudioPlayer _player = AudioPlayer();
  final formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

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
  }

  @override
  void dispose() {
    nameController.dispose();
    try {
      _player.dispose();
    } catch (_) {}
    try {
      // Best-effort stop recorder on dispose
      (_recorder as dynamic).stop();
    } catch (_) {}
    super.dispose();
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
                _buildButton('Tilføj lyd', 'assets/images/sound_icon.png', onClick: () {
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
                  backgroundColor: Color(0xFFBADFB5),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    widget.onSubmit(nameController.text, imageBytes, soundBytes);
                    Navigator.of(context).pop();
                  }
                },
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
        Text('Tilføj lyd', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
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
            Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (!_isRecording) {
                        bool hasPermission = await (_recorder as dynamic).hasPermission();
                        if (!hasPermission) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mangler mikrofon tilladelse')));
                          return;
                        }
                        final tmpPath = '${Directory.systemTemp.path}/vta_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
                        await (_recorder as dynamic).start(path: tmpPath, encoder: AudioEncoder.aacLc);
                        setState(() {
                          _isRecording = true;
                        });
                      } else {
                        final path = await (_recorder as dynamic).stop();
                        setState(() {
                          _isRecording = false;
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
                        // keep dialog open so user can preview or re-record
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Optagelse fejlede: $e')));
                    }
                  },
                  child: Text(_isRecording ? 'Stop optagelse' : 'Start optagelse'),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: soundBytes == null
                      ? null
                      : () async {
                          try {
                            // Use data URI for in-memory bytes
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
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generer lyd med AI - ikke implementeret')));
              },
              child: Text('Generer lyd (AI)'),
            ),
          ],
        )
      ],
    );
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
