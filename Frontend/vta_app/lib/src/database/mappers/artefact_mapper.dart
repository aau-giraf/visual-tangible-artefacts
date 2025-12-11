import 'package:vta_app/src/modelsDTOs/artefact.dart';
import '../models/artefact_db.dart';

/// Convert DTO into ArtefactDB model local database
ArtefactDB artefactToDb(Artefact a) {
  return ArtefactDB(
    artefactId: a.artefactId ?? '',
    artefactIndex: a.artefactIndex ?? 0,
    userId: a.userId ?? '',
    categoryId: a.categoryId,
    imagePath: a.imageUrl,
    soundPath: a.soundUrl,
    modifiedDate: DateTime.now().millisecondsSinceEpoch,
    name: a.name,
    nameShown: (a.nameShown ?? false) ? 1 : 0,
  );
}
