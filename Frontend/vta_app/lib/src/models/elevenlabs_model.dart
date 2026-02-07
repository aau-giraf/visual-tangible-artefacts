import 'dart:typed_data';

/// Response model for ElevenLabs TTS calls (via backend proxy).
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