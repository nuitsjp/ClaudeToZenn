using FluentAssertions;

namespace ClaudeToZenn.Test;

public class RequestTest
{
    [Fact]
    public void Parse()
    {
        #region message

        const string message =
            "{\"action\":\"post\",\"fileName\":\"artifacts.md\",\"content\":\"contents\",\"repositoryPath\":\"C:\\\\foo\\\\bar\\\\\"}";

        #endregion

        var actual = Request.Parse(message);
        actual.Action.Should().Be("post");
        actual.FileName.Should().Be("artifacts.md");
        actual.Content.Should().Be("contents");
        actual.RepositoryPath.Should().Be("C:\\foo\\bar\\");
    }
}