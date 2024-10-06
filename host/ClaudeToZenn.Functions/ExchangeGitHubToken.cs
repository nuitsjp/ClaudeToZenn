using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace ClaudeToZenn.Functions
{
    public class ExchangeGitHubToken
    {
        private readonly ILogger _logger;

        public ExchangeGitHubToken(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<ExchangeGitHubToken>();
        }

        [Function("ExchangeGitHubToken")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            string code = query["code"];

            if (string.IsNullOrEmpty(code))
            {
                var badRequestResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badRequestResponse.WriteStringAsync("Please pass a code on the query string");
                return badRequestResponse;
            }

            var clientId = Environment.GetEnvironmentVariable("GitHubClientId");
            var clientSecret = Environment.GetEnvironmentVariable("GitHubClientSecret");

            using (var client = new HttpClient())
            {
                var values = new Dictionary<string, string>
                {
                    { "client_id", clientId },
                    { "client_secret", clientSecret },
                    { "code", code }
                };
                var content = new FormUrlEncodedContent(values);
                var response = await client.PostAsync("https://github.com/login/oauth/access_token", content);
                var responseString = await response.Content.ReadAsStringAsync();

                var okResponse = req.CreateResponse(HttpStatusCode.OK);
                await okResponse.WriteStringAsync(responseString);
                return okResponse;
            }
        }
    }
}