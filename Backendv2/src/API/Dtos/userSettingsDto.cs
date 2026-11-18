using Backendv2.DB.Data.Models.VTAModels;

namespace Backendv2.src.API.Routes.DTOs.userSettingsDto;

public class UserSettingsDto
{
    public bool Contrast {get; set;}
    public bool Lightmode {get; set;}
    public bool Darkmode {get; set;}
    public string Language {get; set;} = null!;
    public bool SentenceBar {get; set;}


    public UserSettingsDto() { }
    public UserSettingsDto(UserSetting UserSetting) => 
    (Contrast, Lightmode, Darkmode, Language, SentenceBar) = (UserSetting.Contrast, UserSetting.Lightmode, UserSetting. Darkmode, UserSetting. Language, UserSetting.SentenceBar);
}