
namespace Backendv2.src.API.Routes.DTOs.userSettingsDto;

public partial class UserSettingsGetDTO
{
    public string id { get; set; } = null!;

    public bool contrast { get; set; }

    public bool light { get; set; }

    public bool dark { get; set; }

    public string language { get; set; } = null!;

    public bool sound { get; set; }

   public bool sentenceBar { get; set; }
}


public partial class UserSettingsPatchDTO
{
    public bool contrast { get; set; }

    public bool light { get; set; }

    public bool dark { get; set; }

    public string language { get; set; } = null!;

    public bool sound { get; set; }

   public bool sentenceBar { get; set; }
}

