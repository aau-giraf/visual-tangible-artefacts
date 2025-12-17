using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using VTA.API.DTOs;
using VTA.Data.Models;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.ControllerTests
{
    public class SessionControllerTests : IClassFixture<CustomApplicationFactory>
    {
        private readonly HttpClient _client;
        private readonly Utilities _utilities;

        public SessionControllerTests(CustomApplicationFactory factory)
        {
            _client = factory.CreateClient();
            _utilities = new Utilities(_client);
        }

        [Fact]
        public async Task GetSessions_ReturnsOkForAdmin()
        {
            // Arrange
            var adminToken = await CreateAdminTokenAsync();
            var request = new HttpRequestMessage(HttpMethod.Get, "/api/Admin/sessions");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var sessions = await response.Content.ReadFromJsonAsync<List<SessionGetDTO>>();
            Assert.NotNull(sessions);
        }

        [Fact]
        public async Task GetSessions_ReturnsForbiddenForNonAdmin()
        {
            // Arrange
            var username = _utilities.GenerateUniqueUsername();
            var (_, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
            var request = new HttpRequestMessage(HttpMethod.Get, "/api/Admin/sessions");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult!.Token);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);

            // Cleanup
            await _utilities.DeleteUserAsync(signUpResult.userId, signUpResult.Token);
        }

        [Fact]
        public async Task GetSessions_FiltersCorrectlyByStartDate()
        {
            // Arrange
            var adminToken = await CreateAdminTokenAsync();
            var startDate = DateTime.UtcNow.AddDays(-7);
            var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Admin/sessions?startDate={startDate:O}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var sessions = await response.Content.ReadFromJsonAsync<List<SessionGetDTO>>();
            Assert.NotNull(sessions);
            Assert.All(sessions!, s => Assert.True(s.StartTime >= startDate));
        }

        [Fact]
        public async Task GetSessions_FiltersCorrectlyByEndDate()
        {
            // Arrange
            var adminToken = await CreateAdminTokenAsync();
            var endDate = DateTime.UtcNow;
            var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Admin/sessions?endDate={endDate:O}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var sessions = await response.Content.ReadFromJsonAsync<List<SessionGetDTO>>();
            Assert.NotNull(sessions);
            Assert.All(sessions!, s => Assert.True(s.StartTime <= endDate));
        }

        [Fact]
        public async Task GetSessions_FiltersCorrectlyByUserId()
        {
            // Arrange
            var adminToken = await CreateAdminTokenAsync();
            // Get any session first to extract a valid user ID
            var allSessionsRequest = new HttpRequestMessage(HttpMethod.Get, "/api/Admin/sessions");
            allSessionsRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);
            var allSessionsResponse = await _client.SendAsync(allSessionsRequest);
            var allSessions = await allSessionsResponse.Content.ReadFromJsonAsync<List<SessionGetDTO>>();
            
            if (allSessions == null || allSessions.Count == 0)
            {
                // Skip test if no sessions exist
                return;
            }

            var userId = allSessions.First().CallerId;
            var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Admin/sessions?userId={userId}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var sessions = await response.Content.ReadFromJsonAsync<List<SessionGetDTO>>();
            Assert.NotNull(sessions);
            Assert.All(sessions!, s => Assert.True(s.CallerId == userId || s.CalleeId == userId));
        }

        [Fact]
        public async Task GetSessions_OrdersByStartTimeDescending()
        {
            // Arrange
            var adminToken = await CreateAdminTokenAsync();
            var request = new HttpRequestMessage(HttpMethod.Get, "/api/Admin/sessions");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var sessions = await response.Content.ReadFromJsonAsync<List<SessionGetDTO>>();
            Assert.NotNull(sessions);
            
            // Verify descending order
            for (int i = 0; i < sessions!.Count - 1; i++)
            {
                Assert.True(sessions[i].StartTime >= sessions[i + 1].StartTime);
            }
        }

        [Fact]
        public async Task GetSession_ReturnsSessionWhenExists()
        {
            // Arrange
            var adminToken = await CreateAdminTokenAsync();
            var sessionId = await GetFirstSessionIdAsync(adminToken);
            
            if (sessionId == null)
            {
                // Skip test if no sessions exist
                return;
            }

            var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Admin/sessions/{sessionId}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var session = await response.Content.ReadFromJsonAsync<SessionGetDTO>();
            Assert.NotNull(session);
            Assert.Equal(sessionId, session!.Id);
            Assert.NotNull(session.CallerName);
            Assert.NotNull(session.CalleeName);
        }

        [Fact]
        public async Task GetSession_ReturnsNotFoundWhenDoesNotExist()
        {
            // Arrange
            var adminToken = await CreateAdminTokenAsync();
            var nonExistentId = 999999;
            var request = new HttpRequestMessage(HttpMethod.Get, $"/api/Admin/sessions/{nonExistentId}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        }

        [Fact]
        public async Task GetSession_ReturnsForbiddenForNonAdmin()
        {
            // Arrange
            var username = _utilities.GenerateUniqueUsername();
            var (_, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
            var request = new HttpRequestMessage(HttpMethod.Get, "/api/Admin/sessions/1");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult!.Token);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);

            // Cleanup
            await _utilities.DeleteUserAsync(signUpResult.userId, signUpResult.Token);
        }

        [Fact]
        public async Task GetSessionStatistics_ReturnsCorrectCalculations()
        {
            // Arrange
            var adminToken = await CreateAdminTokenAsync();
            var request = new HttpRequestMessage(HttpMethod.Get, "/api/Admin/sessions/statistics");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var statistics = await response.Content.ReadFromJsonAsync<SessionStatisticsDTO>();
            Assert.NotNull(statistics);
            Assert.True(statistics!.TotalSessions >= 0);
            Assert.True(statistics.CompletedSessions >= 0);
            Assert.True(statistics.RejectedSessions >= 0);
            Assert.True(statistics.FailedSessions >= 0);
            Assert.Equal(statistics.TotalSessions, 
                statistics.CompletedSessions + statistics.RejectedSessions + statistics.FailedSessions);
        }

        [Fact]
        public async Task GetSessionStatistics_FiltersCorrectlyByDateRange()
        {
            // Arrange
            var adminToken = await CreateAdminTokenAsync();
            var startDate = DateTime.UtcNow.AddDays(-30);
            var endDate = DateTime.UtcNow;
            var request = new HttpRequestMessage(HttpMethod.Get, 
                $"/api/Admin/sessions/statistics?startDate={startDate:O}&endDate={endDate:O}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var statistics = await response.Content.ReadFromJsonAsync<SessionStatisticsDTO>();
            Assert.NotNull(statistics);
            Assert.True(statistics!.TotalSessions >= 0);
        }

        [Fact]
        public async Task GetSessionStatistics_ReturnsForbiddenForNonAdmin()
        {
            // Arrange
            var username = _utilities.GenerateUniqueUsername();
            var (_, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
            var request = new HttpRequestMessage(HttpMethod.Get, "/api/Admin/sessions/statistics");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult!.Token);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);

            // Cleanup
            await _utilities.DeleteUserAsync(signUpResult.userId, signUpResult.Token);
        }

        [Fact]
        public async Task GetSessionStatistics_HandlesNoSessionsGracefully()
        {
            // Arrange
            var adminToken = await CreateAdminTokenAsync();
            // Use a date range where no sessions exist
            var startDate = DateTime.UtcNow.AddYears(10);
            var endDate = DateTime.UtcNow.AddYears(11);
            var request = new HttpRequestMessage(HttpMethod.Get, 
                $"/api/Admin/sessions/statistics?startDate={startDate:O}&endDate={endDate:O}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var statistics = await response.Content.ReadFromJsonAsync<SessionStatisticsDTO>();
            Assert.NotNull(statistics);
            Assert.Equal(0, statistics!.TotalSessions);
            Assert.Equal(0, statistics.CompletedSessions);
            Assert.Null(statistics.AverageDuration);
        }

        private async Task<string> CreateAdminTokenAsync()
        {
            // This assumes there's an admin user already in the database
            // Adjust the username/password to match your test database setup
            var (_, loginResult) = await _utilities.LoginUserAsync("admin", "admin");
            return loginResult?.Token ?? throw new InvalidOperationException("Could not create admin token");
        }

        private async Task<int?> GetFirstSessionIdAsync(string adminToken)
        {
            var request = new HttpRequestMessage(HttpMethod.Get, "/api/Admin/sessions");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);
            var response = await _client.SendAsync(request);
            
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            var sessions = await response.Content.ReadFromJsonAsync<List<SessionGetDTO>>();
            return sessions?.FirstOrDefault()?.Id;
        }
    }
}
