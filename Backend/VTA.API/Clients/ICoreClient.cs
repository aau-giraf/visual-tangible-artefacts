namespace VTA.API.Clients;

public interface ICoreClient
{
    Task<bool> ValidateCitizenAsync(int id, string accessToken);
    Task<bool> ValidateOrganizationAsync(int id, string accessToken);
}
