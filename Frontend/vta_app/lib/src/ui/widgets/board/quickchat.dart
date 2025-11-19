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
    double screenWidth = MediaQuery.of(context).size.width;
    double fabSize = screenWidth > 600 ? 60.0 : 48.0;
    double iconSize = screenWidth > 600 ? 30.0 : 24.0;
    double popupTop = screenWidth > 600 ? 30.0 : 15.0;
    double popupRight = screenWidth > 600 ? 100.0 : 70.0;
    double popupMenu = screenWidth > 600 ? 150.0 : 150.0;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          top: popupTop,
          right: _isPopupVisible ? popupRight : -250,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: popupMenu,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(201, 244, 67, 54),
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
                    label: const Text(
                      'Har det ikke godt',
                      style: TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _playAudio('assets/sound/toilet.mp3'),
                    icon: const Icon(Icons.wc, color: Colors.white),
                    label: const Text('Toilet',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                  alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _playAudio('assets/sound/sulten.mp3'),
                    icon: const Icon(Icons.lunch_dining, color: Colors.white),
                    label: const Text('Sulten',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                  alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: fabSize,
            height: fabSize,
            child: Padding(
              padding: EdgeInsets.only(top: screenWidth > 600 ? 15 : 5, right: screenWidth > 600 ? 30 : 15),
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isPopupVisible = !_isPopupVisible;
                  });
                },
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                child: Icon(Icons.lightbulb_circle, size: iconSize),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
