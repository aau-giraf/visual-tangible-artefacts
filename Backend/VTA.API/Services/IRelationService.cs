using VTA.API.DTOs;

namespace VTA.API.Services;

/// <summary>
/// Service for caregiver-child relation (pairing) management.
/// Single source of truth — replaces duplicated logic in
/// AdminController, RelationController, ContactsController, and UsersController.
/// </summary>
public interface IRelationService
{
    /// <summary>Get all pairings, optionally filtering by active status.</summary>
    Task<List<PairingDTO>> GetAllPairingsAsync(bool? activeOnly = null, int? skip = null, int? take = null);

    /// <summary>Get pairings for a specific caregiver.</summary>
    Task<List<PairingDTO>> GetPairingsForCaregiverAsync(string caregiverId, int? skip = null, int? take = null);

    /// <summary>
    /// Get the related contacts for a user (children if caregiver, caregivers if child).
    /// </summary>
    Task<List<UserGetDTO>> GetRelatedContactsAsync(string userId);

    /// <summary>
    /// Create a new caregiver-child pairing.
    /// Returns the created PairingDTO, or null with an error message if validation fails.
    /// </summary>
    Task<(PairingDTO? Pairing, string? Error)> CreatePairingAsync(string caregiverId, string childId);

    /// <summary>Soft-delete a pairing by its ID (sets IsActive = false).</summary>
    /// <returns>True if found and deactivated, false if not found.</returns>
    Task<bool> RemovePairingAsync(string id);

    /// <summary>Soft-delete a pairing by caregiver + child IDs.</summary>
    /// <returns>True if found and deactivated, false if not found.</returns>
    Task<bool> RemovePairingByIdsAsync(string caregiverId, string childId);
}
