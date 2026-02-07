import 'dart:typed_data';
import 'package:vta_app/src/models/elevenlabs_model.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';

/// Service class for text-to-speech via the VTA backend proxy.
///
/// All TTS requests go through the backend (ArtefactsController), which holds
/// the ElevenLabs API key server-side. The client never sees or stores the key.
class ElevenLabsService {
  final ApiProvider _apiProvider;
  final String _token;

  ElevenLabsService({
    required ApiProvider apiProvider,
    required String token,
  })  : _apiProvider = apiProvider,
        _token = token;

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  /// Generate speech from text via the backend TTS proxy.
  /// Returns raw audio bytes on success.
  Future<ElevenLabsResponse> generateSpeech({
    required String text,
    String? voiceId,
  }) async {
    try {
      final response = await _apiProvider.postAsJson(
        'Artefacts/generate-speech-simple',
        headers: _authHeaders,
        body: {
          'text': text,
          if (voiceId != null) 'voiceId': voiceId,
        },
      );

      if (response != null && response.ok) {
        final Uint8List audioData = response.bodyBytes;
        return ElevenLabsResponse.success(audioData);
      } else {
        final String errorMessage = response != null
            ? 'Failed to generate speech: ${response.statusCode} ${response.reasonPhrase}'
            : 'Failed to connect to TTS backend';
        return ElevenLabsResponse.error(errorMessage, response?.statusCode);
      }
    } catch (e) {
      return ElevenLabsResponse.error(
          'Error generating speech: ${e.toString()}');
    }
  }

  /// Generate speech and save it to an existing artefact on the backend.
  Future<ElevenLabsResponse> generateSpeechAndSave({
    required String text,
    required String artefactId,
    String? voiceId,
  }) async {
    try {
      final response = await _apiProvider.postAsJson(
        'Artefacts/generate-speech-and-save',
        headers: _authHeaders,
        body: {
          'text': text,
          'artefactId': artefactId,
          if (voiceId != null) 'voiceId': voiceId,
        },
      );

      if (response != null && response.ok) {
        // Audio saved server-side; no bytes to return
        return ElevenLabsResponse.success(Uint8List(0));
      } else {
        final String errorMessage = response != null
            ? 'Failed to generate and save speech: ${response.statusCode} ${response.reasonPhrase}'
            : 'Failed to connect to TTS backend';
        return ElevenLabsResponse.error(errorMessage, response?.statusCode);
      }
    } catch (e) {
      return ElevenLabsResponse.error(
          'Error generating speech for artefact: ${e.toString()}');
    }
  }
}