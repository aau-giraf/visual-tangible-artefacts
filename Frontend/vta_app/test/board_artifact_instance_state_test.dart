import 'package:flutter_test/flutter_test.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';

void main() {
  group('BoardArtefact per-instance state', () {
    test('nameVisible is independent across duplicates', () {
      final dto = Artefact(
        artefactId: 'a1',
        name: 'Test',
        nameShown: true, // backend/global flag should not influence instance
      );

      final a = BoardArtefact.fromArtefact(dto);
      final b = BoardArtefact.fromArtefact(dto);

      // Defaults should be false per instance, regardless of dto.nameShown
      expect(a.nameVisible, isFalse);
      expect(b.nameVisible, isFalse);

      // Toggle for one should not affect the other
      b.nameVisible = true;
      expect(b.nameVisible, isTrue);
      expect(a.nameVisible, isFalse);
    });
  });
}
