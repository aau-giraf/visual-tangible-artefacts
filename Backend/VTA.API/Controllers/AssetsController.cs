using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace VTA.API.Controllers;

[Authorize]
[Route("api/Assets")]
[ApiController]
public class AssetsController : ControllerBase
{
    // GET: api/Assets/Images
    [HttpGet("Artefacts/{filepath}")]
    public IActionResult GetArtefactImage(string filepath)
    {
        var imagePath = $"Assets/Artefacts/{filepath}";
        if (!System.IO.File.Exists(imagePath))
        {
            return NotFound();
        }
        var fileBytes = System.IO.File.ReadAllBytes(imagePath);
        return File(fileBytes, "image/jpeg");
    }
    [HttpGet("Categories/{filepath}")]
    public IActionResult GetCategoryImage(string filepath)
    {
        var imagePath = $"Assets/Categories/{filepath}";
        if (!System.IO.File.Exists(imagePath))
        {
            return NotFound();
        }
        var fileBytes = System.IO.File.ReadAllBytes(imagePath);
        return File(fileBytes, "image/jpeg");
    }
    

}