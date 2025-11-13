# File Storage Migration Guide

## Overview

This guide documents the migration from a flat file storage structure to a user-based hierarchical structure.

### Old Structure
```
Assets/
├── Artefacts/
│   ├── {artefactId}.png
│   └── {artefactId2}.png
├── Categories/
│   └── {categoryId}.png
└── Sounds/
    ├── {artefactId}.mp3
    └── {artefactId2}.mp3
```

### New Structure
```
Assets/
├── Artefacts/
│   ├── {userId}/
│   │   ├── {artefactId}.png
│   │   └── {artefactId2}.png
│   └── {userId2}/
│       └── {artefactId3}.png
├── Categories/
│   ├── {userId}/
│   │   └── {categoryId}.png
│   └── {userId2}/
│       └── {categoryId2}.png
└── Sounds/
    ├── {userId}/
    │   ├── {artefactId}.mp3
    │   └── {artefactId2}.mp3
    └── {userId2}/
        └── {artefactId3}.mp3
```

## Benefits

1. **User Isolation** - Each user's files are physically separated
2. **Easy User Management** - Delete user folder to remove all user data
3. **Better Security** - Physical isolation of user data
4. **GDPR Compliance** - Right to deletion is trivial (just delete folder)
5. **Scalability** - Better performance as files are distributed across user folders
6. **Backup Flexibility** - Can backup individual users

## Changes Made

### 1. Utility Classes Updated

#### [ImageUtilities.cs](Utilities/ImageUtilities.cs)
- `AddImage()` - Now accepts `userId` parameter and creates user-specific subdirectories
- `DeleteImage()` - Now accepts `userId` parameter and searches in user-specific subdirectories
- `FindFile()` - Updated to search within user-specific directories

#### [SoundUtilities.cs](Utilities/SoundUtilities.cs)
- `AddSound(IFormFile)` - Now accepts `userId` parameter
- `AddSound(byte[])` - Now accepts `userId` parameter (for ElevenLabs generated audio)
- `DeleteSound()` - Now accepts `userId` parameter

### 2. Controllers Updated

All controller methods now pass `userId` (extracted from JWT token) to utility functions:

- [ArtefactsController.cs](Controllers/ArtefactsController.cs)
  - `PostArtefact()` - Creates artifacts in user folders
  - `PatchArtefact()` - Updates artifacts in user folders
  - `DeleteArtefact()` - Deletes from user folders
  - `GenerateSpeech()` - Saves generated audio to user folders
  - All TTS endpoints updated

- [CategoriesController.cs](Controllers/CategoriesController.cs)
  - `PostCategory()` - Creates categories in user folders
  - `PatchCategory()` - Updates categories in user folders
  - `DeleteCategory()` - Deletes from user folders

- [AssetsController.cs](Controllers/AssetsController.cs)
  - **Breaking Change**: Endpoints now require userId in path
  - `GET /api/Assets/Artefacts/{userId}/{filename}`
  - `GET /api/Assets/Categories/{userId}/{filename}`
  - `GET /api/Assets/Sounds/{userId}/{filename}`

### 3. API Path Changes

**Old Format:**
```
/api/Assets/Artefacts/{filename}
/api/Assets/Categories/{filename}
/api/Assets/Sounds/{filename}
```

**New Format:**
```
/api/Assets/Artefacts/{userId}/{filename}
/api/Assets/Categories/{userId}/{filename}
/api/Assets/Sounds/{userId}/{filename}
```

## Migration Process

### Step 1: Dry Run (Recommended)

First, run a dry run to see what would be migrated without making any changes:

```bash
curl -X POST "https://your-api-url/api/Migration/migrate-to-user-based-storage?dryRun=true" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

This will output a summary of:
- How many files would be moved
- How many files are already migrated
- Any errors that would occur

### Step 2: Backup

**IMPORTANT:** Before running the live migration, backup your Assets folder:

```bash
# Navigate to the backend directory
cd /path/to/Backend/VTA.API

# Create a backup
cp -r Assets Assets_backup_$(date +%Y%m%d_%H%M%S)
```

Also backup your database:
```bash
mysqldump -h giraf-vta02.srv.aau.dk -u GirafDotNetAPI -p VTA > vta_backup_$(date +%Y%m%d_%H%M%S).sql
```

### Step 3: Run Live Migration

Once you've verified the dry run and created backups, run the live migration:

```bash
curl -X POST "https://your-api-url/api/Migration/migrate-to-user-based-storage?dryRun=false" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

