namespace VTA.API.DTOs;

public class FileChangeDTO
{
    public required string FileId { get; set; }

    public required string FileName { get; set; }

    public required string FileType { get; set; }

    public DateTime? ModifiedDate { get; set; }

    public string? ImageUrl { get; set; }

    public string? SoundUrl { get; set; }
}

public class SyncResponseDTO
{
    public required List<FileChangeDTO> ChangedFiles { get; set; }

    public DateTime CheckDate { get; set; }

    public int TotalChanges { get; set; }
}

public class SyncSummaryDTO
{
    public int TotalChanges { get; set; }

    public int ArtefactChanges { get; set; }

    public int BoardChanges { get; set; }

    public DateTime CheckDate { get; set; }
}
