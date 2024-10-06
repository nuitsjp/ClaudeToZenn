using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using ClaudeToZenn.Functions;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.Azure.Functions.Worker.Middleware;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults(workerApplication =>
    {
        workerApplication.UseMiddleware<CorsMiddleware>();
    })
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
        services.AddCors(options =>
        {
            options.AddPolicy("AllowSpecificOrigin",
                builder => builder
                    .WithOrigins("chrome-extension://mlhbhgjbdbgealohaocdehgkopefkndd")
                    .AllowAnyMethod()
                    .AllowAnyHeader()
                    .AllowCredentials());
        });
    })
    .Build();

await host.RunAsync();

public class CorsMiddleware : IFunctionsWorkerMiddleware
{
    public async Task Invoke(FunctionContext context, FunctionExecutionDelegate next)
    {
        context.Features.Set<IHttpResponseFeature>(new HttpResponseFeature
        {
            Headers =
            {
                ["Access-Control-Allow-Origin"] = "chrome-extension://mlhbhgjbdbgealohaocdehgkopefkndd",
                ["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS",
                ["Access-Control-Allow-Headers"] = "*",
                ["Access-Control-Allow-Credentials"] = "true"
            }
        });

        await next(context);
    }
}