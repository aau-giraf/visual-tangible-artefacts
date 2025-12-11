import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class QuickChatButton extends StatefulWidget {
  const QuickChatButton({super.key});

  @override
  State<QuickChatButton> createState() => _QuickChatButtonState();
}

class _QuickChatButtonState extends State<QuickChatButton> {
  bool _isPopupVisible = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Visual feedback tracking
  IconData? _pressedIcon;

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

  // Quick Icon builder WITH visual feedback
  Widget _quickIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressedIcon = icon); // Shrink effect
      },
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 120));
        setState(() => _pressedIcon = null); // Restore
        onTap();
      },
      onTapCancel: () {
        setState(() => _pressedIcon = null);
      },
      child: AnimatedScale(
        scale: _pressedIcon == icon ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 213, 0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 40,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fabSize = screenWidth > 600 ? 60.0 : 48.0;
    double popupTop = screenWidth > 600 ? 30.0 : 15.0;
    double popupRight = screenWidth > 600 ? 100.0 : 70.0;

    return Stack(
      children: [
        // POPUP
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          top: popupTop,
          right: _isPopupVisible ? popupRight : -250,
          child: Material(
            color: const Color.fromARGB(0, 0, 0, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 232, 200, 38),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _quickIcon(
                    icon: Icons.wc,
                    onTap: () => _playAudio('assets/sound/toilet.mp3'),
                  ),
                  const SizedBox(width: 8),
                  _quickIcon(
                    icon: Icons.lunch_dining,
                    onTap: () => _playAudio('assets/sound/sulten.mp3'),
                  ),
                  const SizedBox(width: 8),
                  _quickIcon(
                    icon: Icons.sick,
                    onTap: () => _playAudio('assets/sound/dårligt.mp3'),
                  ),
                ],
              ),
            ),
          ),
        ),
        // MAIN "!" BUTTON
        Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: fabSize,
            height: fabSize,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, right: 20),
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isPopupVisible = !_isPopupVisible;
                  });
                },
                foregroundColor: Colors.black,
                backgroundColor: const Color.fromARGB(255, 232, 201, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.priority_high),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
