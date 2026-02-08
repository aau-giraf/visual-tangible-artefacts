using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Services;

/// <summary>
/// Concrete implementation of <see cref="IRelationService"/>.
/// Consolidates pairing logic that was previously duplicated across
/// AdminController, RelationController, ContactsController, and UsersController.
/// </summary>
public class RelationService : IRelationService
{
    private readonly VTAContext _context;

    public RelationService(VTAContext context)
    {
        _context = context;
    }

    /// <inheritdoc />
    public async Task<List<PairingDTO>> GetAllPairingsAsync(bool? activeOnly = null, int? skip = null, int? take = null)
    {
        var query = _context.Relations
            .Include(p => p.Caregiver)
            .Include(p => p.Child)
            .AsNoTracking();

        if (activeOnly == true)
        {
            query = query.Where(p => p.IsActive);
        }

        if (skip.HasValue || take.HasValue)
        {
            var resolvedSkip = Math.Max(skip ?? 0, 0);
            var resolvedTake = Math.Clamp(take ?? 50, 1, 200);
            var pairings = await query.Skip(resolvedSkip).Take(resolvedTake).ToListAsync();
            return pairings.Select(MapToPairingDTO).ToList();
        }

        var allPairings = await query.ToListAsync();
        return allPairings.Select(MapToPairingDTO).ToList();
    }

    /// <inheritdoc />
    public async Task<List<PairingDTO>> GetPairingsForCaregiverAsync(string caregiverId, int? skip = null, int? take = null)
    {
        var query = _context.Relations
            .Include(p => p.Caregiver)
            .Include(p => p.Child)
            .Where(p => p.CaregiverId == caregiverId && p.IsActive)
            .AsNoTracking();

        if (skip.HasValue || take.HasValue)
        {
            var resolvedSkip = Math.Max(skip ?? 0, 0);
            var resolvedTake = Math.Clamp(take ?? 50, 1, 200);
            var pairings = await query.Skip(resolvedSkip).Take(resolvedTake).ToListAsync();
            return pairings.Select(MapToPairingDTO).ToList();
        }

        var allPairings = await query.ToListAsync();
        return allPairings.Select(MapToPairingDTO).ToList();
    }

    /// <inheritdoc />
    public async Task<List<UserGetDTO>> GetRelatedContactsAsync(string userId)
    {
        var currentUser = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (currentUser == null)
        {
            return new List<UserGetDTO>();
        }

        if (currentUser.Role == UserRole.Caregiver)
        {
            var children = await _context.Relations
                .Where(r => r.CaregiverId == userId && r.IsActive)
                .Include(r => r.Child)
                .AsNoTracking()
                .ToListAsync();

            return children
                .Select(r => DTOConverter.MapUserToUserGetDTO(r.Child))
                .ToList();
        }

        if (currentUser.Role == UserRole.Child)
        {
            var caregivers = await _context.Relations
                .Where(r => r.ChildId == userId && r.IsActive)
                .Include(r => r.Caregiver)
                .AsNoTracking()
                .ToListAsync();

            return caregivers
                .Select(r => DTOConverter.MapUserToUserGetDTO(r.Caregiver))
                .ToList();
        }

        return new List<UserGetDTO>();
    }

    /// <inheritdoc />
    public async Task<(PairingDTO? Pairing, string? Error)> CreatePairingAsync(
        string caregiverId, string childId)
    {
        var caregiver = await _context.Users.FindAsync(caregiverId);
        if (caregiver == null)
            return (null, "Caregiver not found");
        if (caregiver.Role != UserRole.Caregiver)
            return (null, "The specified user is not a caregiver");

        var child = await _context.Users.FindAsync(childId);
        if (child == null)
            return (null, "Child not found");
        if (child.Role != UserRole.Child)
            return (null, "The specified user is not a child");

        var exists = await _context.Relations
            .AnyAsync(p => p.CaregiverId == caregiverId
                        && p.ChildId == childId
                        && p.IsActive);

        if (exists)
            return (null, "Pairing already exists");

        var pairing = new Relation
        {
            CaregiverId = caregiverId,
            ChildId = childId,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Relations.Add(pairing);
        await _context.SaveChangesAsync();

        // Reload navigation properties for the DTO
        await _context.Entry(pairing).Reference(p => p.Caregiver).LoadAsync();
        await _context.Entry(pairing).Reference(p => p.Child).LoadAsync();

        return (MapToPairingDTO(pairing), null);
    }

    /// <inheritdoc />
    public async Task<bool> RemovePairingAsync(string id)
    {
        var pairing = await _context.Relations.FindAsync(id);
        if (pairing == null)
            return false;

        pairing.IsActive = false;
        await _context.SaveChangesAsync();
        return true;
    }

    /// <inheritdoc />
    public async Task<bool> RemovePairingByIdsAsync(string caregiverId, string childId)
    {
        var pairing = await _context.Relations
            .FirstOrDefaultAsync(p => p.CaregiverId == caregiverId
                                   && p.ChildId == childId
                                   && p.IsActive);

        if (pairing == null)
            return false;

        pairing.IsActive = false;
        await _context.SaveChangesAsync();
        return true;
    }

    // ── helpers ──────────────────────────────────────────────────────────

    private static PairingDTO MapToPairingDTO(Relation r) => new()
    {
        Id = r.Id,
        CaregiverId = r.CaregiverId,
        ChildId = r.ChildId,
        IsActive = r.IsActive,
        CreatedAt = r.CreatedAt,
        Caregiver = DTOConverter.MapUserToUserGetDTO(r.Caregiver),
        Child = DTOConverter.MapUserToUserGetDTO(r.Child)
    };
}
