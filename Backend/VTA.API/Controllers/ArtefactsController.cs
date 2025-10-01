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
public class ArtefactsController : ControllerBase
{
    private readonly ArtefactContext _context;

    public ArtefactsController(ArtefactContext context)
    {
        _context = context;
    }

    // GET: api/Artefacts
    /// <summary>
    /// Gets all artefacts that a user owns
    /// </summary>
    /// <returns>An IEnumerable of artefacts</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ArtefactGetDTO>>> GetArtefacts()
    {
        var userId = User.FindFirst("id")?.Value;

        List<Artefact>? artefacts = await _context.Artefacts.Where(a => a.UserId == userId).ToListAsync();
        if (artefacts == null)
        {
            return NotFound();
        }
        List<ArtefactGetDTO> artefactGetDTOs = new List<ArtefactGetDTO>();
        foreach (Artefact artefact in artefacts)
        {
            artefactGetDTOs.Add(DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString()));
        }
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

        var artefact = await _context.Artefacts.Where(a => a.UserId == userId).FirstOrDefaultAsync(a => a.ArtefactId == artefactId);
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
        var artefact = _context.Artefacts.Find(dto.ArtefactId);

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
        if (dto.Image != null)
        {
            ImageUtilities.DeleteImage(artefact.CategoryId, "Categories");
            ImageUtilities.AddImage(dto.Image, artefact.CategoryId, "Categories");
        }
        if (dto.Sound != null)
        {
            // Delete any existing sound for this artefact
            try
            {
                SoundUtilities.DeleteSound(artefact.ArtefactId);
            }
            catch { }
            // Save sound file using SoundUtilities: ArtefactId + extension in Assets/Sounds
            var soundPath = SoundUtilities.AddSound(dto.Sound, artefact.ArtefactId);
            artefact.SoundPath = soundPath;
        }

        _context.Entry(artefact).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!ArtefactExists(artefact.CategoryId))
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
        var userId = User.FindFirst("id")?.Value;

        if (userId != artefactPostDTO.UserId)
        {
            return Forbid();
        }

        string artefactId = Guid.NewGuid().ToString();
        string? imageUrl = ImageUtilities.AddImage(artefactPostDTO.Image, artefactId, "Artefacts");
        string? soundUrl = null;
        if (artefactPostDTO.Sound != null)
        {
            soundUrl = SoundUtilities.AddSound(artefactPostDTO.Sound, artefactId);
        }
        Artefact artefact = DTOConverter.MapArtefactPostDTOToArtefact(artefactPostDTO, artefactId, imageUrl);
        artefact.SoundPath = soundUrl;
        artefact.UserId = userId;

        _context.Artefacts.Add(artefact);
        try
        {
            await _context.SaveChangesAsync();
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
                await _context.SaveChangesAsync();
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

        var artefact = await _context.Artefacts.FindAsync(artefactId);
        if (artefact == null)
        {
            return NotFound();
        }

        if (userId != artefact.UserId)
        {
            return Forbid();
        }
        ImageUtilities.DeleteImage(artefact.ArtefactId, "Artefacts");
        // Also remove associated sound file if present
        try
        {
            SoundUtilities.DeleteSound(artefact.ArtefactId);
        }
        catch { }

        _context.Artefacts.Remove(artefact);
        await _context.SaveChangesAsync();

        return NoContent();
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
        var artefact = await _context.Artefacts.FindAsync(ttsDto.ArtefactId);
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
                SoundUtilities.DeleteSound(artefact.ArtefactId);
            }
            catch { }

            // Save the generated audio as a temporary file
            var tempFileName = $"{artefact.ArtefactId}.mp3";
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
            var soundPath = SoundUtilities.AddSound(formFile, artefact.ArtefactId);
            if (soundPath != null)
            {
                artefact.SoundPath = soundPath;
                artefact.ModifiedDate = DateTime.UtcNow;
                
                _context.Entry(artefact).State = EntityState.Modified;
                await _context.SaveChangesAsync();
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
        return _context.Artefacts.Any(e => e.ArtefactId == id);
    }
}
