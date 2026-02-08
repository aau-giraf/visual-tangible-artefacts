using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.API.Services;
using VTA.Data.DbContexts;

namespace VTA.API.Controllers;

[Authorize]
[Route("api/Artefacts")]
[ApiController]
public class ArtefactsController(VTAContext context, ITtsService ttsService, IArtefactService artefactService) : ControllerBase
{

    // GET: api/Artefacts
    /// <summary>
    /// Gets all artefacts that a user owns
    /// </summary>
    /// <param name="skip">Number of items to skip (pagination)</param>
    /// <param name="take">Number of items to return (pagination, default 50)</param>
    /// <returns>An IEnumerable of artefacts</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ArtefactGetDTO>>> GetArtefacts([FromQuery] int? skip, [FromQuery] int? take)
    {
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var artefacts = await artefactService.GetArtefactsForUserAsync(userId, skip, take);

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
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var artefact = await artefactService.GetArtefactByIdAsync(artefactId, userId);
        if (artefact == null)
        {
            return NotFound();
        }

        return DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());
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
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var artefact = await artefactService.PatchArtefactAsync(
            dto.ArtefactId, userId, dto.ArtefactIndex, dto.Name, dto.NameShown, dto.Image, dto.Sound);

        if (artefact == null) return BadRequest();

