import 'dart:convert';
import 'dart:typed_data';
import 'package:vta_app/src/models/elevenlabs_model.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';

/// Service class for interacting with ElevenLabs API
class ElevenLabsService {
  static const String _baseUrl = 'https://api.elevenlabs.io/v1';
  static const String _defaultVoiceId = 'pNInz6obpgDQGcFmaJgB'; // Adam voice
  
  final String apiKey;
  final ApiProvider _apiProvider;

  ElevenLabsService({
    required this.apiKey,
  }) : _apiProvider = ApiProvider(baseUrl: _baseUrl);

  /// Generate speech from text using ElevenLabs TTS
  Future<ElevenLabsResponse> generateSpeech({
    required String text,
    String? voiceId,
    VoiceSettings? voiceSettings,
    String? modelId,
    int? seed,
  }) async {
    try {
      final String effectiveVoiceId = voiceId ?? _defaultVoiceId;
      final String endpoint = '/text-to-speech/$effectiveVoiceId';
      
      final ElevenLabsRequest request = ElevenLabsRequest(
        text: text,
        modelId: modelId ?? 'eleven_monolingual_v1',
        voiceSettings: voiceSettings ?? VoiceSettings(),
        seed: seed,
      );

      final Map<String, String> headers = {
        'Accept': 'audio/mpeg',
        'Content-Type': 'application/json',
        'xi-api-key': apiKey,
      };

      final response = await _apiProvider.postAsJson(
        endpoint,
        headers: headers,
        body: request.toJson(),
      );

      if (response != null && response.ok) {
        final Uint8List audioData = response.bodyBytes;
        return ElevenLabsResponse.success(audioData);
      } else {
        final String errorMessage = response != null
            ? 'Failed to generate speech: ${response.statusCode} ${response.reasonPhrase}'
            : 'Failed to connect to ElevenLabs API';
        return ElevenLabsResponse.error(errorMessage, response?.statusCode);
      }
    } catch (e) {
      return ElevenLabsResponse.error('Error generating speech: ${e.toString()}');
    }
  }

  /// Get available voices from ElevenLabs
  Future<List<ElevenLabsVoice>?> getVoices() async {
    try {
      const String endpoint = '/voices';
      
      final Map<String, String> headers = {
        'Accept': 'application/json',
        'xi-api-key': apiKey,
      };

      final response = await _apiProvider.fetchAsJson(
        endpoint,
        headers: headers,
      );

      if (response != null && response.ok) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> voicesJson = jsonResponse['voices'] as List<dynamic>;
        
        return voicesJson
            .map((voiceJson) => ElevenLabsVoice.fromJson(voiceJson as Map<String, dynamic>))
            .toList();
      } else {
        throw ElevenLabsException(
          message: 'Failed to fetch voices: ${response?.statusCode} ${response?.reasonPhrase}',
          statusCode: response?.statusCode,
        );
      }
    } catch (e) {
      throw ElevenLabsException(
        message: 'Error fetching voices: ${e.toString()}',
      );
    }
  }

  /// Get user information and quota from ElevenLabs
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      const String endpoint = '/user';
      
      final Map<String, String> headers = {
        'Accept': 'application/json',
        'xi-api-key': apiKey,
      };

      final response = await _apiProvider.fetchAsJson(
        endpoint,
        headers: headers,
      );

      if (response != null && response.ok) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ElevenLabsException(
          message: 'Failed to fetch user info: ${response?.statusCode} ${response?.reasonPhrase}',
          statusCode: response?.statusCode,
        );
      }
    } catch (e) {
      throw ElevenLabsException(
        message: 'Error fetching user info: ${e.toString()}',
      );
    }
  }

  /// Get a specific voice by ID
  Future<ElevenLabsVoice?> getVoice(String voiceId) async {
    try {
      final String endpoint = '/voices/$voiceId';
      
      final Map<String, String> headers = {
        'Accept': 'application/json',
        'xi-api-key': apiKey,
      };

      final response = await _apiProvider.fetchAsJson(
        endpoint,
        headers: headers,
      );

      if (response != null && response.ok) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return ElevenLabsVoice.fromJson(jsonResponse);
      } else {
        throw ElevenLabsException(
          message: 'Failed to fetch voice: ${response?.statusCode} ${response?.reasonPhrase}',
          statusCode: response?.statusCode,
        );
      }
    } catch (e) {
      throw ElevenLabsException(
        message: 'Error fetching voice: ${e.toString()}',
      );
    }
  }

  /// Validate API key by making a simple request
  Future<bool> validateApiKey() async {
    try {
      final userInfo = await getUserInfo();
      return userInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// Generate speech and save to file system (for backend integration)
  Future<ElevenLabsResponse> generateSpeechForArtefact({
    required String text,
    required String artefactId,
    String? voiceId,
    VoiceSettings? voiceSettings,
    String? modelId,
  }) async {
    try {
      final response = await generateSpeech(
        text: text,
        voiceId: voiceId,
        voiceSettings: voiceSettings,
        modelId: modelId,
      );

      if (response.success && response.audioData != null) {
        // Here you would typically upload the audio data to your backend
        // For now, we'll return the response with the audio data
        return response;
      } else {
        return response;
      }
    } catch (e) {
      return ElevenLabsResponse.error('Error generating speech for artefact: ${e.toString()}');
    }
  }
}

/// Default voice configurations for different use cases
class ElevenLabsVoicePresets {
  static const Map<String, String> popularVoices = {
    'Adam': 'pNInz6obpgDQGcFmaJgB',
    'Antoni': 'ErXwobaYiN019PkySvjV',
    'Arnold': 'VR6AewLTigWG4xSOukaG',
    'Bella': 'EXAVITQu4vr4xnSDxMaL',
    'Domi': 'AZnzlk1XvdvUeBnXmlld',
    'Elli': 'MF3mGyEYCl7XYWbV9V6O',
    'Josh': 'TxGEqnHWrfWFTfGW9XjX',
    'Rachel': '21m00Tcm4TlvDq8ikWAM',
    'Sam': 'yoZ06aMxZJJ28mfd3POQ',
  };

  static VoiceSettings get balanced => VoiceSettings(
    stability: 0.5,
    similarityBoost: 0.75,
    useSpeakerBoost: true,
  );

  static VoiceSettings get stable => VoiceSettings(
    stability: 0.8,
    similarityBoost: 0.5,
    useSpeakerBoost: true,
  );

  static VoiceSettings get expressive => VoiceSettings(
    stability: 0.3,
    similarityBoost: 0.9,
    useSpeakerBoost: true,
  );
}