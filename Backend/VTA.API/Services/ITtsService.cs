namespace VTA.API.Services;

/// <summary>
/// Service for generating text-to-speech audio via ElevenLabs API.
/// </summary>
public interface ITtsService
{
    /// <summary>
    /// Generate speech audio from text.
    /// </summary>
    /// <param name="text">Text to convert to speech</param>
    /// <param name="voiceId">Optional voice ID (falls back to default Danish voice)</param>
    /// <param name="modelId">Optional model ID (falls back to turbo v2.5)</param>
    /// <param name="stability">Voice stability (0.0–1.0)</param>
    /// <param name="similarityBoost">Similarity boost (0.0–1.0)</param>
    /// <param name="useSpeakerBoost">Whether to use speaker boost</param>
    /// <param name="languageCode">Language code (e.g. "da" for Danish)</param>
    /// <returns>Audio data as byte array, or null if generation failed</returns>
    Task<byte[]?> GenerateSpeechAsync(
        string text,
        string? voiceId = null,
        string? modelId = null,
        double? stability = null,
        double? similarityBoost = null,
        bool? useSpeakerBoost = null,
        string? languageCode = null);

    /// <summary>
    /// Generate speech and save it to the filesystem for a given artefact.
    /// </summary>
    /// <param name="text">Text to convert to speech</param>
    /// <param name="artefactId">Artefact ID (used as filename)</param>
    /// <param name="userId">Owner's user ID (used for asset path)</param>
    /// <param name="voiceId">Optional voice ID</param>
    /// <param name="modelId">Optional model ID</param>
    /// <param name="stability">Voice stability</param>
    /// <param name="similarityBoost">Similarity boost</param>
    /// <param name="useSpeakerBoost">Whether to use speaker boost</param>
    /// <param name="languageCode">Language code</param>
    /// <returns>The saved sound file path, or null if failed</returns>
    Task<string?> GenerateAndSaveSpeechAsync(
        string text,
        string artefactId,
        string userId,
        string? voiceId = null,
        string? modelId = null,
        double? stability = null,
        double? similarityBoost = null,
        bool? useSpeakerBoost = null,
        string? languageCode = null);

    /// <summary>
    /// Resolve a voice ID to a valid allowed voice, falling back to default.
    /// </summary>
    string ResolveVoiceId(string? requestedVoiceId);
}
