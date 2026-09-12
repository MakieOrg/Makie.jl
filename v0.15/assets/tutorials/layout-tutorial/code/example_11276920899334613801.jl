# This file was generated, do not modify it. # hide
__result = begin # hide
  
for (label, layout) in zip(["A", "B", "C", "D"], [ga, gb, gc, gd])
    Label(layout[1, 1, TopLeft()], label,
        textsize = 26,
        font = noto_sans_bold,
        padding = (0, 5, 5, 0),
        halign = :right)
end

f

  end # hide
  save(joinpath(@OUTPUT, "example_11276920899334613801.png"), __result) # hide
  
  nothing # hide