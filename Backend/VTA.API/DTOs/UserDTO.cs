using VTA.Data.Models;

namespace VTA.API.DTOs;

public partial class UserPostDTO
{
    public required string? Name { get; set; }

    public required string Password { get; set; }

    public string Username { get; set; } = null!;

    public UserRole Role { get; set; } = UserRole.Child;
}

public partial class UserGetDTO
{
    public string Id { get; set; } = null!;

    public string? Name { get; set; }

    public string Username { get; set; } = null!;

    public bool NameVisible { get; set; }

    public int FieldCount { get; set; }

    public UserRole Role { get; set; }

    public virtual ICollection<CategoryGetDTO> Categories { get; set; } = new List<CategoryGetDTO>();
}

public class UserSignupDTO
{
    required public string Username { get; set; }
    required public string Password { get; set; }
    required public string Name { get; set; }
    public UserRole Role { get; set; } = UserRole.Child;
}

public class UserLoginDTO
{
    required public string Username { get; set; }
    required public string Password { get; set; }
}

public class UserLoginResponseDTO
{
    public string Token { get; set; } = null!;
    public string userId { get; set; }
}



/// <summary>
/// DTO for updating user settings
/// </summary>
public partial class UserPatchDTO
{
    /// <summary>
    /// Whether artefact names should be shown by default
    /// </summary>
    public bool? NameVisible { get; set; }
    
    /// <summary>
    /// Number of fields/columns in the linear layout
    /// </summary>
    public int? FieldCount { get; set; }
}
