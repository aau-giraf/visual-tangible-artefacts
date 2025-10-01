import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

class NetworkAudio {
  final String url;
  final Map<String, String>? headers;
  final _player = AudioPlayer();
  bool _isInitialized = false;
  String? _blobUrl;
  
  NetworkAudio(this.url, {this.headers});

  Future<void> load() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('Loading audio from URL: $url');
      debugPrint('Using headers: $headers');

      // Ensure URL is properly formed
      final Uri uri = url.startsWith('http') ? Uri.parse(url) : Uri.parse('http://${Uri.parse(url).host}${Uri.parse(url).path}');
      debugPrint('Parsed URI: $uri');

      // First try to fetch the audio file using http with auth headers
      final response = await http.get(
        uri,
        headers: headers ?? {},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load audio file. Status code: ${response.statusCode}, Body: ${response.body}');
      }

      debugPrint('Successfully fetched audio file. Content-Type: ${response.headers['content-type']}');
      debugPrint('Audio file size: ${response.bodyBytes.length} bytes');

      // Create a blob URL from the response data
      final blob = html.Blob([response.bodyBytes], response.headers['content-type'] ?? 'audio/mpeg');
      _blobUrl = html.Url.createObjectUrlFromBlob(blob);
      debugPrint('Created blob URL: $_blobUrl');

      // Create an audio source from the blob URL
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(_blobUrl!)),
      );
      
      _isInitialized = true;
      debugPrint('Audio loaded successfully');
    } catch (e) {
      debugPrint('Error loading audio: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      debugPrint('Please check if the URL is correct and accessible');
      rethrow;
    }
  }

  Future<void> playAudio() async {
    if (!_isInitialized) {
      await load();
    }
    await _player.play();
  }

  Future<void> pauseAudio() async {
    await _player.pause();
  }

  Future<void> stopAudio() async {
    await _player.stop();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> disposeAudio() async {
    await _player.dispose();
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
      _blobUrl = null;
    }
  }

  bool get isPlaying => _player.playing;
  bool get isInitialized => _isInitialized;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  Future<void> play() async {
    try {
      if (!_isInitialized) {
        await load();
      }
      await _player.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}