# Library: database

**Path:** `Frontend/vta_app/lib/src/database/database.dart`

## Overview
This `database.dart` file serves as a barrel file for the SQLite database integration layer of the VTA Flutter application. Its primary purpose is to re-export all the core components (helper classes, database models, and repositories) of the database module, making them easily accessible through a single import statement.

## Exports

### Database Helper
- `'database_helper.dart'`

### Debug Helper
- `'database_debug_helper.dart'`

### Models
- `'models/user_db.dart'`
- `'models/category_db.dart'`
- `'models/artefact_db.dart'`
- `'models/saved_board_db.dart'`
- `'models/saved_artefact_db.dart'`
- `'models/session_meta_db.dart'`
- `'models/sync_metadata_db.dart'`

### Repositories
- `'repositories/user_repository.dart'`
- `'repositories/category_repository.dart'`
- `'repositories/artefact_repository.dart'`
- `'repositories/saved_board_repository.dart'`
- `'repositories/saved_artefact_repository.dart'`
- `'repositories/session_meta_repository.dart'`
- `'repositories/sync_metadata_repository.dart'`

## Internal Imports
*(This file only exports; it does not import other Dart files for its own logic.)*

## Notable Packages
*(None beyond standard Dart libraries and the implicitly used components it exports)*
