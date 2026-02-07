# Database Mappers Summary

**Path:** `Frontend/vta_app/lib/src/database/mappers/`

## Files

| File | Description |
|------|-------------|
| `artefact_mapper.dart` (17 lines) | Single function `artefactToDb(Artefact a) → ArtefactDB` converting an API DTO into a local database model. Maps fields directly, defaults `artefactId` to empty string and `artefactIndex` to 0 if null, converts `nameShown` bool to int (0/1), sets `modifiedDate` to current timestamp. |

## Notes

- Only one mapper exists; category mapping is done inline in `ArtifactModel` via `_categoryToDb()`.
- This is the only file in this directory.
