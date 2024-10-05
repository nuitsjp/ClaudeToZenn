using System.Text.Json;

namespace ClaudeToZenn;

public record Request(
    string Action,
    string Content,
    string RepositoryPath)
{
    public static Request Parse(string message)
    {
        // 先頭が小文字のJSONをデシリアライズするためには、JsonSerializerOptions.PropertyNameCaseInsensitiveを指定する
        return JsonSerializer.Deserialize<Request>(
            message, 
            new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            })!;
    }

    public string ToJson()
    {
        return JsonSerializer.Serialize(this);
    }
};