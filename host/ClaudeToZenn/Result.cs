using System.Text.Json;

namespace ClaudeToZenn;

public record Result(
    bool IsSuccess,
    string? Exception)
{
    public string ToJson()
    {
        return JsonSerializer.Serialize(this);
    }
};