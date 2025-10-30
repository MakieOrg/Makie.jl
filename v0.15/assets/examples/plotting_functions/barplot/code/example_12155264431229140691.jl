# This file was generated, do not modify it. # hide
__result = begin # hide
  
barplot(
    tbl.x, tbl.height,
    dodge = tbl.grp,
    color = tbl.grp,
    bar_labels = :y,
    axis = (xticks = (1:3, ["left", "middle", "right"]),
            title = "Dodged bars horizontal with labels"),
    colormap = [:red, :green, :blue],
    color_over_background=:red,
    color_over_bar=:white,
    flip_labels_at=0.85,
    direction=:x,
)

  end # hide
  save(joinpath(@OUTPUT, "example_12155264431229140691.png"), __result) # hide
  
  nothing # hide