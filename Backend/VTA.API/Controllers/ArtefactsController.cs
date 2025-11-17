using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
using VTA.API.Utilities;

namespace VTA.API.Controllers;

[Authorize]//Lock all endpoints behind JWT
[Route("api/Users/Artefacts")]//We designed the route so that *Users* OWNS *Artefacts* and this route reflects it
[ApiController]
public class ArtefactsController(VTAContext context) : ControllerBase
{
    // GET: api/Artefacts
    /// <summary>
    /// Gets all artefacts that a user owns
    /// </summary>
    /// <returns>An IEnumerable of artefacts</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ArtefactGetDTO>>> GetArtefacts()
    {
        var userId = User.FindFirst("id")?.Value;

        List<Artefact>? artefacts = await context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId)
            .ToListAsync();
        if (artefacts == null)
        {
            return NotFound();
        }

        var artefactGetDTOs = artefacts
            .Select(artefact => DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString()))
            .ToList();

        return artefactGetDTOs;
    }

    // GET: api/Artefacts/5
    /// <summary>
    /// Gets a specific artefact
    /// </summary>
    /// <param name="artefactId">The artefact to get</param>
    /// <returns>The specified artefact</returns>
    [HttpGet("{artefactId}")]
    public async Task<ActionResult<ArtefactGetDTO>> GetArtefact(string artefactId)
    {
        var userId = User.FindFirst("id")?.Value;

        var artefact = await context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId)
            .FirstOrDefaultAsync(a => a.ArtefactId == artefactId);
        if (artefact == null)
        {
            return NotFound();
        }

        ArtefactGetDTO artefactGetDTO = DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());

        return artefactGetDTO;
    }

    // PATCH: api/Artefacts/5
    // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
    /// <summary>
    /// Updates an artefacts information
    /// </summary>
    /// <param name="dto"></param>
    /// <returns></returns>
    [HttpPatch]
    [DisableRequestSizeLimit, RequestFormLimits(MultipartBodyLengthLimit = Int32.MaxValue, ValueLengthLimit = Int32.MaxValue)]
    public async Task<IActionResult> PatchArtefact([FromForm] ArtefactPatchDTO dto)
    {
        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var artefact = context.Artefacts.Find(dto.ArtefactId);

        if (artefact == null)
        {
            return BadRequest();
        }

        if (dto.ArtefactIndex != null && artefact.ArtefactIndex != dto.ArtefactIndex)
        {
            artefact.ArtefactIndex = dto.ArtefactIndex.Value;
        }
        if (!string.IsNullOrEmpty(dto.Name) && artefact.Name != dto.Name)
        {
            artefact.Name = dto.Name;
        }
        if (dto.NameShown != null && artefact.NameShown != dto.NameShown)
        {
            artefact.NameShown = dto.NameShown;
        }

        if (dto.Image != null && !string.IsNullOrEmpty(artefact.CategoryId))
        {
            ImageUtilities.DeleteImage(artefact.CategoryId, "Categories", userId);
            await ImageUtilities.AddImage(dto.Image, artefact.CategoryId, "Categories", userId);
        }
        if (dto.Sound != null)
        {
            // Delete any existing sound for this artefact
            try
            {
                SoundUtilities.DeleteSound(artefact.ArtefactId, userId);
            }
            catch { }
            // Save sound file using SoundUtilities: ArtefactId + extension in Assets/Sounds
            var soundPath = await SoundUtilities.AddSound(dto.Sound, artefact.ArtefactId, userId);
            artefact.SoundPath = soundPath;
        }

        context.Entry(artefact).State = EntityState.Modified;

        try
        {
            await context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!ArtefactExists(artefact.ArtefactId))
            {
                return NotFound();
            }
            else
            {
                throw;
            }
        }

        return NoContent();
    }

    // POST: api/Artefacts
    // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
    /// <summary>
    /// Creates a new artefact
    /// </summary>
    /// <param name="ArtefactPostDTO">An object with all artefact info</param>
    /// <returns>
    /// Status code 200 (Ok) to the client on success (Ok should also have the item with it)<br />
    /// Status code 403 (Forbidden) if a client tries to add an artefact to someone else<br />
    /// </returns>
    [HttpPost]
    [DisableRequestSizeLimit, RequestFormLimits(MultipartBodyLengthLimit = Int32.MaxValue, ValueLengthLimit = Int32.MaxValue)]
    public async Task<ActionResult<ArtefactGetDTO>> PostArtefact(ArtefactPostDTO artefactPostDTO)
    {

        Console.WriteLine("----------------------------------------" + artefactPostDTO.Name);
        Console.WriteLine("----------------------------------------");
        var userId = User.FindFirst("id")?.Value;

        if (userId != artefactPostDTO.UserId)
        {
            return Forbid();
        }



        string artefactId = Guid.NewGuid().ToString();
        string? imageUrl = await ImageUtilities.AddImage(artefactPostDTO.Image, artefactId, "Artefacts", userId);
        string? soundUrl = null;

        // Debug logging for sound data
        Console.WriteLine($"Debug: PostArtefact - Sound data present: {artefactPostDTO.Sound != null}");
        if (artefactPostDTO.Sound != null)
        {
            Console.WriteLine($"Debug: PostArtefact - Sound file size: {artefactPostDTO.Sound.Length} bytes");
            Console.WriteLine($"Debug: PostArtefact - Sound file name: {artefactPostDTO.Sound.FileName}");
            soundUrl = await SoundUtilities.AddSound(artefactPostDTO.Sound, artefactId, userId);
            Console.WriteLine($"Debug: PostArtefact - Sound saved to: {soundUrl}");
        }
        Artefact artefact = DTOConverter.MapArtefactPostDTOToArtefact(artefactPostDTO, artefactId, imageUrl, soundUrl);
        artefact.UserId = userId;
        artefact.Name = artefactPostDTO.Name;
        

        context.Artefacts.Add(artefact);
        try
        {
            await context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            if (ArtefactExists(artefact.ArtefactId))
            {
                //Chance of this happening is infinitely small ! But never zero !
                while (ArtefactExists(artefact.ArtefactId))
                {
                    artefact.ArtefactId = Guid.NewGuid().ToString();
                }
                await context.SaveChangesAsync();
            }
            else
            {
                throw;
            }
        }

        ArtefactGetDTO artefactGetDTO = DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());

        return Ok(artefactGetDTO);
    }

    // DELETE: api/Artefacts/5
    /// <summary>
    /// Deletes an artefact using its ID
    /// </summary>
    /// <param name="artefactId">The artefacts ID</param>
    /// <returns>
    /// Status code 204 (No content) to the client on success<br />
    /// Status code 403 (Forbidden) if a client tries to delete an artefact that they do not own<br />
    /// Status code 404 (Not Found) if the artefact does not exist
    /// </returns>
    [HttpDelete("{artefactId}")]
    public async Task<IActionResult> DeleteArtefact(string artefactId)
    {
        var userId = User.FindFirst("id")?.Value;

        var artefact = await context.Artefacts.FindAsync(artefactId);
        if (artefact == null)
        {
            return NotFound();
        }

        if (userId != artefact.UserId)
        {
            return Forbid();
        }
        ImageUtilities.DeleteImage(artefact.ArtefactId, "Artefacts", userId);
        // Also remove associated sound file if present
        try
        {
            SoundUtilities.DeleteSound(artefact.ArtefactId, userId);
        }
        catch { }

        context.Artefacts.Remove(artefact);
        await context.SaveChangesAsync();

        return NoContent();
    }

    /// <summary>
    /// Generate speech from text using ElevenLabs API (simple version for new artefacts)
    /// </summary>
    /// <param name="request">Simple text-to-speech request</param>
    /// <returns>
    /// Status code 200 (Ok) with audio data on success<br />
    /// Status code 400 (Bad Request) if the request is invalid<br />
    /// Status code 500 (Internal Server Error) if ElevenLabs API fails
    /// </returns>
    [HttpPost("generate-speech-simple")]
    public async Task<IActionResult> GenerateSpeechSimple([FromBody] SimpleTtsRequest request)
    {
        // Validate text input
        if (string.IsNullOrWhiteSpace(request.Text))
        {
            return BadRequest(new { error = "Text cannot be empty" });
        }

        try
        {
            // Get ElevenLabs API key from configuration
            var configuration = HttpContext.RequestServices.GetRequiredService<IConfiguration>();
            var apiKey = configuration["ElevenLabs:ApiKey"];
            
            if (string.IsNullOrEmpty(apiKey))
            {
                return StatusCode(500, "ElevenLabs API key not configured");
            }

            // Create ElevenLabs service
            var httpClientFactory = HttpContext.RequestServices.GetRequiredService<IHttpClientFactory>();
            var httpClient = httpClientFactory.CreateClient();
            var elevenLabsService = new ElevenLabsService(httpClient, apiKey);

            // Generate speech with multilingual support for Danish
            // Backend controls the voice - frontend doesn't specify it
            var audioData = await elevenLabsService.GenerateSpeechAsync(
                text: request.Text,
                // voiceId not specified - uses backend default (Bj9UqZbhQsanLzgalpEG)
                modelId: "eleven_turbo_v2_5", // Use v2.5 turbo model (supports audio tags + multilingual)
                languageCode: "da" // Explicitly set Danish
            );

            if (audioData == null)
            {
                return StatusCode(500, "Failed to generate speech from ElevenLabs API");
            }

            // Return audio data directly
            return File(audioData, "audio/mpeg", "generated_speech");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error generating speech: {ex.Message}");
            return StatusCode(500, "Internal server error while generating speech");
        }
    }

    /// <summary>
    /// Generate speech from text and save it to an artefact using ElevenLabs API
    /// </summary>
    /// <param name="request">Text-to-speech request with artefact ID</param>
    /// <returns>
    /// Status code 200 (Ok) with the sound URL on success<br />
    /// Status code 400 (Bad Request) if the request is invalid<br />
    /// Status code 403 (Forbidden) if the user doesn't own the artefact<br />
    /// Status code 404 (Not Found) if the artefact doesn't exist<br />
    /// Status code 500 (Internal Server Error) if ElevenLabs API fails
    /// </returns>
    [HttpPost("generate-speech-and-save")]
    public async Task<IActionResult> GenerateSpeechAndSave([FromBody] ArtefactTtsRequest request)
    {
        // Validate input
        if (string.IsNullOrWhiteSpace(request.Text))
        {
            return BadRequest(new { error = "Text cannot be empty" });
        }

        if (string.IsNullOrWhiteSpace(request.ArtefactId))
        {
            return BadRequest(new { error = "ArtefactId cannot be empty" });
        }

        try
        {
            // Check if artefact exists and user owns it
            var userId = User.FindFirst("id")?.Value;

            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized();
            }

            var artefact = await context.Artefacts
                .Where(a => a.UserId == userId && a.ArtefactId == request.ArtefactId)
                .FirstOrDefaultAsync();

            if (artefact == null)
            {
                return NotFound("Artefact not found or you don't have permission to modify it");
            }

            // Get ElevenLabs API key from configuration
            var configuration = HttpContext.RequestServices.GetRequiredService<IConfiguration>();
            var apiKey = configuration["ElevenLabs:ApiKey"];
            
            if (string.IsNullOrEmpty(apiKey))
            {
                return StatusCode(500, "ElevenLabs API key not configured");
            }

            // Create ElevenLabs service
            var httpClientFactory = HttpContext.RequestServices.GetRequiredService<IHttpClientFactory>();
            var httpClient = httpClientFactory.CreateClient();
            var elevenLabsService = new ElevenLabsService(httpClient, apiKey);

            // Generate speech with multilingual support for Danish
            // Backend controls the voice - frontend doesn't specify it
            var audioData = await elevenLabsService.GenerateSpeechAsync(
                text: request.Text,
                // voiceId not specified - uses backend default (Bj9UqZbhQsanLzgalpEG)
                modelId: "eleven_turbo_v2_5", // Use v2.5 turbo model (supports audio tags + multilingual)
                languageCode: "da" // Explicitly set Danish
            );

            if (audioData == null)
            {
                return StatusCode(500, "Failed to generate speech from ElevenLabs API");
            }

            // Save the audio data to file system using SoundUtilities
            var soundUrl = await SoundUtilities.AddSound(audioData, request.ArtefactId, userId);

            if (soundUrl == null)
            {
                return StatusCode(500, "Failed to save generated audio file");
            }

            // Update artefact with sound path
            artefact.SoundPath = soundUrl;
            await context.SaveChangesAsync();

            // Return the sound URL
            return Ok(new { soundUrl = soundUrl, message = "Speech generated and saved successfully" });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error generating and saving speech: {ex.Message}");
            return StatusCode(500, "Internal server error while generating and saving speech");
        }
    }

    /// <summary>
    /// Generate speech from text and save it with a unique ID
    /// </summary>
    /// <param name="request">Text-to-speech request</param>
    /// <returns>
    /// Status code 200 (Ok) with the sound URL on success<br />
    /// Status code 400 (Bad Request) if the request is invalid<br />
    /// Status code 500 (Internal Server Error) if ElevenLabs API fails
    /// </returns>
    [HttpPost("generate-and-save-speech")]
    public async Task<IActionResult> GenerateAndSaveSpeech([FromBody] StandaloneTtsRequest request)
    {
        // Validate input
        if (string.IsNullOrWhiteSpace(request.Text))
        {
            return BadRequest(new { error = "Text cannot be empty" });
        }

        try
        {
            var userId = User.FindFirst("id")?.Value;

            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized();
            }

            // Get ElevenLabs API key from configuration
            var configuration = HttpContext.RequestServices.GetRequiredService<IConfiguration>();
            var apiKey = configuration["ElevenLabs:ApiKey"];

            if (string.IsNullOrEmpty(apiKey))
            {
                return StatusCode(500, "ElevenLabs API key not configured");
            }

            // Create ElevenLabs service
            var httpClientFactory = HttpContext.RequestServices.GetRequiredService<IHttpClientFactory>();
            var httpClient = httpClientFactory.CreateClient();
            var elevenLabsService = new ElevenLabsService(httpClient, apiKey);

            // Generate speech using v2.5 turbo model which supports audio tags
            var audioData = await elevenLabsService.GenerateSpeechAsync(
                text: request.Text,
                voiceId: request.VoiceId ?? "Bj9UqZbhQsanLzgalpEG", // Default to your specified voice
                modelId: "eleven_turbo_v2_5" // v2.5 model supports audio tags like <break>, <emphasis>, etc.
            );

            if (audioData == null)
            {
                return StatusCode(500, "Failed to generate speech from ElevenLabs API");
            }

            // Generate unique ID for the sound file
            var soundId = Guid.NewGuid().ToString();

            // Save the audio data to file system using SoundUtilities
            var soundUrl = await SoundUtilities.AddSound(audioData, soundId, userId);

            if (soundUrl == null)
            {
                return StatusCode(500, "Failed to save generated audio file");
            }

            Console.WriteLine($"Debug: GenerateAndSaveSpeech - Sound saved successfully: {soundUrl}");

            // Return the sound URL and ID
            return Ok(new { 
                soundId = soundId,
                soundUrl = soundUrl, 
                message = "Speech generated and saved successfully",
                audioSize = audioData.Length 
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error generating and saving speech: {ex.Message}");
            return StatusCode(500, "Internal server error while generating and saving speech");
        }
    }

    /// <summary>
    /// Test endpoint to play audio for a specific artefact
    /// </summary>
    /// <param name="artefactId">The ID of the artefact</param>
    /// <returns>The audio file if it exists</returns>
    [HttpGet("{artefactId}/play-audio")]
    public async Task<IActionResult> PlayArtefactAudio(string artefactId)
    {
        try
        {
            var userId = User.FindFirst("id")?.Value;
            var artefact = await context.Artefacts
                .Where(a => a.UserId == userId && a.ArtefactId == artefactId)
                .FirstOrDefaultAsync();

            if (artefact == null)
            {
                return NotFound("Artefact not found or you don't have permission to access it");
            }

            if (string.IsNullOrEmpty(artefact.SoundPath))
            {
                return NotFound("No audio attached to this artefact");
            }

            Console.WriteLine($"Debug: PlayArtefactAudio - Artefact {artefactId} has soundPath: {artefact.SoundPath}");

            // Convert the API path to file system path
            // SoundPath is like "/api/Assets/Sounds/filename"
            var fileName = Path.GetFileName(artefact.SoundPath);
            var soundFolder = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Sounds");
            var filePath = Path.Combine(soundFolder, fileName);

            Console.WriteLine($"Debug: PlayArtefactAudio - Looking for file: {filePath}");

            if (!System.IO.File.Exists(filePath))
            {
                Console.WriteLine($"Debug: PlayArtefactAudio - File not found: {filePath}");
                return NotFound("Audio file not found on disk");
            }

            var fileBytes = await System.IO.File.ReadAllBytesAsync(filePath);
            Console.WriteLine($"Debug: PlayArtefactAudio - Serving audio file: {fileBytes.Length} bytes");

            return File(fileBytes, "audio/mpeg", fileName);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error playing artefact audio: {ex.Message}");
            return StatusCode(500, "Internal server error while retrieving audio");
        }
    }

    /// <summary>
    /// Generate speech from text for an artefact using ElevenLabs API
    /// </summary>
    /// <param name="ttsDto">Text-to-speech request data</param>
    /// <returns>
    /// Status code 200 (Ok) with the updated artefact on success<br />
    /// Status code 400 (Bad Request) if the request is invalid<br />
    /// Status code 403 (Forbidden) if the user doesn't own the artefact<br />
    /// Status code 404 (Not Found) if the artefact doesn't exist<br />
    /// Status code 500 (Internal Server Error) if ElevenLabs API fails
    /// </returns>
    [HttpPost("generate-speech")]
    public async Task<ActionResult<ArtefactGetDTO>> GenerateSpeech(ArtefactTextToSpeechDTO ttsDto)
    {
        var userId = User.FindFirst("id")?.Value;

        // Find the artefact
        var artefact = await context.Artefacts.FindAsync(ttsDto.ArtefactId);
        if (artefact == null)
        {
            return NotFound("Artefact not found");
        }

        // Check ownership
        if (userId != artefact.UserId)
        {
            return Forbid();
        }

        // Validate text input
        if (string.IsNullOrWhiteSpace(ttsDto.Text))
        {
            return BadRequest(new { error = "Text cannot be empty" });
        }

        try
        {
            // Get ElevenLabs API key from configuration
            var configuration = HttpContext.RequestServices.GetRequiredService<IConfiguration>();
            var apiKey = configuration["ElevenLabs:ApiKey"];
            
            if (string.IsNullOrEmpty(apiKey))
            {
                return StatusCode(500, "ElevenLabs API key not configured");
            }

            // Create ElevenLabs service
            var httpClientFactory = HttpContext.RequestServices.GetRequiredService<IHttpClientFactory>();
            var httpClient = httpClientFactory.CreateClient();
            var elevenLabsService = new ElevenLabsService(httpClient, apiKey);

            // Generate speech
            var audioData = await elevenLabsService.GenerateSpeechAsync(
                text: ttsDto.Text,
                voiceId: ttsDto.VoiceId,
                modelId: ttsDto.ModelId,
                stability: ttsDto.Stability,
                similarityBoost: ttsDto.SimilarityBoost,
                useSpeakerBoost: ttsDto.UseSpeakerBoost
            );

            if (audioData == null)
            {
                return StatusCode(500, "Failed to generate speech from ElevenLabs API");
            }

            // Delete any existing sound for this artefact
            try
            {
                SoundUtilities.DeleteSound(artefact.ArtefactId, userId);
            }
            catch { }

            // Save the generated audio as a temporary file
            var tempFileName = $"{artefact.ArtefactId}";
            var tempFilePath = Path.GetTempFileName();
            await System.IO.File.WriteAllBytesAsync(tempFilePath, audioData);

            // Create a form file from the audio data
            using var stream = new MemoryStream(audioData);
            var formFile = new FormFile(stream, 0, audioData.Length, "sound", tempFileName)
            {
                Headers = new HeaderDictionary(),
                ContentType = "audio/mpeg"
            };

            // Save using existing sound utilities
            var soundPath = await SoundUtilities.AddSound(formFile, artefact.ArtefactId, userId);
            if (soundPath != null)
            {
                artefact.SoundPath = soundPath;
                artefact.ModifiedDate = DateTime.UtcNow;

                context.Entry(artefact).State = EntityState.Modified;
                await context.SaveChangesAsync();
            }

            // Clean up temp file
            try
            {
                System.IO.File.Delete(tempFilePath);
            }
            catch { }

            // Return updated artefact
            var updatedArtefactDto = DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());
            return Ok(updatedArtefactDto);
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"An error occurred while generating speech: {ex.Message}");
        }
    }

    private bool ArtefactExists(string id)
    {
        return context.Artefacts.Any(e => e.ArtefactId == id);
    }
}
