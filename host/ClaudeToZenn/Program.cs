using System.Text;
using ClaudeToZenn;

#if DEBUG
System.Diagnostics.Debugger.Launch();
#endif

var message = ReadMessage();
if (string.IsNullOrEmpty(message))
{
    return ;
}

try
{
    var request = Request.Parse(message);
    var service = new PublishToZennService();
    var result = service.Publish(request);
    SendMessage(result);
}
catch (Exception e)
{
    SendMessage(new Result(false, e.Message));
}

return;

string ReadMessage()
{
    using var standardInput = Console.OpenStandardInput();
    var lengthBytes = new byte[4];
    // ReSharper disable once MustUseReturnValue
    standardInput.Read(lengthBytes, 0, 4);
    var length = BitConverter.ToInt32(lengthBytes, 0);

    var buffer = new byte[length];
    // ReSharper disable once MustUseReturnValue
    standardInput.Read(buffer, 0, buffer.Length);
    return Encoding.UTF8.GetString(buffer);
}

void SendMessage(Result result)
{
    var bytes = Encoding.UTF8.GetBytes(result.ToJson());
    using var stdout = Console.OpenStandardOutput();
    stdout.Write(BitConverter.GetBytes(bytes.Length), 0, 4);
    stdout.Write(bytes, 0, bytes.Length);
    stdout.Flush();
}
