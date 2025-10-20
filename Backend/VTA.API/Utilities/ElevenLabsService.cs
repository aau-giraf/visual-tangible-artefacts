using System.Text;
using System.Text.Json;

namespace VTA.API.Utilities;

/// <summary>
/// Service for interacting with ElevenLabs Text-to-Speech API
/// </summary>
public class ElevenLabsService
{
    private const string BaseUrl = "https://api.elevenlabs.io/v1";
    private const string DefaultVoiceId = "Bj9UqZbhQsanLzgalpEG"; // Danish voice
    private const string DefaultModelId = "eleven_turbo_v2_5"; // Turbo multilingual model for better language support

    private readonly HttpClient _httpClient;
    private readonly string _apiKey;

    /// <summary>
    /// Initialize the ElevenLabs service
    /// </summary>
    /// <param name="httpClient">HTTP client for making requests</param>
    /// <param name="apiKey">ElevenLabs API key</param>
    public ElevenLabsService(HttpClient httpClient, string apiKey)
    {
        _httpClient = httpClient;
        _apiKey = apiKey;
        
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
    /// <param name="languageCode">Language code (e.g., "da" for Danish, "en" for English)</param>
    /// <returns>Audio data as byte array or null if failed</returns>
    public async Task<byte[]?> GenerateSpeechAsync(
        string text,
        string? voiceId = null,
        string? modelId = null,
        double? stability = null,
        double? similarityBoost = null,
        bool? useSpeakerBoost = null,
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
                ["use_speaker_boost"] = useSpeakerBoost ?? true
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

            Console.WriteLine($"Debug: ElevenLabs request to voice {effectiveVoiceId}");
            Console.WriteLine($"Debug: Model ID: {effectiveModelId}");
            Console.WriteLine($"Debug: Language Code: {languageCode ?? "null"}");
            Console.WriteLine($"Debug: Request body: {json}");

            var response = await _httpClient.PostAsync($"{BaseUrl}/text-to-speech/{effectiveVoiceId}", content);

            if (response.IsSuccessStatusCode)
            {
                Console.WriteLine($"Debug: ElevenLabs API success");
                return await response.Content.ReadAsByteArrayAsync();
            }

            var errorContent = await response.Content.ReadAsStringAsync();
            Console.WriteLine($"Debug: ElevenLabs API error - Status: {response.StatusCode}, Body: {errorContent}");
            return null;
        }
        catch (Exception ex)
        {
            // Log error (in a real application, use proper logging)
            Console.WriteLine($"ElevenLabs API error: {ex.Message}");
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
            Console.WriteLine($"ElevenLabs API error: {ex.Message}");
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
            Console.WriteLine($"ElevenLabs API error: {ex.Message}");
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