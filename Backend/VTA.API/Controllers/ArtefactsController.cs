using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models.Artefacts;
using VTA.API.Models.Categories;
using VTA.API.Utilities;

namespace VTA.API.Controllers;

[Authorize]//Lock all endpoints behind JWT
[Route("api/Users/Artefacts")]//We designed the route so that *Users* OWNS *Artefacts* and this route reflects it
[ApiController]
public class ArtefactsController(VTAContext context) : ControllerBase
{
    // GET: api/Users/Artefacts
    /// <summary>
    /// Gets all artefacts that a user owns
    /// </summary>
    /// <returns>An IEnumerable of artefacts</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ArtefactGetDTO>>> GetArtefacts(CancellationToken cancellationToken)
    {
        //TODO: Delete endpoint if not needed
        
        var userId = User.FindFirst("id")?.Value!;

        var artefacts = await CompiledQueries
            .GetUserArtefactDTOs(context, userId)
            .ToListAsync(cancellationToken);

        if (artefacts.Count == 0)
        {
            return NotFound();
        }

        var artefactsWithFullUrls = artefacts
            .Select(x => x.WithFullUrls(Request.Scheme, Request.Host.ToString()))
            .ToList();

        return artefactsWithFullUrls;
    }

    // GET: api/Users/Artefacts/5
    /// <summary>
    /// Gets a specific artefact
    /// </summary>
    /// <param name="artefactId">The artefact to get</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>The specified artefact</returns>
    [HttpGet("{artefactId}")]
    public async Task<ActionResult<ArtefactGetDTO>> GetArtefact(string artefactId, CancellationToken cancellationToken)
    {
        //TODO: Delete endpoint if not needed
        
        var userId = User.FindFirst("id")?.Value!;

        var artefact = await CompiledQueries
            .GetUserArtefactDTOById(context, userId, artefactId)
            .FirstOrDefaultAsync(cancellationToken);

        if (artefact is null)
        {
            return NotFound();
        }

        var artefactWithFullUrls = artefact.WithFullUrls(Request.Scheme, Request.Host.ToString());

        return artefactWithFullUrls;
    }

    // PATCH: api/Users/Artefacts
    // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
    /// <summary>
    /// Updates an artefacts information
    /// </summary>
    /// <param name="dto">The artefact patch DTO with fields to update</param>
    /// <returns>Status code 204 (No content) to the client on success</returns>
    [HttpPatch]
    [DisableRequestSizeLimit, RequestFormLimits(MultipartBodyLengthLimit = Int32.MaxValue, ValueLengthLimit = Int32.MaxValue)]
    public async Task<IActionResult> PatchArtefact([FromForm] ArtefactPatchDTO dto)
    {
        var userId = User.FindFirst("id")?.Value!;

        // If we have files to upload, we need to load the entity
        if (dto.Image != null || dto.Sound != null)
        {
            var artefact = await context.Artefacts
                .OfType<UserArtefact>()
                .FirstOrDefaultAsync(a => a.ArtefactId == dto.ArtefactId && a.UserId == userId, HttpContext.RequestAborted);

            if (artefact == null)
            {
                return NotFound();
            }

            // Handle image update
            if (dto.Image != null)
            {
                var imagePath = ImageUtilities.ReplaceImage(dto.Image, artefact.ArtefactId, "Artefacts");
                artefact.ImagePath = imagePath;
            }

            // Handle sound update
            if (dto.Sound != null)
            {
                var soundPath = SoundUtilities.ReplaceSound(dto.Sound, artefact.ArtefactId);
                artefact.SoundPath = soundPath;
            }

            // Update simple fields if provided
            if (dto.ArtefactIndex != null)
            {
                artefact.ArtefactIndex = dto.ArtefactIndex.Value;
            }
            
            if (!string.IsNullOrEmpty(dto.Name))
            {
                artefact.Name = dto.Name;
            }

            artefact.ModifiedDate = DateTime.UtcNow;

            await context.SaveChangesAsync(HttpContext.RequestAborted);
        }
        else
        {
            // No files - use ExecuteUpdateAsync for better performance
            var rowsAffected = await context.Artefacts
                .OfType<UserArtefact>()
                .Where(a => a.ArtefactId == dto.ArtefactId && a.UserId == userId)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(a => a.ArtefactIndex, a => dto.ArtefactIndex ?? a.ArtefactIndex)
                    .SetProperty(a => a.Name, a => dto.Name ?? a.Name)
                    .SetProperty(a => a.ModifiedDate, DateTime.UtcNow),
                    HttpContext.RequestAborted);

            if (rowsAffected == 0)
            {
                return NotFound();
            }
        }

