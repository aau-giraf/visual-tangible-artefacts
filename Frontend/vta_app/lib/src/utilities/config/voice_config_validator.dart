import 'package:vta_app/src/utilities/config/elevenlabs_config.dart';

/// Utility class for validating and resolving voice IDs
class VoiceConfigValidator {
  /// Resolves a voice ID to ensure it's one of the allowed voices
  /// Falls back to default voice if the provided ID is invalid
  static String resolveVoiceId(String? voiceId) {
    if (voiceId == null || voiceId.isEmpty) {
      return ElevenLabsConfig.defaultVoiceId;
    }

    // Check if the voice ID is in the list of available voices
    if (ElevenLabsConfig.availableVoiceIds.contains(voiceId)) {
      return voiceId;
    }

    // Fall back to default if not found
    return ElevenLabsConfig.defaultVoiceId;
  }

  /// Validates if a voice ID is supported
  static bool isValidVoiceId(String? voiceId) {
    if (voiceId == null || voiceId.isEmpty) {
      return false;
    }
    return ElevenLabsConfig.availableVoiceIds.contains(voiceId);
  }

  /// Gets a human-readable label for a voice ID
  static String getVoiceLabel(String voiceId) {
    if (voiceId == ElevenLabsConfig.defaultVoiceId) {
      return 'Mand 👨';
    } else if (voiceId == ElevenLabsConfig.alternateVoiceId) {
      return 'Kvinde 👩';
    }
    return 'Ukendt stemme';
  }

  /// Gets all available voice options as a list of maps
  static List<Map<String, String>> getVoiceOptions() {
    return [
      {
        'id': ElevenLabsConfig.defaultVoiceId,
        'label': 'Mand 👨',
      },
      {
        'id': ElevenLabsConfig.alternateVoiceId,
        'label': 'Kvinde 👩',
      },
    ];
  }
}
