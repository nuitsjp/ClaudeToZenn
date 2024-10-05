using System.Diagnostics;

namespace ClaudeToZenn;

public class PublishToZennService : IPublishToZennService
{
    public Result Publish(Request request)
    {
        try
        {
            // Request.Contentの1行目にファイル名が含まれているため、1行目とそれ以降で分離する
            var lines = request.Content.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);
            var fileName = lines[0];
            var content = string.Join(Environment.NewLine, lines.Skip(1));

            var filePath = Path.Combine(request.RepositoryPath, "articles", fileName);
            File.WriteAllText(filePath, content);

            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "pwsh.exe", // PowerShell Core実行ファイル
                    Arguments = $"-Command \"& {{.\\Publish-Article.ps1 -RepoPath '{request.RepositoryPath}' -ArticleTitle 'publish {fileName}' -FilePath '{filePath}'}}\"",
                    UseShellExecute = true,
                    CreateNoWindow = false
                }
            };
            process.Start();

            return new Result(true, null);
        }
        catch (Exception ex)
        {
            return new Result(false, ex.Message);
        }
    }
}