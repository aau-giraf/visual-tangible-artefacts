import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const FloatingActionButtonExampleApp());
}

class FloatingActionButtonExampleApp extends StatelessWidget {
  const FloatingActionButtonExampleApp({super.key});

  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const FloatingActionButtonExample(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FloatingActionButtonExample extends StatefulWidget {
  const FloatingActionButtonExample({super.key});

  @override
  State<FloatingActionButtonExample> createState() =>
      _FloatingActionButtonExampleState();
}

class _FloatingActionButtonExampleState
    extends State<FloatingActionButtonExample> {
  bool _isPopupVisible = false; // Track popup visibility
  final AudioPlayer _audioPlayer = AudioPlayer(); // Create an instance of AudioPlayer

  // Function to play the audio file
  void _playAudio(String filePath) async {
    await _audioPlayer.play(AssetSource(filePath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Center(child: Text('This button is for fast talking')),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            top: 70, // Adjust vertical alignment of the popup with the button
            right: _isPopupVisible ? 100 : -250, // Moves the popup to the right of the button
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 150, // Adjust the width of the popup as needed
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        _playAudio('assets/sound/dårligt.mp3');
                      },
                      icon: const Icon(Icons.sick, color: Colors.white),
                      label: const Text('Sick', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.2), // Button background color
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        _playAudio('assets/sound/toilet.mp3');
                      },
                      icon: const Icon(Icons.wc, color: Colors.white),
                      label: const Text('WC', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.2), // Button background color
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        _playAudio('assets/sound/sulten.mp3');
                      },
                      icon: const Icon(Icons.lunch_dining, color: Colors.white),
                      label: const Text('Lunch', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.2), // Button background color
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(50.50),
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isPopupVisible = !_isPopupVisible; // Toggle popup visibility
                  });
                },
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                child: const Icon(Icons.lightbulb_circle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Dispose the AudioPlayer when the widget is destroyed
    super.dispose();
  }
}
