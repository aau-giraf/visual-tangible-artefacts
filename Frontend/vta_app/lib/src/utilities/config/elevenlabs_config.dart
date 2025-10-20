import 'package:shared_preferences/shared_preferences.dart';

/// Configuration manager for ElevenLabs API settings
class ElevenLabsConfig {
  static const String _apiKeyKey = 'elevenlabs_api_key';
  static const String _defaultVoiceIdKey = 'elevenlabs_default_voice_id';
  static const String _defaultModelIdKey = 'elevenlabs_default_model_id';
  static const String _voiceStabilityKey = 'elevenlabs_voice_stability';
  static const String _voiceSimilarityBoostKey = 'elevenlabs_voice_similarity_boost';
  static const String _useSpeakerBoostKey = 'elevenlabs_use_speaker_boost';
  static const String _enabledKey = 'elevenlabs_enabled';

  // Default values
  static const String defaultVoiceId = 'Bj9UqZbhQsanLzgalpEG'; // Custom selected voice
  static const String defaultModelId = 'eleven_monolingual_v1';
  static const double defaultStability = 0.5;
  static const double defaultSimilarityBoost = 0.75;
  static const bool defaultUseSpeakerBoost = true;
  static const bool defaultEnabled = false;

  /// Get the stored API key
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  /// Set the API key
  static Future<bool> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_apiKeyKey, apiKey);
  }

  /// Remove the API key
  static Future<bool> removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_apiKeyKey);
  }

  /// Get the default voice ID
  static Future<String> getDefaultVoiceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultVoiceIdKey) ?? defaultVoiceId;
  }

  /// Set the default voice ID
  static Future<bool> setDefaultVoiceId(String voiceId) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_defaultVoiceIdKey, voiceId);
  }

  /// Get the default model ID
  static Future<String> getDefaultModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultModelIdKey) ?? defaultModelId;
  }

  /// Set the default model ID
  static Future<bool> setDefaultModelId(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_defaultModelIdKey, modelId);
  }

  /// Get voice stability setting
  static Future<double> getVoiceStability() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_voiceStabilityKey) ?? defaultStability;
  }

  /// Set voice stability setting
  static Future<bool> setVoiceStability(double stability) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(_voiceStabilityKey, stability);
  }

  /// Get voice similarity boost setting
  static Future<double> getVoiceSimilarityBoost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_voiceSimilarityBoostKey) ?? defaultSimilarityBoost;
  }

  /// Set voice similarity boost setting
  static Future<bool> setVoiceSimilarityBoost(double similarityBoost) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(_voiceSimilarityBoostKey, similarityBoost);
  }

  /// Get speaker boost setting
  static Future<bool> getUseSpeakerBoost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useSpeakerBoostKey) ?? defaultUseSpeakerBoost;
  }

  /// Set speaker boost setting
  static Future<bool> setUseSpeakerBoost(bool useSpeakerBoost) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_useSpeakerBoostKey, useSpeakerBoost);
  }

  /// Get ElevenLabs enabled status
  static Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? defaultEnabled;
  }

  /// Set ElevenLabs enabled status
  static Future<bool> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_enabledKey, enabled);
  }

  /// Get all current settings as a map
  static Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'apiKey': await getApiKey(),
      'defaultVoiceId': await getDefaultVoiceId(),
      'defaultModelId': await getDefaultModelId(),
      'voiceStability': await getVoiceStability(),
      'voiceSimilarityBoost': await getVoiceSimilarityBoost(),
      'useSpeakerBoost': await getUseSpeakerBoost(),
      'enabled': await getEnabled(),
    };
  }

  /// Check if ElevenLabs is properly configured
  static Future<bool> isConfigured() async {
    final apiKey = await getApiKey();
    final enabled = await getEnabled();
    return apiKey != null && apiKey.isNotEmpty && enabled;
  }

  /// Reset all settings to defaults
  static Future<bool> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final futures = [
      prefs.remove(_apiKeyKey),
      prefs.remove(_defaultVoiceIdKey),
      prefs.remove(_defaultModelIdKey),
      prefs.remove(_voiceStabilityKey),
      prefs.remove(_voiceSimilarityBoostKey),
      prefs.remove(_useSpeakerBoostKey),
      prefs.remove(_enabledKey),
    ];
    
    final results = await Future.wait(futures);
    return results.every((result) => result);
  }
}