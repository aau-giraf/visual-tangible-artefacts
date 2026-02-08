using Microsoft.EntityFrameworkCore;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Utilities;

/// <summary>
/// Shared helper for cleaning up all filesystem assets and DB entities when deleting a user.
/// Used by both <see cref="Controllers.UsersController"/> and <see cref="Controllers.AdminController"/>
/// to ensure artefact images, sounds, and board snapshots are not orphaned on disk.
/// </summary>
public static class UserCleanupHelper
{
    /// <summary>
    /// Loads a user with all related entities, deletes their filesystem assets
    /// (images, sounds, board snapshots), removes DB entities, and saves changes.
    /// </summary>
    /// <param name="context">The database context.</param>
    /// <param name="userId">The ID of the user to delete.</param>
    /// <returns>The deleted <see cref="User"/>, or <c>null</c> if not found.</returns>
    public static async Task<User?> DeleteUserWithAssets(VTAContext context, string userId)
    {
        var user = await context.Users
            .Include(u => u.Categories)
                .ThenInclude(c => c.Artefacts)
            .Include(u => u.SavedBoards)
                .ThenInclude(sb => sb.SavedArtefacts)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null)
        {
            return null;
        }

        // Delete artefact and category images/sounds from the filesystem
        // before we lose the references via cascade delete.
        foreach (var category in user.Categories)
        {
            foreach (var artefact in category.Artefacts)
            {
                ImageUtilities.DeleteImage(artefact.ArtefactId, "Artefacts", userId);
                try
                {
                    SoundUtilities.DeleteSound(artefact.ArtefactId, userId);
                }
                catch { }
            }
            ImageUtilities.DeleteImage(category.CategoryId, "Categories", userId);
        }

        // Delete saved board snapshots and entities
        foreach (var savedBoard in user.SavedBoards.ToList())
        {
            if (!string.IsNullOrEmpty(savedBoard.SnapshotPath))
            {
                try
                {
                    var snapshotPath = Path.Combine("wwwroot", savedBoard.SnapshotPath.TrimStart('/'));
                    if (File.Exists(snapshotPath))
                    {
                        File.Delete(snapshotPath);
                    }
                }
                catch { }
            }

            foreach (var savedArtefact in savedBoard.SavedArtefacts.ToList())
            {
                context.SavedArtefacts.Remove(savedArtefact);
            }

            context.SavedBoards.Remove(savedBoard);
        }

        context.Users.Remove(user);
        await context.SaveChangesAsync();

        return user;
    }
}
