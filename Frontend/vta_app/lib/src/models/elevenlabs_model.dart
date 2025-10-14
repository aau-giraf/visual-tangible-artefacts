import 'dart:typed_data';

/// Model for ElevenLabs text-to-speech request
class ElevenLabsRequest {
  final String text;
  final String? modelId;
  final VoiceSettings? voiceSettings;
  final int? seed;
  final String? previousText;
  final String? nextText;
  final bool? previousRequestIds;
  final bool? nextRequestIds;

  ElevenLabsRequest({
    required this.text,
    this.modelId = 'eleven_monolingual_v1',
    this.voiceSettings,
    this.seed,
    this.previousText,
    this.nextText,
    this.previousRequestIds,
    this.nextRequestIds,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'text': text,
      'model_id': modelId,
    };

    if (voiceSettings != null) {
      json['voice_settings'] = voiceSettings!.toJson();
    }

    if (seed != null) json['seed'] = seed;
    if (previousText != null) json['previous_text'] = previousText;
    if (nextText != null) json['next_text'] = nextText;
    if (previousRequestIds != null) json['previous_request_ids'] = previousRequestIds;
    if (nextRequestIds != null) json['next_request_ids'] = nextRequestIds;

    return json;
  }
}

/// Voice settings for ElevenLabs TTS
class VoiceSettings {
  final double stability;
  final double similarityBoost;
  final double? style;
  final bool? useSpeakerBoost;

  VoiceSettings({
    this.stability = 0.5,
    this.similarityBoost = 0.75,
    this.style,
    this.useSpeakerBoost = true,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'stability': stability,
      'similarity_boost': similarityBoost,
    };

    if (style != null) json['style'] = style;
    if (useSpeakerBoost != null) json['use_speaker_boost'] = useSpeakerBoost;

    return json;
  }
}

/// Response model for ElevenLabs API calls
class ElevenLabsResponse {
  final bool success;
  final Uint8List? audioData;
  final String? errorMessage;
  final int? statusCode;

  ElevenLabsResponse({
    required this.success,
    this.audioData,
    this.errorMessage,
    this.statusCode,
  });

  factory ElevenLabsResponse.success(Uint8List audioData) {
    return ElevenLabsResponse(
      success: true,
      audioData: audioData,
    );
  }

  factory ElevenLabsResponse.error(String errorMessage, [int? statusCode]) {
    return ElevenLabsResponse(
      success: false,
      errorMessage: errorMessage,
      statusCode: statusCode,
    );
  }
}

/// Model for available voices from ElevenLabs
class ElevenLabsVoice {
  final String voiceId;
  final String name;
  final String? category;
  final String? description;
  final List<String>? labels;
  final VoiceSettings? settings;

  ElevenLabsVoice({
    required this.voiceId,
    required this.name,
    this.category,
    this.description,
    this.labels,
    this.settings,
  });

  factory ElevenLabsVoice.fromJson(Map<String, dynamic> json) {
    return ElevenLabsVoice(
      voiceId: json['voice_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      description: json['description'] as String?,
      labels: json['labels'] != null 
          ? List<String>.from(json['labels'] as List)
          : null,
      settings: json['settings'] != null
          ? VoiceSettings(
              stability: (json['settings']['stability'] as num?)?.toDouble() ?? 0.5,
              similarityBoost: (json['settings']['similarity_boost'] as num?)?.toDouble() ?? 0.75,
              style: (json['settings']['style'] as num?)?.toDouble(),
              useSpeakerBoost: json['settings']['use_speaker_boost'] as bool? ?? true,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice_id': voiceId,
      'name': name,
      'category': category,
      'description': description,
      'labels': labels,
      'settings': settings?.toJson(),
    };
  }
}

/// Exception class for ElevenLabs API errors
class ElevenLabsException implements Exception {
  final String message;
  final int? statusCode;

  ElevenLabsException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() {
    return 'ElevenLabsException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}