        return NoContent();
    }

    // POST: api/Artefacts
    // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
    /// <summary>
    /// Creates a new artefact
    /// </summary>
    /// <param name="artefactPostDTO">An object with all artefact info</param>
    /// <returns>
    /// Status code 200 (Ok) to the client on success (Ok should also have the item with it)<br />
    /// Status code 403 (Forbidden) if a client tries to add an artefact to someone else<br />
    /// </returns>
    [HttpPost]
    [DisableRequestSizeLimit, RequestFormLimits(MultipartBodyLengthLimit = Int32.MaxValue, ValueLengthLimit = Int32.MaxValue)]
    public async Task<ActionResult<ArtefactGetDTO>> PostArtefact(ArtefactPostDTO artefactPostDTO)
    {
        var userId = User.FindFirst("id")?.Value;

        if (userId != artefactPostDTO.UserId)
        {
            return Forbid();
        }

        var artefact = await artefactService.CreateOrUpdateArtefactAsync(
            artefactPostDTO.ArtefactId,
            userId!,
            artefactPostDTO.Name,
            artefactPostDTO.ArtefactIndex,
            artefactPostDTO.CategoryId,
            artefactPostDTO.NameShown,
            artefactPostDTO.Image,
            artefactPostDTO.Sound);

        var artefactGetDTO = DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());
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
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var (success, error) = await artefactService.DeleteArtefactAsync(artefactId, userId);

        return error switch
        {
            "NotFound" => NotFound(),
            "Forbidden" => Forbid(),
            _ when success => NoContent(),
            _ => StatusCode(500)
        };
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
        if (string.IsNullOrWhiteSpace(request.Text))
        {
            return BadRequest(new { error = "Text cannot be empty" });
        }

        var audioData = await ttsService.GenerateSpeechAsync(
            request.Text,
            voiceId: request.VoiceId,
            modelId: "eleven_turbo_v2_5",
            languageCode: "da");

        if (audioData == null)
        {
            return StatusCode(500, "Failed to generate speech from ElevenLabs API");
        }

        return File(audioData, "audio/mpeg", "generated_speech");
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
        if (string.IsNullOrWhiteSpace(request.Text))
        {
            return BadRequest(new { error = "Text cannot be empty" });
        }

        if (string.IsNullOrWhiteSpace(request.ArtefactId))
        {
            return BadRequest(new { error = "ArtefactId cannot be empty" });
        }

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

        var soundUrl = await ttsService.GenerateAndSaveSpeechAsync(
            request.Text, request.ArtefactId, userId,
            voiceId: request.VoiceId,
            modelId: "eleven_turbo_v2_5",
            languageCode: "da");

        if (soundUrl == null)
        {
            return StatusCode(500, "Failed to generate or save speech");
        }

        artefact.SoundPath = soundUrl;
        await context.SaveChangesAsync();

        return Ok(new { soundUrl, message = "Speech generated and saved successfully" });
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
        if (string.IsNullOrWhiteSpace(request.Text))
        {
            return BadRequest(new { error = "Text cannot be empty" });
        }

        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var soundId = Guid.NewGuid().ToString();

        var soundUrl = await ttsService.GenerateAndSaveSpeechAsync(
            request.Text, soundId, userId,
            voiceId: request.VoiceId,
            modelId: "eleven_turbo_v2_5");

        if (soundUrl == null)
        {
            return StatusCode(500, "Failed to generate or save speech");
        }

        return Ok(new
        {
            soundId,
            soundUrl,
            message = "Speech generated and saved successfully"
        });
    }

    /// <summary>
    /// Test endpoint to play audio for a specific artefact
    /// </summary>
    /// <param name="artefactId">The ID of the artefact</param>
    /// <returns>The audio file if it exists</returns>
    [HttpGet("{artefactId}/play-audio")]
    public async Task<IActionResult> PlayArtefactAudio(string artefactId)
    {
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var artefact = await artefactService.GetArtefactForAudioAsync(artefactId, userId);

        if (artefact == null)
        {
            return NotFound("Artefact not found or you don't have permission to access it");
        }

        if (string.IsNullOrEmpty(artefact.SoundPath))
        {
            return NotFound("No audio attached to this artefact");
        }

        // Convert the API path to file system path
        var fileName = Path.GetFileName(artefact.SoundPath);
        var soundFolder = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Sounds");
        var filePath = Path.Combine(soundFolder, fileName);

        if (!System.IO.File.Exists(filePath))
        {
            return NotFound("Audio file not found on disk");
        }

        var fileBytes = await System.IO.File.ReadAllBytesAsync(filePath);
        return File(fileBytes, "audio/mpeg", fileName);
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

        var artefact = await context.Artefacts.FindAsync(ttsDto.ArtefactId);
        if (artefact == null)
        {
            return NotFound("Artefact not found");
        }

        if (userId != artefact.UserId)
        {
            return Forbid();
        }

        if (string.IsNullOrWhiteSpace(ttsDto.Text))
        {
            return BadRequest(new { error = "Text cannot be empty" });
        }

        var soundPath = await ttsService.GenerateAndSaveSpeechAsync(
            ttsDto.Text, artefact.ArtefactId, userId!,
            voiceId: ttsDto.VoiceId,
            modelId: ttsDto.ModelId,
            stability: ttsDto.Stability,
            similarityBoost: ttsDto.SimilarityBoost,
            useSpeakerBoost: ttsDto.UseSpeakerBoost);

        if (soundPath == null)
        {
            return StatusCode(500, "Failed to generate speech from ElevenLabs API");
        }

        artefact.SoundPath = soundPath;
        artefact.ModifiedDate = DateTime.UtcNow;
        context.Entry(artefact).State = EntityState.Modified;
        await context.SaveChangesAsync();

        var updatedArtefactDto = DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());
        return Ok(updatedArtefactDto);
    }

    /// <summary>
    /// Update nameShown for all artefacts owned by the current user
    /// </summary>
    /// <param name="request">Request containing the nameShown value to apply to all artefacts</param>
    /// <returns>
    /// Status code 200 (Ok) with count of updated artefacts<br />
    /// Status code 401 (Unauthorized) if user token is invalid
    /// </returns>
    [HttpPatch("bulk-update-name-shown")]
    public async Task<IActionResult> BulkUpdateNameShown([FromBody] BulkUpdateNameShownDTO request)
    {
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized("Invalid token");

        var updatedCount = await artefactService.BulkUpdateNameShownAsync(userId, request.NameShown);

        return Ok(new { updatedCount, nameShown = request.NameShown });
    }
}
