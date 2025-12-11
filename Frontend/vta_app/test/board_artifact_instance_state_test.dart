import 'package:flutter_test/flutter_test.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';

void main() {
  group('BoardArtefact name visibility from baseArtefact', () {
    test('nameVisible reads from baseArtefact.nameShown', () {
      final dto = Artefact(
        artefactId: 'a1',
        name: 'Test',
        nameShown: true,
      );

      final boardArtifact = BoardArtefact.fromArtefact(dto);

      // nameVisible should read from baseArtefact.nameShown
      expect(boardArtifact.nameVisible, isTrue);
      expect(boardArtifact.baseArtefact?.nameShown, isTrue);
    });

    test('multiple instances share the same baseArtefact.nameShown', () {
      final dto = Artefact(
        artefactId: 'a1',
        name: 'Test',
        nameShown: false,
      );

      final a = BoardArtefact.fromArtefact(dto);
      final b = BoardArtefact.fromArtefact(dto);

      // Both should read false initially
      expect(a.nameVisible, isFalse);
      expect(b.nameVisible, isFalse);

      // Changing one updates the shared baseArtefact
      a.nameVisible = true;
      
      // Both should now reflect the change since they share the same Artefact object
      expect(dto.nameShown, isTrue);
      expect(a.nameVisible, isTrue);
      expect(b.nameVisible, isTrue);
    });
  });
}
