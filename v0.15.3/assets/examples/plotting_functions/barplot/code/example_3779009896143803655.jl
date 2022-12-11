# This file was generated, do not modify it. # hide
__result = begin # hide
  
barplot(tbl.x, tbl.height,
        dodge = tbl.grp1,
        stack = tbl.grp2,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Dodged and stacked bars"),
        )

  end # hide
  save(joinpath(@OUTPUT, "example_3779009896143803655.png"), __result) # hide
  
  nothing # hide