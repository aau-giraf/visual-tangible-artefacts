using Xunit;

//Backendv2/src/Tests/TestProject.csproj
namespace Tests;

public class TestFile{

[Fact]
void PrintHello()
    {
            var message = "Hello world :)";
            Assert.Contains(message,"Hello world :)");
    }
}


