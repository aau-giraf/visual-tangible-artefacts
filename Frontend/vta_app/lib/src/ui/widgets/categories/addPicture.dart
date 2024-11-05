import 'dart:io';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class AIPage extends StatefulWidget {
  final void Function(String imageBytes)? onImageProcessed;

  const AIPage({super.key, this.onImageProcessed});

  @override
  _AIPageState createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final aiSettings = GlobalConfiguration().appConfig['OpenAi'];
  final TextEditingController _controller = TextEditingController();
  late String apiKey;
  String? image;
  bool isLoading = false;
  double imageWidth = 150;
  double imageHeight = 150;

  @override
  void initState() {
    super.initState();
    apiKey = aiSettings['ApiKey'];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> generateImage() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        image = null;
        isLoading = true;
      });

      var data = {
        "model": "dall-e-3",
        "prompt":
            "White background, a single icon with no unnecessary detail, child-friendly, continuous line art no spaces, no text, simple icon of " +
                _controller.text,
        "n": 1,
        "size": "1024x1024",
        "response_format": "b64_json",
      };

      var res = await http.post(
        Uri.parse("https://api.openai.com/v1/images/generations"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json"
        },
        body: jsonEncode(data),
      );

      var jsonResponse = jsonDecode(res.body) as Map<String, dynamic>;

      setState(() {
        image = jsonResponse['data'][0]['b64_json'];
        isLoading = false;
      });
    } else {
      print('Prompt is empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2E7),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor:
            const Color(0xFFF5F2E7), // Use a contrasting color for the app bar
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(50.0),
          width: MediaQuery.of(context).size.width * 0.9, // Responsive width
          decoration: BoxDecoration(
            color: const Color(0xFFF5F2E7), // Main background color
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Skriv her',
                  hintStyle:
                      TextStyle(color: Color.fromARGB(255, 136, 136, 136)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.black), // Black underline when focused
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color:
                            Colors.black), // Black underline when not focused
                  ),
                ),
                style: const TextStyle(color: Colors.black), // Black input text
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: generateImage,
                child: const Text(
                  'Generer billede',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator() // Display loading icon
                  : Column(
                      children: [
                        image != null
                            ? Image.memory(base64Decode(image!),
                                width: imageWidth, height: imageHeight)
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
                                  'Brug billede',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : Container(), // Empty container if no image is generated
                      ],
                    ),
            ],
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
      backgroundColor: Colors.transparent, // Make the background transparent
      body: Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color:
                Colors.black.withOpacity(0.5), // Grey out the rest of the app
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.8, // Set width based on screen size
              padding: const EdgeInsets.all(45.0), // Reduced padding
              decoration: BoxDecoration(
                color: const Color(
                    0xFFF5F2E7), // Set the background color of the container
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3), // Changes position of shadow
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      'Tilføj billede',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 255), // Add some spacing
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
                            print("No file selected");
                          } // Button 1 action
                        },
                        tooltip: 'Upload fra galleri',
                        child: const Icon(Icons.add),
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          // Button 2 action
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
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Container(
                                  color: Colors.white,
                                  width: 760, // Set your desired width here
                                  height: 500, // Set your desired height here
                                  child: const AIPage(), // The AIPage widget
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
        ],
      ),
    );
  }
}
