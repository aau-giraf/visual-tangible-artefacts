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
  //final aiSettings = GlobalConfiguration().appConfig['OpenAi'];
  final TextEditingController _controller = TextEditingController();
  late String apiKey;
  String? image;
  bool isLoading = false;
  double imageWidth = 150;
  double imageHeight = 150;
  String selectedOption = 'Vælg format'; // Default selected option
  bool showError =
      false; // Track if the generate button was pressed without a valid selection

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
    if (_controller.text.isNotEmpty) {
      setState(() {
        image = null;
        isLoading = true;
        showError = false; // Reset the error when a valid option is selected
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
              "Realistisk stil, ingen unødvendig detalje i baggrunden, børne venligt, ingen tekst billede af " +
                  _controller.text;
          break;
        case 'Tegning':
          prompt =
              "Hvid baggrund, tegne stil, skitsering, sort og hvidt, børne venligt, simpel tegning, ingen text billede af " +
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
      setState(() {
        showError = true; // Show error if the prompt is empty
      });
      print('Prompt is empty or format not chosen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make the background transparent
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F2E7), // Use a contrasting color for the app bar
        iconTheme: const IconThemeData(
            color: Colors.black), // Set the back arrow color to black
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
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: showError && selectedOption == 'Vælg format'
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
                                showError =
                                    false; // Reset the error when a valid option is selected
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
                                  style: const TextStyle(
                                      color: Colors.black), // Black text
                                ),
                              );
                            }).toList(),
                            dropdownColor: Colors
                                .white, // Set the background color of the dropdown menu to white
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black, // Black arrow icon
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                        width:
                            15), // Add some spacing between the dropdown and the text field
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Skriv her',
                          hintStyle: TextStyle(
                              color: Color.fromARGB(255, 136, 136, 136)),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors
                                    .black), // Black underline when focused
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors
                                    .black), // Black underline when not focused
                          ),
                        ),
                        style: const TextStyle(
                            color: Colors.black), // Black input text
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
                      showError =
                          true; // Show error if no valid option is selected
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
                                  'Gem billede',
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
                color:
                    Colors.white, // Set the background color of the container
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
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
                    SizedBox(height: 20), // Add some spacing
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
                            } // Button 1 action
                          },
                          tooltip: 'Upload fra galleri',
                          child: Icon(Icons.add),
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
                                    // Button 2 action
                                  ),
                                );
                              },
                            );
                          },
                          tooltip: 'Tag ny billede',
                          child: Icon(Icons.camera_alt),
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
          ),
        ],
      ),
    );
  }
}
