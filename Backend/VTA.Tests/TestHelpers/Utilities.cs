using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Net;
using System.Net.Http.Json;
using System.Threading.Tasks;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;
using Xunit;

namespace VTA.Tests.TestHelpers
{
    public class Utilities
    {

        private readonly HttpClient _client;

        public Utilities(HttpClient client)
        {
            _client = client;
        }

        public async Task<(HttpStatusCode StatusCode, UserLoginResponseDTO? Data)> SignUpUserAsync(string username, string password, string name)
        {
            var userDto = new UserSignupDTO
            {
                Username = username,
                Password = password,
                Name = name
            };

            var response = await _client.PostAsJsonAsync("/api/Users/SignUp", userDto);
            var data = response.IsSuccessStatusCode ? await response.Content.ReadFromJsonAsync<UserLoginResponseDTO>() : null;
            return (response.StatusCode, data);
        }

        public async Task<(HttpStatusCode StatusCode, UserLoginResponseDTO? Data)> LoginUserAsync(string username, string password)
        {
            var userDto = new UserLoginDTO
            {
                Username = username,
                Password = password
            };

            var response = await _client.PostAsJsonAsync("/api/Users/Login", userDto);
            var data = response.IsSuccessStatusCode ? await response.Content.ReadFromJsonAsync<UserLoginResponseDTO>() : null;
            return (response.StatusCode, data);
        }

        public async Task<HttpStatusCode> DeleteUserAsync(string userId, string token)
        {
            var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/{userId}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var response = await _client.SendAsync(request);
            return response.StatusCode;
        }
    }
}
