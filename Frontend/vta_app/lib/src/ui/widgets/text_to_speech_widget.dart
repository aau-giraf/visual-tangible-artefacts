import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vta_app/src/controllers/elevenlabs_controller.dart';

/// Widget for text-to-speech input and generation
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
  String? _selectedVoiceId;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVoicesIfNeeded();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadVoicesIfNeeded() async {
    final controller = context.read<ElevenLabsController>();
    if (controller.isConfigured && controller.availableVoices == null) {
      await controller.loadVoices();
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
      
      // Check quota if available
      if (controller.userInfo != null) {
        if (!controller.hasQuotaForText(_textController.text)) {
          _showError('Not enough quota remaining for this text');
          return;
        }
      }

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
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.settings,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Text-to-Speech Not Configured',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please configure ElevenLabs API key in settings to use text-to-speech functionality.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to settings or show configuration dialog
                      _showConfigurationDialog(context, controller);
                    },
                    child: const Text('Configure'),
                  ),
                ],
              ),
            ),
          );
        }

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
                
                // Voice selection dropdown
                if (controller.availableVoices != null && controller.availableVoices!.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVoiceId,
                    decoration: const InputDecoration(
                      labelText: 'Voice',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Default Voice'),
                      ),
                      ...controller.availableVoices!.map((voice) {
                        return DropdownMenuItem<String>(
                          value: voice.voiceId,
                          child: Text('${voice.name}${voice.category != null ? ' (${voice.category})' : ''}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedVoiceId = value;
                      });
                    },
                  ),
                
                if (controller.availableVoices != null && controller.availableVoices!.isNotEmpty)
                  const SizedBox(height: 16),

                // Text input
                TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 3,
                  maxLength: 1000, // Reasonable limit for TTS
                  decoration: const InputDecoration(
                    labelText: 'Enter text to convert to speech',
                    hintText: 'Type the text you want to hear...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (text) {
                    setState(() {}); // Rebuild to update button state
                  },
                ),
                const SizedBox(height: 12),

                // Character count and quota information
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_textController.text.length} characters',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (controller.userInfo != null) ...[
                      Text(
                        'Quota: ${controller.getQuotaUsed()}/${controller.getQuotaLimit()}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
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
                  label: Text(_isGenerating ? 'Generating...' : 'Generate Speech'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfigurationDialog(BuildContext context, ElevenLabsController controller) {
    final TextEditingController apiKeyController = TextEditingController();
    bool isConfiguring = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Configure ElevenLabs'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your ElevenLabs API key to enable text-to-speech functionality.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !isConfiguring,
              ),
              if (isConfiguring) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isConfiguring ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isConfiguring
                  ? null
                  : () async {
                      if (apiKeyController.text.trim().isEmpty) {
                        return;
                      }

                      setState(() {
                        isConfiguring = true;
                      });

                      final success = await controller.configure(apiKeyController.text.trim());
                      
                      if (success) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ElevenLabs configured successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        setState(() {
                          isConfiguring = false;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(controller.lastError ?? 'Configuration failed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: Text(isConfiguring ? 'Configuring...' : 'Configure'),
            ),
          ],
        ),
      ),
    );
  }
}