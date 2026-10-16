# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure(fontsize = 30)
Label(
    f[1, 1],
    rich(
        "H", subscript("2"), "O is the formula for ",
        rich("water", color = :cornflowerblue, font = :italic)
    )
)

str = "A BEAUTIFUL RAINBOW"
rainbow = cgrad(:rainbow, length(str), categorical = true)
fontsizes = 30 .+ 10 .* sin.(range(0, 3pi, length = length(str)))

rainbow_chars = map(enumerate(str)) do (i, c)
    rich("$c", color = rainbow[i], fontsize = fontsizes[i])
end

Label(f[2, 1], rich(rainbow_chars...), font = :bold)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_6d379955_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_6d379955.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_6d379955.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide