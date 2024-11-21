import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class QuickChatButton extends StatefulWidget {
  const QuickChatButton({super.key});

  @override
  State<QuickChatButton> createState() => _FloatingActionButtonExampleState();
}

class _FloatingActionButtonExampleState extends State<QuickChatButton> {
  bool _isPopupVisible = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String assetPath) async {
    try {
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          top: 70,
          right: _isPopupVisible ? 100 : -250,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 150,
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
                    onPressed: () => _playAudio('assets/sound/dårligt.mp3'),
                    icon: const Icon(Icons.sick, color: Colors.white),
                    label: const Text('Har det ikke godt',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _playAudio('assets/sound/toilet.mp3'),
                    icon: const Icon(Icons.wc, color: Colors.white),
                    label: const Text('Toilet',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _playAudio('assets/sound/sulten.mp3'),
                    icon: const Icon(Icons.lunch_dining, color: Colors.white),
                    label: const Text('Sulten',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.2),
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
                  _isPopupVisible = !_isPopupVisible;
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
    );
  }
}
