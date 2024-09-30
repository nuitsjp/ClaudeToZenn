using System;
using System.Text;
using System.Text.Json;

System.Diagnostics.Debugger.Launch();

while (true)
{
    var message = ReadMessage();
    if (message == null)
        break;

    if (string.IsNullOrEmpty(message))
    {
        await Task.Delay(TimeSpan.FromMilliseconds(100));
        continue;
    }

    var response = ProcessMessage(message);
    SendMessage(response);

}

string? ReadMessage()
{
    var standardInput = Console.OpenStandardInput();
    var lengthBytes = new byte[4];
    // ReSharper disable once MustUseReturnValue
    standardInput.Read(lengthBytes, 0, 4);
    var length = BitConverter.ToInt32(lengthBytes, 0);

    var buffer = new byte[length];
    // ReSharper disable once MustUseReturnValue
    standardInput.Read(buffer, 0, buffer.Length);
    return Encoding.UTF8.GetString(buffer);
}

void SendMessage(string message)
{
    var bytes = Encoding.UTF8.GetBytes(message);
    var stdout = Console.OpenStandardOutput();
    stdout.Write(BitConverter.GetBytes(bytes.Length), 0, 4);
    stdout.Write(bytes, 0, bytes.Length);
    stdout.Flush();
}

string ProcessMessage(string message)
{
    try
    {
        using JsonDocument doc = JsonDocument.Parse(message);
        var root = doc.RootElement;
        var action = root.GetProperty("action").GetString();

        return action switch
        {
            "hello" => JsonSerializer.Serialize(new { response = "Hello from Native Messaging Host!" }),
            "echo" => JsonSerializer.Serialize(new { response = $"Echo: {root.GetProperty("text").GetString()}" }),
            _ => JsonSerializer.Serialize(new { error = "Unknown action" })
        };
    }
    catch (Exception ex)
    {
        return JsonSerializer.Serialize(new { error = ex.Message });
    }
}