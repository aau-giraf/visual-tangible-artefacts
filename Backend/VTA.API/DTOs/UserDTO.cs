namespace VTA.API.DTOs;

public partial class UserPostDTO
{
    public required string? Name { get; set; }

    public required string Password { get; set; }

    public string GuardianKey { get; set; } = null!;

    public string Username { get; set; } = null!;
}

public partial class UserGetDTO
{
    public string Id { get; set; } = null!;

    public string? Name { get; set; }

    public string GuardianKey { get; set; } = null!;

    public string Username { get; set; } = null!;

    public virtual ICollection<CategoryGetDTO> Categories { get; set; } = new List<CategoryGetDTO>();


}

public class UserSignupDTO
{
    required public string Username { get; set; }
    required public string Password { get; set; }
    required public string Name { get; set; }
    public string? GuardianKey {get; set; }
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



