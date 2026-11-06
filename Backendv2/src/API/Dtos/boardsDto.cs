

namespace Backendv2.src.API.Dtos;

public class BoardGetDTO

{
   public int ID { get; set; }
   public int userID { get; set; }
   public required string Name { get; set; }

}

public class BoardPostDTO
{
   public required string Name { get; set; }

}