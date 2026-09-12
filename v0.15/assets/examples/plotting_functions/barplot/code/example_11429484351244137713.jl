# This file was generated, do not modify it. # hide
__result = begin # hide
  
barplot([-1, -0.5, 0.5, 1],
    bar_labels = :y,
    axis = (title="Fonts + flip_labels_at",),
    label_size = 20,
    flip_labels_at=(-0.8, 0.8),
    label_color=[:white, :green, :black, :white],
    label_formatter = x-> "Flip at $(x)?",
    label_offset = 10
)

  end # hide
  save(joinpath(@OUTPUT, "example_11429484351244137713.png"), __result) # hide
  
  nothing # hide