import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AIPage extends StatefulWidget {
  final void Function(String imageBytes)? onImageProcessed;

  const AIPage({super.key, this.onImageProcessed});

  @override
  _AIPageState createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String apiKey;
  String? image;
  bool isLoading = false;
  double imageWidth = 150;
  double imageHeight = 150;
  String selectedOption = 'Vælg format';
  bool showError = false;

  @override
  void initState() {
    super.initState();
    loadConfiguration();
  }

  Future<void> loadConfiguration() async {
    final aiSettings = GlobalConfiguration().appConfig['OpenAi'];
    setState(() {
      apiKey = aiSettings['ApiKey'];
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> generateImage() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        image = null;
        isLoading = true;
        showError = false;
      });

      String prompt;
      switch (selectedOption) {
        case 'Piktogram':
          prompt =
              "Hvid baggrund, et enkelt ikon med ingen unødvendige detajler, børne venligt, kontinuert line art ingen mellemrum, ingen tekst, simpelt ikon af " +
                  _controller.text;
          break;
        case 'Realistisk':
          prompt =
              "Realistisk stil, ingen unødvendig detalje i baggrunden, børne venligt, høj-kvalitets billede af " +
                  _controller.text;
          break;
        case 'Tegning':
          prompt =
              "Hvid baggrund, tegne stil, skitsering, sort og hvidt, børne venligt, simpel tegning af " +
                  _controller.text;
          break;
        default:
          prompt = _controller.text;
      }

      var data = {
        "model": "dall-e-3",
        "prompt": prompt,
        "n": 1,
        "size": "1024x1024",
        "response_format": "b64_json",
      };

      try {
        var res = await http.post(
          Uri.parse("https://api.openai.com/v1/images/generations"),
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json"
          },
          body: jsonEncode(data),
        );

        var jsonResponse = jsonDecode(res.body) as Map<String, dynamic>;

        if (jsonResponse.containsKey('data') && jsonResponse['data'] != null) {
          setState(() {
            image = jsonResponse['data'][0]['b64_json'];
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            showError = true;
          });
          print('Unexpected response format: $jsonResponse');
        }
      } catch (e) {
        setState(() {
          isLoading = false;
          showError = true;
        });
        print('Error generating image: $e');
      }
    } else {
      setState(() {
        showError = true;
      });
      print('Prompt is empty or format not chosen');
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var minHeight = screenSize.height * 0.8;
    var minWidth = screenSize.width * 0.6;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Generer billede med AI',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            decoration: BoxDecoration(
                              color:
                                  showError && selectedOption == 'Vælg format'
                                      ? Colors.red
                                      : const Color(0xFFF5F2E7),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.black),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedOption,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedOption = newValue!;
                                    showError = false;
                                  });
                                },
                                items: <String>[
                                  'Vælg format',
                                  'Piktogram',
                                  'Realistisk',
                                  'Tegning'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                  );
                                }).toList(),
                                dropdownColor: Colors.white,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Focus(
                            onFocusChange: (hasFocus) {
                              if (hasFocus) {
                                setState(() {
                                  showError = false;
                                });
                              }
                            },
                            child: TextFormField(
                              controller: _controller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Dette felt er påkrævet';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: 'Skriv her',
                                hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 136, 136, 136)),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedOption == 'Vælg format') {
                        setState(() {
                          showError = true;
                        });
                      } else {
                        generateImage();
                      }
                    },
                    child: const Text(
                      'Generer billede',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(image!),
                                      width: imageWidth,
                                      height: imageHeight,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Text(
                                    'Intet billede genereret',
                                    style: TextStyle(color: Colors.black),
                                  ),
                            const SizedBox(height: 20),
                            image != null
                                ? ElevatedButton(
                                    onPressed: () {
                                      if (widget.onImageProcessed != null) {
                                        widget.onImageProcessed!(image!);
                                      }
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      'Gem billede',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddPicturePage extends StatelessWidget {
  const AddPicturePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(45.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Tilføj billede',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          onPressed: () async {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles();
                            if (result != null) {
                              File file = File(result.files.single.path!);
                            } else {
                              print("Ingen fil valgt");
                            }
                          },
                          tooltip: 'Upload fra galleri',
                          child: const Icon(Icons.add),
                        ),
                        FloatingActionButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  child: Container(
                                    color: Colors.white,
                                    width: 760,
                                    height: 500,
                                    child: const AIPage(),
                                  ),
                                );
                              },
                            );
                          },
                          tooltip: 'Tag ny billede',
                          child: const Icon(Icons.camera_alt),
                        ),
                        FloatingActionButton(
                          onPressed: () {
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
                                    child: const AIPage(),
                                  ),
                                );
                              },
                            );
                          },
                          tooltip: 'Lav med AI',
                          child: const Icon(Icons.android),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
