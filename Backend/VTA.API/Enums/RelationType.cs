namespace VTA.API.Enums;

/// <summary>
/// Represents the type of relationship between a caregiver and a child
/// </summary>
public enum RelationType
{
    Caregiver,
    Guardian,
    Parent
}

/// <summary>
/// Represents the status of an invite
/// </summary>
public enum InviteStatus
{
    Pending,
    Accepted,
    Declined
}

/// <summary>
/// Represents the role of a user in the system
/// </summary>
public enum UserRole
{
    Admin,
    Caregiver,
    Child
}

/// <summary>
/// Represents the status of a relationship between a caregiver and a child
/// </summary>
public enum RelationStatus
{
    Pending,
    Active,
    Inactive,
    Rejected
}

/// <summary>
/// Represents the status of a session
/// </summary>
public enum SessionStatus
{
    Active,
    Completed,
    Cancelled
}