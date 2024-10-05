using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace ClaudeToZenn.Functions;

public class InitiateOAuth
{
    private readonly KeyVaultEncryptionHelper _encryptionHelper;

    public InitiateOAuth(KeyVaultEncryptionHelper encryptionHelper)
    {
        _encryptionHelper = encryptionHelper;
    }

    [Function("InitiateOAuth")]
    public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        var timestamp = DateTime.UtcNow.ToString("O");
        var nonce = Guid.NewGuid().ToString();
        var stateData = $"{timestamp}|{nonce}";
        var encryptedState = await _encryptionHelper.EncryptAsync(stateData);

        var clientId = Environment.GetEnvironmentVariable("GitHubClientId");
        var redirectUri = Environment.GetEnvironmentVariable("REDIRECT_URI");
        var scope = "repo";

        var authorizationUrl = $"https://github.com/login/oauth/authorize?client_id={clientId}&redirect_uri={redirectUri}&scope={scope}&state={encryptedState}";

        var response = req.CreateResponse(HttpStatusCode.Redirect);
        response.Headers.Add("Location", authorizationUrl);

        return response;
    }
}