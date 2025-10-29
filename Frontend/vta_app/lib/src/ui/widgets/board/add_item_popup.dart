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

class AddItemPopup extends StatefulWidget {
  Category? category;
  final bool isCategory;
  final void Function(String name, Uint8List? imageBytes) onSubmit;
  final String title;

  AddItemPopup({
    super.key,
    required this.isCategory,
    required this.onSubmit,
    this.category,
    this.title = 'Tilføj ',
  });

  @override
  State<AddItemPopup> createState() => _AddItemPopupState();
}

class _AddItemPopupState extends State<AddItemPopup> {
  Uint8List? imageBytes;
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
    var minHeight = screenSize.height * 0.75;
    var minWidth = screenSize.width * 0.55;

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
            padding: const EdgeInsets.all(8.0),
            child: _buildForm(minWidth, formKey, nameController),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(double minWidth, GlobalKey<FormState> formKey,
      TextEditingController nameController) {
    
    final titleFontSize = (minWidth * 0.05).clamp(16.0, 28.0);
    final imageDisplaySize = (minWidth * 0.3).clamp(80.0, 150.0);

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title + (widget.isCategory ? 'Kategori' : 'Artefakt'),
            style: TextStyle(
              color: Colors.black,
              fontSize: titleFontSize,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
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
                SizedBox(height: 8),
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      imageBytes!,
                      width: imageDisplaySize,
                      height: imageDisplaySize,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Image.asset(
                    'assets/images/no_image.png',
                    width: imageDisplaySize,
                    height: imageDisplaySize,
                  ),
              ],
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                    'Tag nyt billede', 'assets/images/camera_icon_filled.png',
                    scaleBase: minWidth,
                    onClick: _onTakePictureButtonPressed),
                SizedBox(width: 8),
                _buildButton('Upload', 'assets/images/folder_icon.png',
                    scaleBase: minWidth, onClick: () async {
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
                SizedBox(width: 8),
                _buildButton('Lav med AI', 'assets/images/ai_file.png',
                    scaleBase: minWidth, onClick: () {
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
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: imageBytes != null
                      ? Color(0xFF4CAF50)
                      : Color(0xFFBADFB5),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    widget.onSubmit(nameController.text, imageBytes);
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
          SizedBox(height: 8),
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

  Widget _buildButton(String label, String imageUrl,
      {void Function()? onClick, required double scaleBase}) {
    
    final idealButtonSize = scaleBase * 0.22;
    final idealIconSize = scaleBase * 0.11;
    final idealSpacing = scaleBase * 0.015;
    final idealFontSize = scaleBase * 0.03;

    
    final buttonSize = idealButtonSize.clamp(60.0, 100.0);
    final iconSize = idealIconSize.clamp(30.0, 50.0);
    final spacing = idealSpacing.clamp(2.0, 6.0);
    final fontSize = idealFontSize.clamp(10.0, 14.0);


    return GestureDetector(
      onTap: onClick,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
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
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(imageUrl),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: fontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
