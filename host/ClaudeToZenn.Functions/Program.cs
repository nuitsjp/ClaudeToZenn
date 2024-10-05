using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using ClaudeToZenn.Functions;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();
        services.AddHttpClient();
        services.AddSingleton(sp =>
        {
            var keyVaultUrl = Environment.GetEnvironmentVariable("KeyVaultUrl");
            var keyName = Environment.GetEnvironmentVariable("CsrfProtectionKeyName");
            return new KeyVaultEncryptionHelper(keyVaultUrl, keyName);
        });
        services.AddSingleton(sp =>
        {
            var keyVaultUrl = Environment.GetEnvironmentVariable("KeyVaultUrl");
            return new SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());
        });
        services.AddSingleton<KeyVaultTokenManager>();
    })
    .Build();

host.Run();
