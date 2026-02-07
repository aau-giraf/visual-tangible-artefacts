import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vta_app/src/models/elevenlabs_model.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/utilities/api/elevenlabs_service.dart';
import 'package:vta_app/src/utilities/config/elevenlabs_config.dart';

/// Controller for managing ElevenLabs TTS functionality for artefacts.
///
/// The ElevenLabs API key lives server-side. This controller only proxies
/// requests through the backend and manages local voice-ID preferences.
class ElevenLabsController extends ChangeNotifier {
  ElevenLabsService? _service;
  bool _isLoading = false;
  String? _lastError;

  // Getters
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isConfigured => _service != null;

  /// Initialise the service with an authenticated [ApiProvider] and JWT [token].
  void initialize(ApiProvider apiProvider, String token) {
    _service = ElevenLabsService(apiProvider: apiProvider, token: token);
    _clearError();
    notifyListeners();
  }

  /// Generate speech from text and return audio bytes.
  Future<ElevenLabsResponse?> generateSpeech({
    required String text,
    String? voiceId,
  }) async {
    if (_service == null) {
      return ElevenLabsResponse.error('ElevenLabs service not initialised');
    }

    if (text.trim().isEmpty) {
      return ElevenLabsResponse.error('Text cannot be empty');
    }

    try {
      _setLoading(true);
      _clearError();

      final String effectiveVoiceId =
          voiceId ?? await ElevenLabsConfig.getDefaultVoiceId();

      final response = await _service!.generateSpeech(
        text: text,
        voiceId: effectiveVoiceId,
      );

      if (!response.success) {
        _setError(response.errorMessage ?? 'Unknown error occurred');
      }

      return response;
    } catch (e) {
      final errorMessage = 'Failed to generate speech: ${e.toString()}';
      _setError(errorMessage);
      return ElevenLabsResponse.error(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Generate speech for an artefact, saving the audio server-side.
  Future<Uint8List?> generateSpeechForArtefact({
    required String text,
    required String artefactId,
    String? voiceId,
  }) async {
    if (_service == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final String effectiveVoiceId =
          voiceId ?? await ElevenLabsConfig.getDefaultVoiceId();

      final response = await _service!.generateSpeechAndSave(
        text: text,
        artefactId: artefactId,
        voiceId: effectiveVoiceId,
      );

      if (!response.success) {
        _setError(response.errorMessage ?? 'Unknown error occurred');
        return null;
      }

      return response.audioData;
    } catch (e) {
      _setError('Failed to generate speech: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Private helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
  }
}