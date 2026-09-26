# This file was generated, do not modify it. # hide
__result = begin # hide
  
ggplot_theme = Theme(
    Axis = (
        backgroundcolor = :gray90,
        leftspinevisible = false,
        rightspinevisible = false,
        bottomspinevisible = false,
        topspinevisible = false,
        xgridcolor = :white,
        ygridcolor = :white,
    )
)

with_theme(example_plot, ggplot_theme)

  end # hide
  save(joinpath(@OUTPUT, "example_3726076456766619082.png"), __result) # hide
  
  nothing # hide