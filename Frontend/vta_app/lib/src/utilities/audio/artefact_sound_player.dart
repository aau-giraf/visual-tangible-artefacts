import 'dart:async';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/utilities/audio/network_audio.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';

mixin ArtefactSoundPlayer {
  final Map<String, NetworkAudio> _audioCache = {};
  late final ApiProvider _apiProvider = GetIt.instance.get<ApiProvider>();

  Future<void> playArtefactSound(Artefact artefact) async {
    if (artefact.soundUrl == null) {
      return;
    }
    
  // Ensure URL is properly formed with scheme and host
  final soundUrl = artefact.soundUrl!.startsWith('http')
    ? artefact.soundUrl!
    : '${_apiProvider.baseUrl}${artefact.soundUrl}';

    try {
      // Get or create NetworkAudio instance
      var audio = _audioCache[soundUrl];
      
      // If audio exists but was disposed, create a new instance
      if (audio != null && !audio.isInitialized) {
        _audioCache.remove(soundUrl);
        audio = null;
      }
      
      // Create new instance if needed
      audio ??= _audioCache.putIfAbsent(
        soundUrl,
        () => NetworkAudio(
          soundUrl,
          headers: {'Authorization': 'Bearer ${GetIt.instance.get<Token>().value}'},
        ),
      );

      // Play the sound
      await audio.play();
    } catch (e) {
      rethrow;
    }
  }

  /// Play a single artefact and wait for it to finish (or timeout).
  /// This exposes a single-item play that other widgets can await and
  /// allows stopping between items.
  Future<void> playArtefactSoundAndWait(Artefact artefact) async {
    await playArtefactSound(artefact);
    // Recreate the full sound URL used as the cache key so we can find the
    // NetworkAudio instance created in playArtefactSound.
    if (artefact.soundUrl == null) return;
    final soundUrl = artefact.soundUrl!.startsWith('http')
        ? artefact.soundUrl!
        : '${_apiProvider.baseUrl}${artefact.soundUrl}';

    // Use the same full URL key as stored in the cache
    final audio = _audioCache[soundUrl];
    if (audio != null && audio.isInitialized) {
      final completer = Completer<void>();
      final subscription = audio.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          completer.complete();
        }
      });

      try {
        await completer.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            audio.stop();
          },
        );
      } finally {
        await subscription.cancel();
      }
    }
  }

  Future<void> cleanupArtefactSounds() async {
    debugPrint('Cleaning up artefact sounds...');
    for (final audio in _audioCache.values) {
      await audio.dispose();
    }
    _audioCache.clear();
    debugPrint('Artefact sounds cleaned up');
  }
}