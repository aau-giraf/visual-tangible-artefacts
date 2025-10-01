# ElevenLabs Text-to-Speech Integration

This document describes the ElevenLabs text-to-speech integration that has been added to the VTA (Visual Tangible Artefacts) application.

## Overview

The integration allows users to generate speech audio from text using the ElevenLabs API. This feature enables users to add voice narration to their artefacts by simply typing text instead of recording audio manually.

## Architecture

### Frontend Components

#### 1. Models (`lib/src/models/elevenlabs_model.dart`)
- **ElevenLabsRequest**: Request model for TTS API calls
- **VoiceSettings**: Voice configuration (stability, similarity boost, speaker boost)
- **ElevenLabsResponse**: Response wrapper with success/error handling
- **ElevenLabsVoice**: Voice information from the API
- **ElevenLabsException**: Custom exception for API errors

#### 2. Service (`lib/src/utilities/api/elevenlabs_service.dart`)
- **ElevenLabsService**: Main service class for API communication
- **ElevenLabsVoicePresets**: Predefined voice configurations
- Methods:
  - `generateSpeech()`: Convert text to speech
  - `getVoices()`: Fetch available voices
  - `getUserInfo()`: Get user quota information
  - `validateApiKey()`: Verify API key validity

#### 3. Configuration (`lib/src/utilities/config/elevenlabs_config.dart`)
- **ElevenLabsConfig**: Manages persistent settings using SharedPreferences
- Stores: API key, default voice, voice settings, enabled status
- Methods for getting/setting all configuration values

#### 4. Controller (`lib/src/controllers/elevenlabs_controller.dart`)
- **ElevenLabsController**: ChangeNotifier that manages TTS state
- Handles initialization, voice loading, speech generation
- Integrates with existing artefact system
- Provides error handling and loading states

#### 5. UI Widget (`lib/src/ui/widgets/text_to_speech_widget.dart`)
- **TextToSpeechWidget**: Complete UI component for text-to-speech
- Features:
  - Text input with character counter
  - Voice selection dropdown
  - Quota information display
  - Configuration dialog for API key setup
  - Error handling and success feedback

### Backend Components

#### 1. Service (`Backend/VTA.API/Utilities/ElevenLabsService.cs`)
- **ElevenLabsService**: C# service for ElevenLabs API integration
- Methods:
  - `GenerateSpeechAsync()`: Generate audio from text
  - `GetVoicesAsync()`: Fetch available voices
  - `GetUserInfoAsync()`: Get user information
  - `ValidateApiKeyAsync()`: Verify API key

#### 2. DTOs (`Backend/VTA.API/DTOs/ArtefactDTO.cs`)
- **ArtefactTextToSpeechDTO**: Request model for text-to-speech endpoint
- Contains: ArtefactId, Text, VoiceId, ModelId, voice settings

#### 3. Controller Endpoint (`Backend/VTA.API/Controllers/ArtefactsController.cs`)
- **POST /api/Users/Artefacts/generate-speech**: New endpoint
- Generates speech from text and saves to artefact
- Handles authorization and error cases
- Integrates with existing sound utilities

## Setup Instructions

### Backend Setup

1. **Add ElevenLabs API Key to Configuration**
   ```json
   {
     "ElevenLabs": {
       "ApiKey": "your-elevenlabs-api-key-here"
     }
   }
   ```

2. **Register HTTP Client** (in `Program.cs`)
   ```csharp
   builder.Services.AddHttpClient();
   ```

3. **Install Required NuGet Packages** (if not already present)
   ```xml
   <PackageReference Include="System.Text.Json" Version="8.0.0" />
   ```

### Frontend Setup

1. **Register the Controller** (in your dependency injection setup)
   ```dart
   // Add to your provider setup
   ChangeNotifierProvider<ElevenLabsController>(
     create: (_) => ElevenLabsController(),
   ),
   ```

2. **Initialize the Controller** (in your app initialization)
   ```dart
   final elevenLabsController = context.read<ElevenLabsController>();
   await elevenLabsController.initialize();
   ```

## Usage Examples

### Basic Text-to-Speech Generation

```dart
// In your widget
final elevenLabsController = context.read<ElevenLabsController>();

// Generate speech
final response = await elevenLabsController.generateSpeech(
  text: "Hello, this is a test of text to speech!",
  voiceId: "pNInz6obpgDQGcFmaJgB", // Optional: Adam voice
);

if (response != null && response.success) {
  // Speech generated successfully
  print("Audio data size: ${response.audioData?.length} bytes");
} else {
  // Handle error
  print("Error: ${response?.errorMessage}");
}
```

### Using the Text-to-Speech Widget

```dart
// Add to your artefact editing screen
TextToSpeechWidget(
  artefactId: artefact.artefactId,
  onSpeechGenerated: (text) {
    // Handle successful speech generation
    print("Generated speech for: $text");
    // Refresh artefact data to show new sound
  },
  onError: () {
    // Handle error
    print("Failed to generate speech");
  },
)
```

### Configuration Management

```dart
// Check if ElevenLabs is configured
final isConfigured = await ElevenLabsConfig.isConfigured();

// Set API key
await ElevenLabsConfig.setApiKey("your-api-key");
await ElevenLabsConfig.setEnabled(true);

// Get current settings
final settings = await ElevenLabsConfig.getAllSettings();
```

### Voice Selection

```dart
// Load available voices
final controller = context.read<ElevenLabsController>();
await controller.loadVoices();

// Use a specific voice
final response = await controller.generateSpeech(
  text: "Hello with a specific voice!",
  voiceId: "21m00Tcm4TlvDq8ikWAM", // Rachel voice
);
```

