namespace ClaudeToZenn.Functions;

using Azure.Security.KeyVault.Secrets;
using System.Text.Json;

public class KeyVaultTokenManager(SecretClient secretClient)
{
    public async Task SaveTokenAsync(string userId, string accessToken)
    {
        var secretName = $"GitHubToken-{userId}";
        await secretClient.SetSecretAsync(secretName, accessToken);
    }

    public async Task<string> GetTokenAsync(string userId)
    {
        var secretName = $"GitHubToken-{userId}";
        var secret = await secretClient.GetSecretAsync(secretName);
        return secret.Value.Value;
    }

    public async Task DeleteTokenAsync(string userId)
    {
        var secretName = $"GitHubToken-{userId}";
        await secretClient.StartDeleteSecretAsync(secretName);
    }
}