The migration script will:
1. Read all artifacts and categories from the database
2. Move each file from flat structure to user-based structure
3. Update database records with new file paths
4. Skip files that have already been migrated
5. Report errors for any files that couldn't be migrated

### Step 4: Verify

After migration, verify that:
1. The API responds correctly
2. Images and sounds load in the frontend
3. File counts match:
   ```bash
   # Count old structure files (should be 0 or minimal)
   find Assets/Artefacts -maxdepth 1 -type f | wc -l
   find Assets/Categories -maxdepth 1 -type f | wc -l
   find Assets/Sounds -maxdepth 1 -type f | wc -l

   # Count new structure files
   find Assets/Artefacts -type f | wc -l
   find Assets/Categories -type f | wc -l
   find Assets/Sounds -type f | wc -l
   ```

### Step 5: Cleanup (Optional)

Once you've verified everything works, you can remove the backup and the migration endpoint:

```bash
# Remove backup (only if everything works!)
rm -rf Assets_backup_*

# Consider removing or securing the MigrationController in production
```

## Rollback Plan

If something goes wrong:

1. **Stop the API server**
2. **Restore Assets folder from backup:**
   ```bash
   rm -rf Assets
   cp -r Assets_backup_TIMESTAMP Assets
   ```
3. **Restore database from backup:**
   ```bash
   mysql -h giraf-vta02.srv.aau.dk -u GirafDotNetAPI -p VTA < vta_backup_TIMESTAMP.sql
   ```
4. **Revert code changes** using git:
   ```bash
   git checkout HEAD~1  # Or specific commit before migration
   ```

## Testing

### Manual Testing Checklist

- [ ] Create new artifact with image
- [ ] Create new artifact with sound
- [ ] Create new category with image
- [ ] View existing artifacts (images load correctly)
- [ ] View existing categories (images load correctly)
- [ ] Play artifact sounds
- [ ] Generate text-to-speech for artifact
- [ ] Update artifact image
- [ ] Update artifact sound
- [ ] Delete artifact (verify files deleted from user folder)
- [ ] Delete category (verify files deleted from user folder)

### API Endpoints to Test

```bash
# Create artifact
POST /api/Users/Artefacts
Content-Type: multipart/form-data

# Get artifacts (check image/sound URLs)
GET /api/Users/Artefacts

# Get artifact image (new path format)
GET /api/Assets/Artefacts/{userId}/{filename}

# Get artifact sound (new path format)
GET /api/Assets/Sounds/{userId}/{filename}
```

## Security Considerations

### Migration Endpoint

The `MigrationController` should be:
1. **Protected** - Only accessible to administrators
2. **Removed** - Delete after migration is complete
3. **Logged** - All migration attempts should be logged

### Recommendations

```csharp
// Add admin-only authorization
[Authorize(Roles = "Admin")]
public class MigrationController : ControllerBase
{
    // ... endpoints
}
```

Or remove the controller entirely after migration:
```bash
rm Controllers/MigrationController.cs
rm Scripts/MigrateToUserBasedStorage.cs
```

## Troubleshooting

### Files Not Found After Migration

**Symptom:** API returns 404 for images/sounds after migration

**Cause:** Database paths not updated or files not moved correctly

**Solution:**
1. Check database for path format: `SELECT ImagePath, SoundPath FROM artefact LIMIT 5;`
2. Should be: `/api/Assets/Artefacts/{userId}/{filename}`
3. Check filesystem: `ls -la Assets/Artefacts/{userId}/`

### Permission Errors During Migration

**Symptom:** Migration fails with permission denied errors

**Cause:** API process doesn't have write permissions

**Solution:**
```bash
# Set proper permissions
chown -R api-user:api-user Assets/
chmod -R 755 Assets/
```

### Partial Migration (Some Files Moved, Some Not)

**Symptom:** Migration completed but some files remain in old structure

**Cause:** Migration was interrupted or had errors

**Solution:**
1. Check migration output for errors
2. Run migration again (it will skip already-migrated files)
3. Manually investigate files that couldn't be migrated

## Performance Impact

- **File Creation:** No significant impact (just an extra directory level)
- **File Retrieval:** Slightly faster (fewer files per directory)
- **User Deletion:** Much faster (just delete one folder)
- **Disk Space:** No change

## Questions?

If you encounter issues or have questions about the migration, check:
1. Migration script output for detailed error messages
2. Application logs for runtime errors
3. Database for correct path formats
4. File system for correct directory structure

---

**Last Updated:** 2025-11-04
**Version:** 1.0
**Author:** Backend Team
