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

        private const string DefaultUsername = "testinguser";
        private const string DefaultPassword = "testingpassword";
        private const string DefaultName = "Testing User";

        public Utilities(HttpClient client)
        {
            _client = client;
        }

        public string GenerateUniqueUsername() => $"testuser_{Guid.NewGuid()}";

        public async Task<(HttpStatusCode StatusCode, UserLoginResponseDTO? Data)> SignUpUserAsync(string username, string password, string name)
        {
            var userDto = new UserSignupDTO
            {
                Username = username,
                Password = password,
                Name = name
            };

            var response = await _client.PostAsJsonAsync("/api/Users/SignUp", userDto);
            response.EnsureSuccessStatusCode(); // Ensure the response status code is successful

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

        // TODO: Signup endpoint should actually return 201 (for creation) instead of 200 (for read, update and delete)
        public async Task<string?> CreateUserAndReturnTokenAsync()
        {
            var (signUpStatus, signUpResult) = await SignUpUserAsync(DefaultUsername, DefaultPassword, DefaultName);
            if (signUpStatus == HttpStatusCode.OK && signUpResult != null)
            {
                return signUpResult.Token;
            }
            return null;
        }

        public async Task<UserLoginResponseDTO?> CreateUserAndReturnLoginDataAsync()
        {
            var (signUpStatus, signUpResult) = await SignUpUserAsync(DefaultUsername, DefaultPassword, DefaultName);
            if (signUpStatus == HttpStatusCode.OK && signUpResult != null)
            {
                return signUpResult;
            }
            return null;
        }

        public async Task<HttpStatusCode> DeleteUserWithTokenAsync()
        {
            var (loginStatus, loginResult) = await LoginUserAsync(DefaultUsername, DefaultPassword);
            if (loginStatus == HttpStatusCode.OK && loginResult != null)
            {
                return await DeleteUserAsync(loginResult.userId, loginResult.Token);
            }
            return HttpStatusCode.NotFound;
        }
    }
}
