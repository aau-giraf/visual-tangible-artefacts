import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vta_app/src/controllers/elevenlabs_controller.dart';
import 'package:vta_app/src/ui/widgets/text_to_speech_widget.dart';

/// Example showing how to integrate TextToSpeechWidget into an artefact editing screen
class ArtefactEditingExamplePage extends StatefulWidget {
  final String artefactId;
  final String artefactName;

  const ArtefactEditingExamplePage({
    super.key,
    required this.artefactId,
    required this.artefactName,
  });

  @override
  State<ArtefactEditingExamplePage> createState() => _ArtefactEditingExamplePageState();
}

class _ArtefactEditingExamplePageState extends State<ArtefactEditingExamplePage> {
  bool _hasGeneratedSpeech = false;

  @override
  void initState() {
    super.initState();
    // Initialize ElevenLabs controller when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<ElevenLabsController>();
      await controller.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${widget.artefactName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Existing artefact editing UI would go here
            _buildArtefactInfoSection(),
            
            const SizedBox(height: 24),
            
            // Image upload section (example)
            _buildImageSection(),
            
            const SizedBox(height: 24),
            
            // Text-to-Speech section
            const Text(
              'Add Voice',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate speech from text to add a voice to your artefact.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // The main TextToSpeechWidget integration
            TextToSpeechWidget(
              artefactId: widget.artefactId,
              onSpeechGenerated: (text) {
                setState(() {
                  _hasGeneratedSpeech = true;
                });
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Generated speech: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}"'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'Play',
                      textColor: Colors.white,
                      onPressed: () {
                        // Here you would implement audio playback
                        _playGeneratedAudio();
                      },
                    ),
                  ),
                );
                
                // Optionally refresh the artefact data to show the new sound
                _refreshArtefactData();
              },
              onError: () {
                // Handle error case
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to generate speech. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Save/Cancel buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildArtefactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Artefact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.artefactName,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Tap to add image'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Save the artefact
              _saveArtefact();
            },
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  void _playGeneratedAudio() {
    // Implement audio playback using just_audio or similar
    // This would play the generated audio file
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Play Audio'),
        content: const Text('Audio playback would be implemented here using the just_audio package.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _refreshArtefactData() {
    // Implement refresh logic to reload artefact data
    // This would typically call your artefact service to get updated data
    setState(() {
      _hasGeneratedSpeech = true;
    });
  }

  void _saveArtefact() {
    // Implement save logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Artefact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Artefact saved successfully!'),
            if (_hasGeneratedSpeech) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('Voice generated', style: TextStyle(color: Colors.green)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Example of how to provide the ElevenLabsController in your app
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Your existing providers...
        ChangeNotifierProvider<ElevenLabsController>(
          create: (_) => ElevenLabsController(),
        ),
        // Other providers...
      ],
      child: MaterialApp(
        title: 'VTA App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const ExampleHomePage(),
      ),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VTA Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ArtefactEditingExamplePage(
                  artefactId: 'example-artefact-id',
                  artefactName: 'Example Artefact',
                ),
              ),
            );
          },
          child: const Text('Edit Artefact'),
        ),
      ),
    );
  }
}