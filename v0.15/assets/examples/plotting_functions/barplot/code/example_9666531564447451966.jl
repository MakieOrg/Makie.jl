# This file was generated, do not modify it. # hide
__result = begin # hide
  
barplot(tbl.x, tbl.height,
        dodge = tbl.grp,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Dodged bars"),
        )

  end # hide
  save(joinpath(@OUTPUT, "example_9666531564447451966.png"), __result) # hide
  
  nothing # hide