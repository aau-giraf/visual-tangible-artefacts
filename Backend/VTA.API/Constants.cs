namespace VTA.API;

/// <summary>
/// Centralized constants used throughout the VTA API.
/// </summary>
public static class Constants
{
    /// <summary>
    /// Default board name created for new users during signup.
    /// </summary>
    public const string DefaultBoardName = "Board1";

    /// <summary>
    /// Category identifier for session-scoped artefacts that are cleaned up when a board is cleared.
    /// </summary>
    public const string SessionArtefactCategory = "Session-Artefact";

    /// <summary>
    /// Prefix added to image filenames for clarity in the filesystem.
    /// </summary>
    public const string ImageFilePrefix = "image_";

    /// <summary>
    /// Directory names for asset storage.
    /// </summary>
    public static class AssetDirectories
    {
        public const string Artefacts = "Artefacts";
        public const string Categories = "Categories";
        public const string Sounds = "Sounds";
    }
}
