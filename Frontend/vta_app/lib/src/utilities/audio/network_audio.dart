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
      // Ensure URL is properly formed
      final Uri uri = url.startsWith('http') ? Uri.parse(url) : Uri.parse('http://${Uri.parse(url).host}${Uri.parse(url).path}');

      // First try to fetch the audio file using http with auth headers
      final response = await http.get(
        uri,
        headers: headers ?? {},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load audio file. Status code: ${response.statusCode}, Body: ${response.body}');
      }

      // Create a blob URL from the response data
      final blob = html.Blob([response.bodyBytes], response.headers['content-type'] ?? 'audio/mpeg');
      _blobUrl = html.Url.createObjectUrlFromBlob(blob);

      // Create an audio source from the blob URL
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(_blobUrl!)),
      );
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading audio: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      debugPrint('Please check if the URL is correct and accessible');
      rethrow;
    }
  }

  Future<void> play() async {
    try {
      if (!_isInitialized) {
        await load();
      }
      
      // Always stop and reset when play is pressed
      await _player.stop();
      await _player.seek(Duration.zero);
      
      // Reload the audio source
      final Uri uri = Uri.parse(_blobUrl!);
      await _player.setAudioSource(
        AudioSource.uri(uri),
      );
      
      await _player.play();
      
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      debugPrint('Pausing audio...');
      await _player.pause();
      debugPrint('Audio paused');
    } catch (e) {
      debugPrint('Error pausing audio: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      debugPrint('Stopping audio...');
      await _player.stop();
      await _player.seek(Duration.zero);
      debugPrint('Audio stopped and reset to beginning');
    } catch (e) {
      debugPrint('Error stopping audio: $e');
      rethrow;
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      debugPrint('Seeking to position: $position');
      await _player.seek(position);
      debugPrint('Seek complete');
    } catch (e) {
      debugPrint('Error seeking audio: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      debugPrint('Disposing audio resources...');
      await _player.dispose();
      if (_blobUrl != null) {
        html.Url.revokeObjectUrl(_blobUrl!);
        _blobUrl = null;
        debugPrint('Blob URL revoked');
      }
      debugPrint('Audio resources disposed');
    } catch (e) {
      debugPrint('Error disposing audio: $e');
      rethrow;
    }
  }

  bool get isPlaying => _player.playing;
  bool get isInitialized => _isInitialized;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
}