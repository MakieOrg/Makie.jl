# This file was generated, do not modify it. # hide
__result = begin # hide
  
lines_theme = Theme(
    Lines = (
        linewidth = 4,
        linestyle = :dash,
    )
)

with_theme(example_plot, lines_theme)

  end # hide
  save(joinpath(@OUTPUT, "example_3908551913716021428.png"), __result) # hide
  
  nothing # hide