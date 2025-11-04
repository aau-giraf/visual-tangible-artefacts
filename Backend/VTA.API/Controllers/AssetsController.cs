using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace VTA.API.Controllers;

[Authorize]//Mark the entire controller to require a valid token
[Route("api/Assets")]
[ApiController]
public class AssetsController : ControllerBase
{
    //All endpoints in here simply serves the image to the client. We have not done a test on if a user is allowed to access this image (it could be sensetive info or people in pictures you know), we probably should do this though
    // GET: api/Assets/Artefacts/{userId}/{filename}
    /// <summary>
    /// Displays/Serves an artefact image
    /// </summary>
    /// <param name="userId">The user ID</param>
    /// <param name="filename">The filename</param>
    /// <returns>
    /// File if the image exists on the server
    /// Status code 404 (Not Found) if the image does not exist
    /// </returns>
    [HttpGet("Artefacts/{userId}/{filename}")]
    public IActionResult GetArtefactImage(string userId, string filename)
    {
        var imagePath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", userId, filename);
        if (!System.IO.File.Exists(imagePath))
        {
            return NotFound();
        }
        var fileBytes = System.IO.File.ReadAllBytes(imagePath);
        return File(fileBytes, "image/jpeg");
    }
    /// <summary>
    /// Displays/Serves a Category image
    /// </summary>
    /// <param name="userId">The user ID</param>
    /// <param name="filename">The filename</param>
    /// <returns>
    /// File if the image exists on the server
    /// Status code 404 (Not Found) if the image does not exist
    /// </returns>
    [HttpGet("Categories/{userId}/{filename}")]//{} allows us to extract that part of the url as a variable
    public IActionResult GetCategoryImage(string userId, string filename)
    {
        var imagePath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Categories", userId, filename);
        if (!System.IO.File.Exists(imagePath))
        {
            return NotFound();
        }
        var fileBytes = System.IO.File.ReadAllBytes(imagePath);
        return File(fileBytes, "image/jpeg");
    }

    // GET: api/Assets/Sounds/{userId}/{filename}
    [HttpGet("Sounds/{userId}/{filename}")]
    public IActionResult GetSoundFile(string userId, string filename)
    {
        var soundPath = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Sounds", userId, filename);
        if (!System.IO.File.Exists(soundPath))
        {
            return NotFound();
        }
        var fileBytes = System.IO.File.ReadAllBytes(soundPath);
        // set a generic audio content type; the frontend can handle playback
        return File(fileBytes, "audio/mpeg");
    }
    

}