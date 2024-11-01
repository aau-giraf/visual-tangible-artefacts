import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
    this.onImageChosen,
  });
  final CameraDescription camera;
  final void Function(Uint8List)? onImageChosen;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  Uint8List? pictureBytes;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.ultraHigh,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Method to take a picture
  Future<Uint8List?> _takePicture() async {
    try {
      await _initializeControllerFuture; // Ensure the camera is initialized

      // Take the picture and save it to the specified path
      XFile picture = await _controller.takePicture();
      return await picture.readAsBytes();
    } catch (e) {
      // Handle errors (e.g., show an error message)
      print('Error capturing picture: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the preview.
          return Stack(
            children: [
              CameraPreview(_controller), // Display the camera preview
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: () async {
                    pictureBytes = await _takePicture();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DisplayPictureScreen(
                          imageBytes: pictureBytes!,
                          onImageChosen: widget.onImageChosen,
                        ),
                      ),
                    );
                  }, // Call _takePicture when pressed
                  child: const Text('Take Picture'),
                ),
              ),
            ],
          );
        } else {
          // Otherwise, display a loading indicator.
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

// A new screen to display the captured image
class DisplayPictureScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final void Function(Uint8List)? onImageChosen;

  const DisplayPictureScreen(
      {super.key, required this.imageBytes, this.onImageChosen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Center(
            child: Image.memory(imageBytes), // Display the captured image
          ),
          ElevatedButton(
            onPressed: () => onImageChosen?.call(imageBytes),
            child: const Text('Brug billede'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Return to the camera screen
            },
            child: const Text('Tag igen'),
          ),
        ],
      ),
    );
  }
}
