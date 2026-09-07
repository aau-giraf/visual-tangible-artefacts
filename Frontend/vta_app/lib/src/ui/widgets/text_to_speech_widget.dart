import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vta_app/src/controllers/elevenlabs_controller.dart';
import 'package:vta_app/src/utilities/config/elevenlabs_config.dart';
import 'package:vta_app/src/utilities/config/voice_config_validator.dart';

/// Widget for text-to-speech input and generation.
///
/// Uses the backend TTS proxy — no client-side API key required.
class TextToSpeechWidget extends StatefulWidget {
  final String artefactId;
  final Function(String)? onSpeechGenerated;
  final VoidCallback? onError;

  const TextToSpeechWidget({
    super.key,
    required this.artefactId,
    this.onSpeechGenerated,
    this.onError,
  });

  @override
  State<TextToSpeechWidget> createState() => _TextToSpeechWidgetState();
}

class _TextToSpeechWidgetState extends State<TextToSpeechWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedVoiceId = ElevenLabsConfig.defaultVoiceId;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadVoicePreference();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadVoicePreference() async {
    final voiceId = await ElevenLabsConfig.getDefaultVoiceId();
    if (mounted) {
      setState(() {
        _selectedVoiceId = voiceId;
      });
    }
  }

  Future<void> _generateSpeech() async {
    if (_textController.text.trim().isEmpty) {
      _showError('Please enter some text to convert to speech');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final controller = context.read<ElevenLabsController>();

      final audioData = await controller.generateSpeechForArtefact(
        text: _textController.text,
        artefactId: widget.artefactId,
        voiceId: _selectedVoiceId,
      );

      if (audioData != null) {
        widget.onSpeechGenerated?.call(_textController.text);
        _showSuccess('Speech generated successfully!');
        _textController.clear();
      } else {
        _showError(controller.lastError ?? 'Failed to generate speech');
        widget.onError?.call();
      }
    } catch (e) {
      _showError('An error occurred: ${e.toString()}');
      widget.onError?.call();
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElevenLabsController>(
      builder: (context, controller, child) {
        if (!controller.isConfigured) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Text-to-Speech Unavailable',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please log in to use text-to-speech.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final voiceOptions = VoiceConfigValidator.getVoiceOptions();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.record_voice_over),
                    const SizedBox(width: 8),
                    const Text(
                      'Generate Speech',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (controller.isLoading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Voice selection from local config
                DropdownButtonFormField<String>(
                  initialValue: _selectedVoiceId,
                  decoration: const InputDecoration(
                    labelText: 'Voice',
                    border: OutlineInputBorder(),
                  ),
                  items: voiceOptions
                      .map((v) => DropdownMenuItem<String>(
                            value: v['id'],
                            child: Text(v['label']!),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _selectedVoiceId = value;
                      });
                      await ElevenLabsConfig.setDefaultVoiceId(value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Text input
                TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Enter text to convert to speech',
                    hintText: 'Type the text you want to hear...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Character count
                Text(
                  '${_textController.text.length} characters',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // Generate button
                ElevatedButton.icon(
                  onPressed: _isGenerating || _textController.text.trim().isEmpty
                      ? null
                      : _generateSpeech,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                      _isGenerating ? 'Generating...' : 'Generate Speech'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
