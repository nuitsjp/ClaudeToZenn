using Octokit;

var client = new GitHubClient(new ProductHeaderValue("YourAppName"));
var clientId = "YOUR_CLIENT_ID"; // OAuth Appから取得したクライアントID

var request = new OauthDeviceFlowRequest(clientId);
request.Scopes.Add("repo"); // プライベートリポジトリへのアクセス権を要求

var deviceFlow = await client.Oauth.InitiateDeviceFlow(request);
Console.WriteLine($"Please visit: {deviceFlow.VerificationUri}");
Console.WriteLine($"And enter the code: {deviceFlow.UserCode}");

var token = await client.Oauth.CreateAccessTokenForDeviceFlow(clientId, deviceFlow);
client.Credentials = new Credentials(token.AccessToken);