## API Integration Details

### ElevenLabs API Endpoints Used

1. **POST /v1/text-to-speech/{voice_id}**
   - Generates audio from text
   - Returns MP3 audio data

2. **GET /v1/voices**
   - Lists available voices
   - Returns voice metadata

3. **GET /v1/user**
   - Gets user information and quota
   - Used for quota checking

### Request Format

```json
{
  "text": "Text to convert to speech",
  "model_id": "eleven_monolingual_v1",
  "voice_settings": {
    "stability": 0.5,
    "similarity_boost": 0.75,
    "use_speaker_boost": true
  }
}
```

### Response Handling

- Success: Returns binary MP3 audio data
- Error: Returns JSON error message
- Rate limiting: Handled with exponential backoff (can be implemented)

## Configuration Options

### Voice Settings

- **Stability** (0.0 - 1.0): Controls voice consistency
  - Low (0.0-0.3): More expressive, less consistent
  - Medium (0.4-0.6): Balanced
  - High (0.7-1.0): More consistent, less expressive

- **Similarity Boost** (0.0 - 1.0): Controls voice similarity
  - Low: More creative interpretation
  - High: Closer to original voice

- **Speaker Boost**: Enhances voice clarity

### Popular Voice IDs

```dart
static const Map<String, String> popularVoices = {
  'Adam': 'pNInz6obpgDQGcFmaJgB',
  'Antoni': 'ErXwobaYiN019PkySvjV',
  'Arnold': 'VR6AewLTigWG4xSOukaG',
  'Bella': 'EXAVITQu4vr4xnSDxMaL',
  'Domi': 'AZnzlk1XvdvUeBnXmlld',
  'Josh': 'TxGEqnHWrfWFTfGW9XjX',
  'Rachel': '21m00Tcm4TlvDq8ikWAM',
  'Sam': 'yoZ06aMxZJJ28mfd3POQ',
};
```

## Error Handling

### Common Error Scenarios

1. **Invalid API Key**
   - Status: 401 Unauthorized
   - Solution: Verify API key in configuration

2. **Quota Exceeded**
   - Status: 429 Too Many Requests
   - Solution: Wait for quota reset or upgrade plan

3. **Text Too Long**
   - Status: 400 Bad Request
   - Solution: Limit text length (recommended: 1000 characters)

4. **Invalid Voice ID**
   - Status: 404 Not Found
   - Solution: Use valid voice ID from voices list

### Error Handling Pattern

```dart
try {
  final response = await elevenLabsService.generateSpeech(text: text);
  if (response.success) {
    // Handle success
  } else {
    // Handle API error
    showError(response.errorMessage ?? 'Unknown error');
  }
} on ElevenLabsException catch (e) {
  // Handle specific ElevenLabs errors
  showError(e.message);
} catch (e) {
  // Handle general errors
  showError('An unexpected error occurred: $e');
}
```

## Security Considerations

1. **API Key Storage**
   - Stored securely using SharedPreferences
   - Not exposed in client-side code
   - Backend configuration should use environment variables

2. **User Authorization**
   - All endpoints require JWT authentication
   - Users can only generate speech for their own artefacts

3. **Input Validation**
   - Text length limits to prevent abuse
   - Sanitization of user input
   - Rate limiting (can be implemented)

## Performance Considerations

1. **Audio File Size**
   - MP3 format for optimal size/quality balance
   - Consider compression for storage

2. **API Response Time**
   - ElevenLabs typically responds in 1-3 seconds
   - Implement loading states for user feedback

3. **Quota Management**
   - Monitor character usage
   - Display quota information to users
   - Implement warnings for low quota

## Future Enhancements

1. **Voice Cloning**
   - Allow users to clone their own voices
   - Custom voice training integration

2. **Audio Processing**
   - Audio effects and filters
   - Speed and pitch adjustment

3. **Batch Processing**
   - Generate speech for multiple artefacts
   - Background processing

4. **Caching**
   - Cache generated audio for repeated text
   - Reduce API calls and costs

5. **Offline Support**
   - Local TTS fallback
   - Sync when online

## Troubleshooting

### Common Issues

1. **"ElevenLabs service not configured"**
   - Ensure API key is set in configuration
   - Verify ElevenLabs is enabled in settings

2. **"Failed to generate speech"**
   - Check API key validity
   - Verify internet connection
   - Check ElevenLabs service status

3. **"Not enough quota"**
   - Check ElevenLabs account quota
   - Reduce text length
   - Wait for quota reset

### Debug Information

```dart
// Get debug information
final controller = context.read<ElevenLabsController>();
print("Is configured: ${controller.isConfigured}");
print("Last error: ${controller.lastError}");
print("Available voices: ${controller.availableVoices?.length}");
print("User info: ${controller.userInfo}");
```

## Testing

### Unit Tests (Recommended)

```dart
// Test voice settings
test('VoiceSettings creates correct JSON', () {
  final settings = VoiceSettings(stability: 0.8, similarityBoost: 0.6);
  final json = settings.toJson();
  
  expect(json['stability'], equals(0.8));
  expect(json['similarity_boost'], equals(0.6));
});

// Test API response handling
test('ElevenLabsResponse handles success correctly', () {
  final audioData = Uint8List.fromList([1, 2, 3, 4]);
  final response = ElevenLabsResponse.success(audioData);
  
  expect(response.success, isTrue);
  expect(response.audioData, equals(audioData));
});
```

### Integration Tests

1. Test API key validation
2. Test speech generation end-to-end
3. Test error handling scenarios
4. Test quota checking functionality

This integration provides a solid foundation for text-to-speech functionality in the VTA application, with proper error handling, configuration management, and user experience considerations.