        return NoContent();
    }

    // POST: api/Users/Artefacts
    // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
    /// <summary>
    /// Creates a new artefact
    /// </summary>
    /// <param name="artefactPostDTO">An object with all artefact info</param>
    /// <returns>
    /// Status code 201 (Created) to the client on success with the created artefact<br />
    /// Status code 400 (Bad Request) if the category doesn't exist or doesn't belong to the user<br />
    /// Status code 403 (Forbidden) if a client tries to add an artefact to someone else<br />
    /// </returns>
    [HttpPost]
    [DisableRequestSizeLimit, RequestFormLimits(MultipartBodyLengthLimit = Int32.MaxValue, ValueLengthLimit = Int32.MaxValue)]
    public async Task<ActionResult<ArtefactGetDTO>> PostArtefact([FromForm] ArtefactPostDTO artefactPostDTO)
    {
        var userId = User.FindFirst("id")?.Value!;

        if (userId != artefactPostDTO.UserId)
        {
            return Forbid();
        }

        // Verify that the dto.CategoryId is a UserCategory that belongs to the user (if provided)
        if (!string.IsNullOrEmpty(artefactPostDTO.CategoryId))
        {
            var categoryExists = await context.Categories
                .OfType<UserCategory>()
                .AnyAsync(c => c.CategoryId == artefactPostDTO.CategoryId && c.UserId == userId, HttpContext.RequestAborted);

            if (!categoryExists)
            {
                return BadRequest("Category does not exist or does not belong to the user");
            }
        }

        string artefactId = Guid.NewGuid().ToString();
        string? imageUrl = ImageUtilities.AddImage(artefactPostDTO.Image, artefactId, "Artefacts");
        string? soundUrl = null;

        if (artefactPostDTO.Sound != null)
        {
            soundUrl = SoundUtilities.AddSound(artefactPostDTO.Sound, artefactId);
        }

        UserArtefact artefact = DTOConverter.MapArtefactPostDTOToArtefact(artefactPostDTO, artefactId, imageUrl, soundUrl);
        artefact.UserId = userId;
        artefact.Name = artefactPostDTO.Name;
        artefact.ModifiedDate = DateTime.UtcNow;

        context.Artefacts.Add(artefact);
        await context.SaveChangesAsync(HttpContext.RequestAborted);
        
        var artefactGetDTO = new ArtefactGetDTO
        {
            ArtefactId = artefact.ArtefactId,
            ArtefactIndex = artefact.ArtefactIndex,
            UserId = artefact.UserId,
            CategoryId = artefact.CategoryId,
            Name = artefact.Name,
            ImageUrl = imageUrl != null ? $"{Request.Scheme}://{Request.Host}{imageUrl}" : null,
            SoundUrl = soundUrl != null ? $"{Request.Scheme}://{Request.Host}{soundUrl}" : null
        };

        return CreatedAtAction("GetArtefact", new { artefactId = artefactGetDTO.ArtefactId }, artefactGetDTO);
    }

    // DELETE: api/Users/Artefacts/5
    /// <summary>
    /// Deletes an artefact using its ID
    /// </summary>
    /// <param name="artefactId">The artefacts ID</param>
    /// <returns>
    /// Status code 204 (No content) to the client on success<br />
    /// Status code 404 (Not Found) if the artefact does not exist or user doesn't own it
    /// </returns>
    [HttpDelete("{artefactId}")]
    public async Task<IActionResult> DeleteArtefact(string artefactId)
    {
        var userId = User.FindFirst("id")?.Value!;

        await using var transaction = await context.Database.BeginTransactionAsync(HttpContext.RequestAborted);

        try
        {
            var rowsAffected = await context.Artefacts
                .OfType<UserArtefact>()
                .Where(a => a.ArtefactId == artefactId && a.UserId == userId)
                .ExecuteDeleteAsync(HttpContext.RequestAborted);

            if (rowsAffected == 0)
            {
                return NotFound();
            }

            // Delete associated files
            ImageUtilities.DeleteImage(artefactId, "Artefacts");

            try
            {
                SoundUtilities.DeleteSound(artefactId);
            }
            catch
            {
                // ignored
            }

            await transaction.CommitAsync(HttpContext.RequestAborted);
        }
        catch
        {
            await transaction.RollbackAsync(HttpContext.RequestAborted);
            throw;
        }

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
            return BadRequest("Text cannot be empty");
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
                // voiceId not specified - uses backend default (xj6X4BCUsv9oxohm1E8o)
                modelId: "eleven_multilingual_v2", // Use multilingual v2 model
                languageCode: "da" // Explicitly set Danish
            );

            if (audioData == null)
            {
                return StatusCode(500, "Failed to generate speech from ElevenLabs API");
            }

            // Return audio data directly
            return File(audioData, "audio/mpeg", "generated_speech.mp3");
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
            return BadRequest("Text cannot be empty");
        }

        if (string.IsNullOrWhiteSpace(request.ArtefactId))
        {
            return BadRequest("ArtefactId cannot be empty");
        }

        try
        {
            // Check if artefact exists and user owns it
            var userId = User.FindFirst("id")?.Value!;
            var artefact = await context.Artefacts
                .OfType<UserArtefact>()
                .Where(a => a.UserId == userId && a.ArtefactId == request.ArtefactId)
                .FirstOrDefaultAsync(HttpContext.RequestAborted);

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
                // voiceId not specified - uses backend default (xj6X4BCUsv9oxohm1E8o)
                modelId: "eleven_multilingual_v2", // Use multilingual v2 model
                languageCode: "da" // Explicitly set Danish
            );

            if (audioData == null)
            {
                return StatusCode(500, "Failed to generate speech from ElevenLabs API");
            }

            // Save the audio data to file system using SoundUtilities
            var soundUrl = SoundUtilities.AddSound(audioData, request.ArtefactId, ".mp3");
            
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
            return BadRequest("Text cannot be empty");
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
                text: request.Text,
                voiceId: request.VoiceId ?? "Bj9UqZbhQsanLzgalpEG", // Default to your specified voice
                modelId: "eleven_monolingual_v1"
            );

            if (audioData == null)
            {
                return StatusCode(500, "Failed to generate speech from ElevenLabs API");
            }

            // Generate unique ID for the sound file
            var soundId = Guid.NewGuid().ToString();
            
            // Save the audio data to file system using SoundUtilities
            var soundUrl = SoundUtilities.AddSound(audioData, soundId, ".mp3");
            
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
            var userId = User.FindFirst("id")?.Value!;
            var artefact = await context.Artefacts
                .OfType<UserArtefact>()
                .Where(a => a.UserId == userId && a.ArtefactId == artefactId)
                .FirstOrDefaultAsync(HttpContext.RequestAborted);

            if (artefact == null)
            {
                return NotFound("Artefact not found or you don't have permission to access it");
            }

            if (string.IsNullOrEmpty(artefact.SoundPath))
            {
                return NotFound("No audio attached to this artefact");
            }

            // Convert the API path to file system path
            // SoundPath is like "/api/Assets/Sounds/filename.mp3"
            var fileName = Path.GetFileName(artefact.SoundPath);
            var soundFolder = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Sounds");
            var filePath = Path.Combine(soundFolder, fileName);

            if (!System.IO.File.Exists(filePath))
            {
                return NotFound("Audio file not found on disk");
            }

            var fileBytes = await System.IO.File.ReadAllBytesAsync(filePath, HttpContext.RequestAborted);

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
    public async Task<ActionResult<ArtefactGetDTO>> GenerateSpeech([FromBody] ArtefactTextToSpeechDTO ttsDto)
    {
        var userId = User.FindFirst("id")?.Value!;

        // Validate text input
        if (string.IsNullOrWhiteSpace(ttsDto.Text))
        {
            return BadRequest("Text cannot be empty");
        }

        // Find the artefact and verify ownership
        var artefact = await context.Artefacts
            .OfType<UserArtefact>()
            .FirstOrDefaultAsync(a => a.ArtefactId == ttsDto.ArtefactId && a.UserId == userId, HttpContext.RequestAborted);

        if (artefact == null)
        {
            return NotFound("Artefact not found");
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

            // Replace the existing sound with the generated audio
            var soundPath = SoundUtilities.ReplaceSound(audioData, artefact.ArtefactId, ".mp3");
            if (soundPath != null)
            {
                artefact.SoundPath = soundPath;
                artefact.ModifiedDate = DateTime.UtcNow;

                await context.SaveChangesAsync(HttpContext.RequestAborted);
            }

            // Return updated artefact DTO
            var artefactGetDTO = new ArtefactGetDTO
            {
                ArtefactId = artefact.ArtefactId,
                ArtefactIndex = artefact.ArtefactIndex,
                UserId = artefact.UserId,
                CategoryId = artefact.CategoryId,
                Name = artefact.Name,
                ImageUrl = artefact.ImagePath != null ? $"{Request.Scheme}://{Request.Host}{artefact.ImagePath}" : null,
                SoundUrl = soundPath != null ? $"{Request.Scheme}://{Request.Host}{soundPath}" : null
            };

            return Ok(artefactGetDTO);
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"An error occurred while generating speech: {ex.Message}");
        }
    }
}
