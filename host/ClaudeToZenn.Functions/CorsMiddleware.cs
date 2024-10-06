using Microsoft.AspNetCore.Http.Features;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Middleware;

namespace ClaudeToZenn.Functions;

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