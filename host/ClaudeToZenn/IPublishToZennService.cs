namespace ClaudeToZenn;

public interface IPublishToZennService
{
    Task<Result> PublishAsync(Request request);
}