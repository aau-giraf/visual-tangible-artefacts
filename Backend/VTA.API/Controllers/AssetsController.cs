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
    // GET: api/Assets/Artefacts/image
    /// <summary>
    /// Displayes/Serves an artefact image
    /// </summary>
    /// <param name="filepath">The "imagePath" returned from the artefact</param>
    /// <returns>
    /// File if the image exists on the server
    /// Status code 404 (Not Found) if the image does not exist
    /// </returns>
    [HttpGet("Artefacts/{filepath}")]
    public IActionResult GetArtefactImage(string filepath)
    {
        var imagePath = $"Assets/Artefacts/{filepath}";//this should have been Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts", filepath); but we have a user testing it at the moment so we can't change it
        if (!System.IO.File.Exists(imagePath))
        {
            return NotFound();
        }
        var fileBytes = System.IO.File.ReadAllBytes(imagePath);
        return File(fileBytes, "image/jpeg");
    }
    /// <summary>
    /// Displayes/Serves a Category image
    /// </summary>
    /// <param name="filepath">The "imagePath" returned from the artefact</param>
    /// <returns>
    /// File if the image exists on the server
    /// Status code 404 (Not Found) if the image does not exist
    /// </returns>
    [HttpGet("Categories/{filepath}")]//{} allows us to extract that part of the url as a variable
    public IActionResult GetCategoryImage(string filepath)
    {
        var imagePath = $"Assets/Categories/{filepath}";//this should have been Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Categories", filepath); but we have a user testing it at the moment so we can't change it
        if (!System.IO.File.Exists(imagePath))
        {
            return NotFound();
        }
        var fileBytes = System.IO.File.ReadAllBytes(imagePath);
        return File(fileBytes, "image/jpeg");
    }
    

}