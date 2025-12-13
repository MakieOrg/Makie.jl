# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

Label(f[1, 1],
    "Left Justified\nMultiline\nLabel\nLineheight 0.9",
    justification = :left,
    lineheight = 0.9
)
Label(f[1, 2],
    "Center Justified\nMultiline\nLabel\nLineheight 1.1",
    justification = :center,
    lineheight = 1.1
)
Label(f[1, 3],
    "Right Justified\nMultiline\nLabel\nLineheight 1.3",
    justification = :right,
    lineheight = 1.3
)

f
end # hide
save(joinpath(@OUTPUT, "example_8628039835119085296.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_8628039835119085296.svg"), __result; ) # hide
nothing # hide