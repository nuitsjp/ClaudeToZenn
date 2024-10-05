using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net.Http;
using System.Web;
using Azure.Security.KeyVault.Secrets;
using System.Net.Http.Headers;
using System.Text.Json;

namespace ClaudeToZenn.Functions;

public class OAuthCallback
{
    private readonly KeyVaultEncryptionHelper _encryptionHelper;
    private readonly HttpClient _httpClient;
    private readonly KeyVaultTokenManager _tokenManager;

    public OAuthCallback(KeyVaultEncryptionHelper encryptionHelper, IHttpClientFactory httpClientFactory, KeyVaultTokenManager tokenManager)
    {
        _encryptionHelper = encryptionHelper;
        _httpClient = httpClientFactory.CreateClient();
        _tokenManager = tokenManager;
    }


    [Function("OAuthCallback")]
    public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        var query = HttpUtility.ParseQueryString(req.Url.Query);
        var code = query["code"];
        var encryptedState = query["state"];

        try
        {
            // URLデコードを行ってから復号化
            var urlDecodedState = HttpUtility.UrlDecode(encryptedState);
            var decryptedState = await _encryptionHelper.DecryptAsync(urlDecodedState);
            var parts = decryptedState.Split('|');
            var timestamp = DateTime.Parse(parts[0]);
            var nonce = parts[1];

            // 有効期限のチェック（例：10分）
            if (DateTime.UtcNow - timestamp > TimeSpan.FromMinutes(10))
            {
                return req.CreateResponse(HttpStatusCode.BadRequest);
            }

            // アクセストークンの取得
            var accessToken = await GetAccessTokenAsync(code);

            // ユーザー情報の取得
            var userInfo = await GetGitHubUserInfoAsync(accessToken);
            var userId = userInfo.Id.ToString();

            // アクセストークンの保存
            await _tokenManager.SaveTokenAsync(userId, accessToken);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "text/html; charset=utf-8");
            response.WriteString($"<html><body><h1>認証成功</h1><p>UserId: {userId}</p><script>window.opener.postMessage({{ userId: '{userId}' }}, '*'); window.close();</script></body></html>");
            return response;
        }
        catch (Exception ex)
        {
            // エラーログの記録
            Console.WriteLine($"State verification failed: {ex.Message}");
            return req.CreateResponse(HttpStatusCode.BadRequest);
        }
    }

    private async Task<string> GetAccessTokenAsync(string code)
    {
        var clientId = Environment.GetEnvironmentVariable("GitHubClientId");
        var clientSecret = Environment.GetEnvironmentVariable("GitHubClientSecret");
        var redirectUri = Environment.GetEnvironmentVariable("REDIRECT_URI");

        var requestContent = new FormUrlEncodedContent(new[]
        {
            new KeyValuePair<string, string>("client_id", clientId),
            new KeyValuePair<string, string>("client_secret", clientSecret),
            new KeyValuePair<string, string>("code", code),
            new KeyValuePair<string, string>("redirect_uri", redirectUri)
        });

        var response = await _httpClient.PostAsync("https://github.com/login/oauth/access_token", requestContent);
        response.EnsureSuccessStatusCode();

        var responseContent = await response.Content.ReadAsStringAsync();
        var parsedContent = HttpUtility.ParseQueryString(responseContent);
        return parsedContent["access_token"];
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