import 'dart:async';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/utilities/audio/network_audio.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

mixin ArtefactSoundPlayer {
  final Map<String, NetworkAudio> _audioCache = {};

  Future<void> playArtefactSound(Artefact artefact) async {
    if (artefact.soundUrl == null) {
      return;
    }
    
    // Ensure URL is properly formed with scheme and host
    final soundUrl = artefact.soundUrl!.startsWith('http')
        ? artefact.soundUrl!
        : 'http://localhost:5192${artefact.soundUrl}';  // Using the correct port number (5192)

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

  Future<void> playArtefactSoundsInOrder(List<Artefact> artefacts) async {
    for (final artefact in artefacts) {
      await playArtefactSound(artefact);
      
      // Get the NetworkAudio instance from cache
      final audio = _audioCache[artefact.soundUrl];
      if (audio != null && audio.isInitialized) {
        // Create a completer to track when the audio finishes
        final completer = Completer<void>();
        
        // Subscribe to player state changes
        final subscription = audio.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            completer.complete();
          }
        });
        
        // Wait for the audio to complete
        try {
          await completer.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              audio.stop();
            },
          );
        } finally {
          await subscription.cancel();
        }
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