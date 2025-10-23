using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace VTA.API.DbContexts;

public static class Converters
{
    public static ValueConverter<Guid, byte[]> GuidToBytesConverter = new (
        v => v.ToByteArray(),
        v => new Guid(v));
}