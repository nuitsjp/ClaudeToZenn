using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Web;

namespace ClaudeToZenn.Functions;

public class GetUserInfo
{
    private readonly HttpClient _httpClient;
    private readonly KeyVaultTokenManager _tokenManager;

    public GetUserInfo(IHttpClientFactory httpClientFactory, KeyVaultTokenManager tokenManager)
    {
        _httpClient = httpClientFactory.CreateClient();
        _tokenManager = tokenManager;
    }

    [Function("GetUserInfo")]
    public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        var query = HttpUtility.ParseQueryString(req.Url.Query);
        var userId = query["userId"];

        if (string.IsNullOrEmpty(userId))
        {
            return req.CreateResponse(HttpStatusCode.BadRequest);
        }

        try
        {
            var accessToken = await _tokenManager.GetTokenAsync(userId);
            var userInfo = await GetGitHubUserInfoAsync(accessToken);

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(userInfo);
            return response;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error getting user info: {ex.Message}");
            return req.CreateResponse(HttpStatusCode.InternalServerError);
        }
    }

    private async Task<GitHubUser> GetGitHubUserInfoAsync(string accessToken)
    {
        try
        {
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            _httpClient.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("YourApp", "1.0"));

            var response = await _httpClient.GetAsync("https://api.github.com/user");
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();
            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            var user = JsonSerializer.Deserialize<GitHubUser>(content, options);

            if (user == null)
            {
                throw new Exception("Failed to deserialize GitHub user information.");
            }

            return user;
        }
        catch (HttpRequestException ex)
        {
            Console.WriteLine($"HTTP request failed: {ex.Message}");
            throw;
        }
        catch (JsonException ex)
        {
            Console.WriteLine($"JSON deserialization failed: {ex.Message}");
            throw;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"An unexpected error occurred: {ex.Message}");
            throw;
        }
    }
}