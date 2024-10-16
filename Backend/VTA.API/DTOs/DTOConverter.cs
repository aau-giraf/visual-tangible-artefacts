using VTA.API.Models;

namespace VTA.API.DTOs;

public static class DTOConverter
{
    public static ArtefactGetDTO MapArtefactToArtefactGetDTO(Artefact artefact, string scheme, string host)
    {
        return new ArtefactGetDTO
        {
            ArtefactId = artefact.ArtefactId,
            ArtefactIndex = artefact.ArtefactIndex,
            UserId = artefact.UserId,
            CategoryId = artefact.CategoryId,
            ImageUrl = scheme + "://" + host + artefact.ImagePath
        };
    }

    public static Artefact MapArtefactPostDTOToArtefact(ArtefactPostDTO artefact, string? imageUrl)
    {
        return new Artefact
        {
            ArtefactId = artefact.ArtefactId,
            ArtefactIndex = artefact.ArtefactIndex,
            UserId = artefact.UserId,
            CategoryId = artefact.CategoryId,
            ImagePath = imageUrl
        };
    }

    public static CategoryGetDTO MapCategoryToCategoryGetDTO(Category category)
    {
        return new CategoryGetDTO
        {
            CategoryId = category.CategoryId,
            CategoryIndex = category.CategoryIndex,
            Name = category.Name
        };
    }

    public static Category MapCategoryGetDTOToCategory(CategoryGetDTO category)
    {
        return new Category
        {
            CategoryId = category.CategoryId,
            CategoryIndex = category.CategoryIndex,
            Name = category.Name
        };
    }

    public static UserGetDTO MapUserToUserGetDTO(User user)
    {
        return new UserGetDTO
        {
            Id = user.Id,
            Name = user.Name,
            Password = user.Password,
            GuardianKey = user.GuardianKey,
            Username = user.Username
        };
    }

}