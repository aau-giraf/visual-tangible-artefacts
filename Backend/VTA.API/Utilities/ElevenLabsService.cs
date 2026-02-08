using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;

namespace VTA.API.Utilities;

/// <summary>
/// Service for interacting with ElevenLabs Text-to-Speech API
/// </summary>
public class ElevenLabsService
{
    private const string BaseUrl = "https://api.elevenlabs.io/v1";
    public const string DefaultVoiceId = "Bj9UqZbhQsanLzgalpEG"; // Danish voice
    private const string DefaultModelId = "eleven_turbo_v2_5"; // Turbo multilingual model for better language support

    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private readonly ILogger _logger;

    /// <summary>
    /// Initialize the ElevenLabs service
    /// </summary>
    /// <param name="httpClient">HTTP client for making requests</param>
    /// <param name="apiKey">ElevenLabs API key</param>
    /// <param name="logger">Logger instance</param>
    public ElevenLabsService(HttpClient httpClient, string apiKey, ILogger logger)
    {
        _httpClient = httpClient;
        _apiKey = apiKey;
        _logger = logger;
        
        // Don't set BaseAddress, use absolute URLs instead
        _httpClient.DefaultRequestHeaders.Add("xi-api-key", _apiKey);
    }

    /// <summary>
    /// Generate speech from text using ElevenLabs API
    /// </summary>
    /// <param name="text">Text to convert to speech</param>
    /// <param name="voiceId">Voice ID (optional, uses default if not provided)</param>
    /// <param name="modelId">Model ID (optional, uses default if not provided)</param>
    /// <param name="stability">Voice stability (0.0 to 1.0)</param>
    /// <param name="similarityBoost">Similarity boost (0.0 to 1.0)</param>
    /// <param name="useSpeakerBoost">Whether to use speaker boost</param>
    /// <param name="speed">Speaking speed (0.25 to 4.0, default 1.0 = normal speed)</param>
    /// <param name="languageCode">Language code (e.g., "da" for Danish, "en" for English)</param>
    /// <returns>Audio data as byte array or null if failed</returns>
    public async Task<byte[]?> GenerateSpeechAsync(
        string text,
        string? voiceId = null,
        string? modelId = null,
        double? stability = null,
        double? similarityBoost = null,
        bool? useSpeakerBoost = null,
        double? speed = null,
        string? languageCode = null)
    {
        try
        {
            var effectiveVoiceId = voiceId ?? DefaultVoiceId;
            var effectiveModelId = modelId ?? DefaultModelId;

            // Build request body with proper structure for JSON serialization
            var voiceSettings = new Dictionary<string, object>
            {
                ["stability"] = stability ?? 0.5,
                ["similarity_boost"] = similarityBoost ?? 0.75,
                ["use_speaker_boost"] = useSpeakerBoost ?? true,
                ["speed"] = speed ?? 0.8  // Default to 0.8 (slightly slower than normal) for better clarity
            };

            var requestBodyDict = new Dictionary<string, object>
            {
                ["text"] = text,
                ["model_id"] = effectiveModelId,
                ["voice_settings"] = voiceSettings
            };

            // Add language_code if provided (for multilingual models)
            if (!string.IsNullOrEmpty(languageCode))
            {
                requestBodyDict["language_code"] = languageCode;
            }

            var json = JsonSerializer.Serialize(requestBodyDict);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            _logger.LogDebug("ElevenLabs request to voice {VoiceId}, model {ModelId}, language {LanguageCode}", effectiveVoiceId, effectiveModelId, languageCode ?? "null");
            _logger.LogDebug("Request body: {RequestBody}", json);

            var response = await _httpClient.PostAsync($"{BaseUrl}/text-to-speech/{effectiveVoiceId}", content);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogDebug("ElevenLabs API success");
                return await response.Content.ReadAsByteArrayAsync();
            }

            var errorContent = await response.Content.ReadAsStringAsync();
            _logger.LogWarning("ElevenLabs API error - Status: {StatusCode}, Body: {ErrorContent}", response.StatusCode, errorContent);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ElevenLabs GenerateSpeechAsync error");
            return null;
        }
    }

    /// <summary>
    /// Get available voices from ElevenLabs API
    /// </summary>
    /// <returns>JSON string with voice data or null if failed</returns>
    public async Task<string?> GetVoicesAsync()
    {
        try
        {
            var response = await _httpClient.GetAsync("/voices");

            if (response.IsSuccessStatusCode)
            {
                return await response.Content.ReadAsStringAsync();
            }

            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ElevenLabs GetVoicesAsync error");
            return null;
        }
    }

    /// <summary>
    /// Get user information and quota from ElevenLabs API
    /// </summary>
    /// <returns>JSON string with user data or null if failed</returns>
    public async Task<string?> GetUserInfoAsync()
    {
        try
        {
            var response = await _httpClient.GetAsync("/user");

            if (response.IsSuccessStatusCode)
            {
                return await response.Content.ReadAsStringAsync();
            }

            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ElevenLabs GetUserInfoAsync error");
            return null;
        }
    }

    /// <summary>
    /// Validate API key by making a test request
    /// </summary>
    /// <returns>True if API key is valid, false otherwise</returns>
    public async Task<bool> ValidateApiKeyAsync()
    {
        try
        {
            var userInfo = await GetUserInfoAsync();
            return !string.IsNullOrEmpty(userInfo);
        }
        catch
        {
            return false;
        }
    }
}
