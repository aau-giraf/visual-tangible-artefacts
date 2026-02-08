using VTA.API.Utilities;

namespace VTA.API.Services;

/// <summary>
/// ElevenLabs-backed implementation of <see cref="ITtsService"/>.
/// Registered as scoped in DI — controllers inject this instead of
/// manually instantiating <see cref="ElevenLabsService"/>.
/// </summary>
public class TtsService : ITtsService
{
    private static readonly HashSet<string> AllowedVoiceIds = new(StringComparer.OrdinalIgnoreCase)
    {
        ElevenLabsService.DefaultVoiceId,
        "Xb7hH8MSUJpSbSDYk0k2"
    };

    private readonly ElevenLabsService _elevenLabs;
    private readonly ILogger<TtsService> _logger;

    public TtsService(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<TtsService> logger)
    {
        _logger = logger;

        var apiKey = configuration["ElevenLabs:ApiKey"];
        if (string.IsNullOrEmpty(apiKey))
        {
            _logger.LogWarning("ElevenLabs:ApiKey is not configured — TTS calls will fail.");
            apiKey = string.Empty; // avoid null; calls will fail with 401 from ElevenLabs
        }

        var httpClient = httpClientFactory.CreateClient();
        _elevenLabs = new ElevenLabsService(httpClient, apiKey);
    }

    /// <inheritdoc />
    public async Task<byte[]?> GenerateSpeechAsync(
        string text,
        string? voiceId = null,
        string? modelId = null,
        double? stability = null,
        double? similarityBoost = null,
        bool? useSpeakerBoost = null,
        string? languageCode = null)
    {
        var resolvedVoice = ResolveVoiceId(voiceId);
        return await _elevenLabs.GenerateSpeechAsync(
            text,
            resolvedVoice,
            modelId,
            stability,
            similarityBoost,
            useSpeakerBoost,
            languageCode: languageCode);
    }

    /// <inheritdoc />
    public async Task<string?> GenerateAndSaveSpeechAsync(
        string text,
        string artefactId,
        string userId,
        string? voiceId = null,
        string? modelId = null,
        double? stability = null,
        double? similarityBoost = null,
        bool? useSpeakerBoost = null,
        string? languageCode = null)
    {
        var audioData = await GenerateSpeechAsync(
            text, voiceId, modelId, stability, similarityBoost, useSpeakerBoost, languageCode);

        if (audioData == null)
        {
            _logger.LogError("ElevenLabs returned null audio for artefact {ArtefactId}", artefactId);
            return null;
        }

        // Delete any existing sound for this artefact
        try { SoundUtilities.DeleteSound(artefactId, userId); }
        catch { /* may not exist yet */ }

        var soundPath = await SoundUtilities.AddSound(audioData, artefactId, userId);

        if (soundPath == null)
        {
            _logger.LogError("Failed to save generated audio for artefact {ArtefactId}", artefactId);
        }

        return soundPath;
    }

    /// <inheritdoc />
    public string ResolveVoiceId(string? requestedVoiceId)
    {
        if (string.IsNullOrWhiteSpace(requestedVoiceId))
        {
            return ElevenLabsService.DefaultVoiceId;
        }

        var normalized = requestedVoiceId.Trim();
        if (AllowedVoiceIds.Contains(normalized))
        {
            return normalized;
        }

        _logger.LogWarning("Unsupported voiceId '{VoiceId}' — falling back to default", requestedVoiceId);
        return ElevenLabsService.DefaultVoiceId;
    }
}
