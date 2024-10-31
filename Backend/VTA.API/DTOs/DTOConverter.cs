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

    public static Artefact MapArtefactPostDTOToArtefact(ArtefactPostDTO artefact, string id, string? imageUrl)
    {
        return new Artefact
        {
            ArtefactId = id,
            ArtefactIndex = artefact.ArtefactIndex,
            UserId = artefact.UserId,
            CategoryId = artefact.CategoryId,
            ImagePath = imageUrl
        };
    }

    public static CategoryGetDTO MapCategoryToCategoryGetDTO(Category category, string scheme, string host)
    {
        ICollection<ArtefactGetDTO> artefacts = new List<ArtefactGetDTO>();
        foreach (Artefact artefact in category.Artefacts)
        {
            artefacts.Add(MapArtefactToArtefactGetDTO(artefact, scheme, host));
        }
        return new CategoryGetDTO
        {
            CategoryId = category.CategoryId,
            CategoryIndex = category.CategoryIndex,
            Name = category.Name,
            Artefacts = artefacts
        };
    }

    public static Category MapCategoryPostDTOToCategory(CategoryPostDTO category, string id)
    {
        return new Category
        {
            CategoryId = id,
            CategoryIndex = category.CategoryIndex,
            UserId = category.UserId,
            Name = category.Name
        };
    }

    public static UserGetDTO MapUserToUserGetDTO(User user)
    {
        return new UserGetDTO
        {
            Id = user.Id,
            Name = user.Name,
            GuardianKey = user.GuardianKey,
            Username = user.Username
        };
    }

    public static User MapUserSignUpDTOToUser(UserSignupDTO dto, string id)
    {
        return new User
        {
            Id = id,
            Name = dto.Name,
            Password = dto.Password,
            Username = dto.Username,
            GuardianKey = dto.GuardianKey
        };
    }
    public static User MapUserPostDTOToUser(UserPostDTO user, string id)
    {
        return new User
        {
            Id = id,
            Name = user.Name,
            Password = user.Password,
            GuardianKey = user.GuardianKey,
            Username = user.Username
        };
    }

}