using System.IdentityModel.Tokens.Jwt;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace VTA.Tests.TestHelpers
{
    /// <summary>
    /// Holds a generated test user's token and integer user ID.
    /// Replaces the old UserLoginResponseDTO for test purposes.
    /// </summary>
    public class TestLoginData
    {
        public string Token { get; set; } = null!;
        public int UserId { get; set; }
    }

    public class Utilities
    {
        private static readonly string TestSecret = Environment.GetEnvironmentVariable("JWT_SECRET")
            ?? "test-jwt-secret-for-ci-must-be-at-least-32-chars";

        private static int _nextUserId = 1000;

        private readonly HttpClient _client;

        public Utilities(HttpClient client)
        {
            _client = client;
        }

        public string GenerateUniqueUsername() => $"testuser_{Guid.NewGuid()}";

        /// <summary>
        /// Generates a test JWT token with the given user ID, signed with the test secret.
        /// Includes "sub" (int) and "org_roles" claims.
        /// </summary>
        public static string GenerateTestToken(int userId, Dictionary<string, string>? orgRoles = null)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(TestSecret));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new("sub", userId.ToString())
            };

            if (orgRoles != null)
            {
                var rolesJson = System.Text.Json.JsonSerializer.Serialize(orgRoles);
                claims.Add(new Claim("org_roles", rolesJson));
            }

            var token = new JwtSecurityToken(
                expires: DateTime.UtcNow.AddHours(1),
                claims: claims,
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        /// <summary>
        /// Creates a TestLoginData with a unique user ID and valid JWT token.
        /// Replaces the old SignUpUserAsync pattern.
        /// </summary>
        public TestLoginData CreateTestLoginData(Dictionary<string, string>? orgRoles = null)
        {
            var userId = Interlocked.Increment(ref _nextUserId);
            var token = GenerateTestToken(userId, orgRoles);
            return new TestLoginData { Token = token, UserId = userId };
        }
    }
}
