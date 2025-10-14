import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

class NetworkAudio {
  final String url;
  final Map<String, String>? headers;
  final _player = AudioPlayer();
  bool _isInitialized = false;

  NetworkAudio(this.url, {this.headers});

  Future<void> load() async {
    if (_isInitialized) return;

    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: headers ?? {});
    if (response.statusCode != 200) {
      throw Exception('Failed to load audio file. Status code: ${response.statusCode}');
    }

  final bytes = response.bodyBytes;
  final dataUri = Uri.dataFromBytes(bytes, mimeType: response.headers['content-type'] ?? 'audio/mpeg');
  await _player.setAudioSource(AudioSource.uri(dataUri));
    _isInitialized = true;
  }

  Future<void> play() async {
    if (!_isInitialized) await load();
    await _player.stop();
    await _player.seek(Duration.zero);
    await _player.play();
  }

  Future<void> pause() async => _player.pause();
  Future<void> stop() async => _player.stop();
  Future<void> seekTo(Duration p) async => _player.seek(p);
  Future<void> dispose() async => await _player.dispose();

  bool get isPlaying => _player.playing;
  bool get isInitialized => _isInitialized;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
}
