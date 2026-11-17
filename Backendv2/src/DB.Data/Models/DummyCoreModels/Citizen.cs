<<<<<<< Updated upstream
﻿namespace Backendv2.DB.Data;
=======
﻿using System;
using System.Collections.Generic;
using Backendv2.DB.Data;

namespace Backendv2.ModelsDC;
>>>>>>> Stashed changes

public partial class Citizen
{
    public int Id { get; set; }

    public int ClassId { get; set; }

    public virtual Class Class { get; set; } = null!;

    public virtual User IdNavigation { get; set; } = null!;

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();

    public virtual ICollection<NonCitizen> Guardians { get; set; } = new List<NonCitizen>();
}
