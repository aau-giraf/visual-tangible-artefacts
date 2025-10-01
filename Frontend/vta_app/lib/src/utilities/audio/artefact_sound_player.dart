import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/utilities/audio/network_audio.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:get_it/get_it.dart';

mixin ArtefactSoundPlayer {
  final Map<String, NetworkAudio> _audioCache = {};

  Future<void> playArtefactSound(Artefact artefact) async {
    print('Attempting to play sound for artefact: ${artefact.artefactId}');
    print('Artefact properties: soundUrl=${artefact.soundUrl}, imageUrl=${artefact.imageUrl}');
    
    if (artefact.soundUrl == null) {
      print('No sound URL available for artefact');
      return;
    }

    print('Raw sound URL: ${artefact.soundUrl}');
    
    // Ensure URL is properly formed with scheme and host
    final soundUrl = artefact.soundUrl!.startsWith('http')
        ? artefact.soundUrl!
        : 'http://localhost:5192${artefact.soundUrl}';  // Using the correct port number (5192)

    print('Attempting to play sound from URL: $soundUrl');

    try {
      // Get or create NetworkAudio instance
      final audio = _audioCache.putIfAbsent(
        soundUrl,
        () => NetworkAudio(
          soundUrl,
          headers: {'Authorization': 'Bearer ${GetIt.instance.get<Token>().value}'},
        ),
      );

      // Play the sound
      await audio.playAudio();
    } catch (e) {
      print('Error playing artefact sound: $e');
    }
  }

  Future<void> playArtefactSoundsInOrder(List<Artefact> artefacts) async {
    for (final artefact in artefacts) {
      await playArtefactSound(artefact);
      
      // Get the NetworkAudio instance from cache
      final audio = _audioCache[artefact.soundUrl];
      if (audio != null && audio.isInitialized) {
        // Wait for the sound to finish playing
        while (audio.isPlaying) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }
  }

  Future<void> cleanupArtefactSounds() async {
    for (final audio in _audioCache.values) {
      await audio.disposeAudio();
    }
    _audioCache.clear();
  }

  Future<void> disposeArtefactSounds() async {
    for (final audio in _audioCache.values) {
      await audio.dispose();
    }
    _audioCache.clear();
  }
}