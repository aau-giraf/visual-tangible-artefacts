namespace  Backendv2.src.API.Controllers.usersettingsController;

public class userSettings(
    int userID,
    bool contrast,
    bool light,
    bool dark,
    string language,
    bool sound,
    bool sentenceBar)
{
    public int userID { get; set; } = userID;
    public bool contrast { get; set; } = contrast;
    public bool light { get; set; } = light;
    public bool dark { get; set; } = dark;
    public string language { get; set; } = language;
    public bool sound { get; set; } = sound;
    public bool sentenceBar { get; set; } = sentenceBar;
}

public class userSettingsController
{
    private userSettings? settings;

    public userSettings getUserSettings(int userId)
    {
        // husk: Find the user and retrieve their settings

        return settings;

    }

    public string updateUserSettings(int userId, userSettings updatedSettings)
    {
       
        // husk: Find the user and update their settings
        // husk: Save changes to the database

        settings = updatedSettings;

        return "(204 no content)";
    }
}