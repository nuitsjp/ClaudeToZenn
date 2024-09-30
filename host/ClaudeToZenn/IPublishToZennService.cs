namespace ClaudeToZenn;

public interface IPublishToZennService
{
    Task<Result> PublishAsync(Request request);
}

public class PublishToZennService : IPublishToZennService
{
    public async Task<Result> PublishAsync(Request request)
    {
        try
        {
            var path = Path.Combine(@"C:\Repos\Zenn", "articles", request.FileName);
            File.WriteAllText(path, request.Content);
            return new Result(true, null);
        }
        catch (Exception e)
        {
            return new Result(false, e.Message);
        }
    }
}
