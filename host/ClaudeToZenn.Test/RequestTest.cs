using FluentAssertions;

namespace ClaudeToZenn.Test;

public class RequestTest
{
    [Fact]
    public void Parse()
    {
        #region message

        const string message =
            "{\"action\":\"post\",\"content\":\"contents\",\"repositoryPath\":\"C:\\\\foo\\\\bar\\\\\"}";

        #endregion

        var actual = Request.Parse(message);
        actual.Action.Should().Be("post");
        actual.Content.Should().Be("contents");
        actual.RepositoryPath.Should().Be("C:\\foo\\bar\\");
    }
}