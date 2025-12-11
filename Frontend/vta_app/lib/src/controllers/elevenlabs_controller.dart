import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vta_app/src/models/elevenlabs_model.dart';
import 'package:vta_app/src/utilities/api/elevenlabs_service.dart';
import 'package:vta_app/src/utilities/config/elevenlabs_config.dart';

/// Controller for managing ElevenLabs TTS functionality for artefacts
class ElevenLabsController extends ChangeNotifier {
  ElevenLabsService? _service;
  List<ElevenLabsVoice>? _availableVoices;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = false;
  String? _lastError;

  // Getters
  List<ElevenLabsVoice>? get availableVoices => _availableVoices;
  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isConfigured => _service != null;

  /// Initialize the ElevenLabs service with stored configuration
  Future<bool> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      final bool isEnabled = await ElevenLabsConfig.getEnabled();
      if (!isEnabled) {
        _service = null;
        notifyListeners();
        return false;
      }

      final String? apiKey = await ElevenLabsConfig.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        _setError('ElevenLabs API key not found');
        return false;
      }

      _service = ElevenLabsService(apiKey: apiKey);
      
      // Validate the API key
      final bool isValid = await _service!.validateApiKey();
      if (!isValid) {
        _setError('Invalid ElevenLabs API key');
        _service = null;
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to initialize ElevenLabs: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Configure ElevenLabs with API key
  Future<bool> configure(String apiKey) async {
    try {
      _setLoading(true);
      _clearError();

      // Test the API key
      final testService = ElevenLabsService(apiKey: apiKey);
      final bool isValid = await testService.validateApiKey();
      
      if (!isValid) {
        _setError('Invalid API key');
        return false;
      }

      // Save configuration
      await ElevenLabsConfig.setApiKey(apiKey);
      await ElevenLabsConfig.setEnabled(true);
      
      _service = testService;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to configure ElevenLabs: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Disable ElevenLabs integration
  Future<void> disable() async {
    await ElevenLabsConfig.setEnabled(false);
    _service = null;
    _availableVoices = null;
    _userInfo = null;
    _clearError();
    notifyListeners();
  }

  /// Load available voices from ElevenLabs
  Future<bool> loadVoices() async {
    if (_service == null) return false;

    try {
      _setLoading(true);
      _clearError();

      _availableVoices = await _service!.getVoices();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to load voices: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load user information and quota
  Future<bool> loadUserInfo() async {
    if (_service == null) return false;

    try {
      _setLoading(true);
      _clearError();

      _userInfo = await _service!.getUserInfo();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to load user info: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate speech from text
  Future<ElevenLabsResponse?> generateSpeech({
    required String text,
    String? voiceId,
    VoiceSettings? voiceSettings,
    String? modelId,
  }) async {
    if (_service == null) {
      return ElevenLabsResponse.error('ElevenLabs service not configured');
    }

    if (text.trim().isEmpty) {
      return ElevenLabsResponse.error('Text cannot be empty');
    }

    try {
      _setLoading(true);
      _clearError();

      // Use configured defaults if not provided
      final String effectiveVoiceId = voiceId ?? await ElevenLabsConfig.getDefaultVoiceId();
      final String effectiveModelId = modelId ?? await ElevenLabsConfig.getDefaultModelId();
      
      final VoiceSettings effectiveVoiceSettings = voiceSettings ?? VoiceSettings(
        stability: await ElevenLabsConfig.getVoiceStability(),
        similarityBoost: await ElevenLabsConfig.getVoiceSimilarityBoost(),
        useSpeakerBoost: await ElevenLabsConfig.getUseSpeakerBoost(),
      );

      final response = await _service!.generateSpeech(
        text: text,
        voiceId: effectiveVoiceId,
        voiceSettings: effectiveVoiceSettings,
        modelId: effectiveModelId,
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

  /// Generate speech for an artefact and return audio data
  Future<Uint8List?> generateSpeechForArtefact({
    required String text,
    required String artefactId,
    String? voiceId,
    VoiceSettings? voiceSettings,
  }) async {
    final response = await generateSpeech(
      text: text,
      voiceId: voiceId,
      voiceSettings: voiceSettings,
    );

    if (response != null && response.success) {
      return response.audioData;
    }

    return null;
  }

  /// Get a voice by ID
  Future<ElevenLabsVoice?> getVoice(String voiceId) async {
    if (_service == null) return null;

    try {
      return await _service!.getVoice(voiceId);
    } catch (e) {
      _setError('Failed to get voice: ${e.toString()}');
      return null;
    }
  }

  /// Get current quota information
  int? getQuotaUsed() {
    return _userInfo?['subscription']?['character_count'] as int?;
  }

  /// Get quota limit
  int? getQuotaLimit() {
    return _userInfo?['subscription']?['character_limit'] as int?;
  }

  /// Check if quota is available for text
  bool hasQuotaForText(String text) {
    final used = getQuotaUsed();
    final limit = getQuotaLimit();
    
    if (used == null || limit == null) return true; // Assume available if unknown
    
    return (used + text.length) <= limit;
  }

  /// Estimate cost for text (in characters)
  int estimateCost(String text) {
    return text.length;
  }

  // Private methods
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

  /// Clear all cached data
  void clearCache() {
    _availableVoices = null;
    _userInfo = null;
    _clearError();
    notifyListeners();
  }

}