using System.Net;
using System.Net.Http.Headers;

namespace VTA.API.Clients;

public class GirafCoreClient : ICoreClient
{
    private readonly HttpClient _httpClient;

    public GirafCoreClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<bool> ValidateCitizenAsync(int id, string accessToken)
    {
        return await ExistsAsync($"/api/v1/citizens/{id}", accessToken);
    }

    public async Task<bool> ValidateOrganizationAsync(int id, string accessToken)
    {
        return await ExistsAsync($"/api/v1/organizations/{id}", accessToken);
    }

    private async Task<bool> ExistsAsync(string path, string accessToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, path);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        var response = await _httpClient.SendAsync(request);
        return response.StatusCode switch
        {
            HttpStatusCode.OK => true,
            HttpStatusCode.NotFound => false,
            HttpStatusCode.Forbidden => false,
            _ => throw new HttpRequestException(
                $"Core API returned unexpected status {(int)response.StatusCode} for {path}")
        };
    }
}
