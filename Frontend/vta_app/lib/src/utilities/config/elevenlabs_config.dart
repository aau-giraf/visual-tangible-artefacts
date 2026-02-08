import 'package:shared_preferences/shared_preferences.dart';

/// Configuration manager for ElevenLabs voice preferences.
///
/// The ElevenLabs API key is stored server-side only (in backend appsettings).
/// This config only manages local voice ID preferences which are not secrets.
class ElevenLabsConfig {
  static const String _defaultVoiceIdKey = 'elevenlabs_default_voice_id';

  // Voice IDs supported by the backend's ResolveVoiceId()
  static const String defaultVoiceId = 'Bj9UqZbhQsanLzgalpEG';
  static const String alternateVoiceId = 'Xb7hH8MSUJpSbSDYk0k2';
  static const List<String> availableVoiceIds = [
    defaultVoiceId,
    alternateVoiceId
  ];

  /// Get the preferred voice ID
  static Future<String> getDefaultVoiceId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_defaultVoiceIdKey);
    if (stored != null && availableVoiceIds.contains(stored)) {
      return stored;
    }
    return defaultVoiceId;
  }

  /// Set the preferred voice ID
  static Future<bool> setDefaultVoiceId(String voiceId) async {
    if (!availableVoiceIds.contains(voiceId)) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_defaultVoiceIdKey, voiceId);
  }
}
