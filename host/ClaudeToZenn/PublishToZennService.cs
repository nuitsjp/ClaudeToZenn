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

            var psi = new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = $"/c Publish.cmd \"{request.RepositoryPath}\" \"publish {fileName}\" \"{filePath}\"", // /c オプションを使用して、コマンド実行後にウィンドウを閉じないようにします
                UseShellExecute = true,
                RedirectStandardOutput = false,
                RedirectStandardError = false,
                CreateNoWindow = false // コンソールウィンドウを表示
            };

            var process = new Process { StartInfo = psi };

            process.Start();

            return new Result(true, null);
        }
        catch (Exception ex)
        {
            return new Result(false, ex.Message);
        }
    }
}