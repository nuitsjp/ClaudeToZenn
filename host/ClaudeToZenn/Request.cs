namespace ClaudeToZenn;

public record Request(
    string Title,
    string Content,
    string RepositoryPath,
    string FileName);