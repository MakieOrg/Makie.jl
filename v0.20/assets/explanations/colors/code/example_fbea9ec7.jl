# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide
using Makie.Colors

theme = Attributes(
    Scatter = (; markersize = 40),
    Text = (; align = (:center, :bottom), offset = (0, 30))
)

with_theme(theme) do

    f = Figure(size = (800, 1200))
    ax = Axis(f[1, 1], xautolimitmargin = (0.2, 0.2), yautolimitmargin = (0.1, 0.1))
    hidedecorations!(ax)
    hidespines!(ax)

    scatter!(ax, 1, 1, color = :red)
    text!(ax, 1, 1, text = ":red")

    scatter!(ax, 2, 1, color = (:red, 0.5))
    text!(ax, 2, 1, text = "(:red, 0.5)")

    scatter!(ax, 3, 1, color = RGBf(0.5, 0.2, 0.8))
    text!(ax, 3, 1, text = "RGBf(0.5, 0.2, 0.8)")
    
    scatter!(ax, 4, 1, color = RGBAf(0.5, 0.2, 0.8, 0.5))
    text!(ax, 4, 1, text = "RGBAf(0.5, 0.2, 0.8, 0.5)")

    scatter!(ax, 1, 0, color = Colors.HSV(40, 30, 60))
    text!(ax, 1, 0, text = "Colors.HSV(40, 30, 60)")

    scatter!(ax, 2, 0, color = 1, colormap = :tab10, colorrange = (1, 10))
    text!(ax, 2, 0, text = "color = 1\ncolormap = :tab10\ncolorrange = (1, 10)")

    scatter!(ax, 3, 0, color = 2, colormap = :tab10, colorrange = (1, 10))
    text!(ax, 3, 0, text = "color = 2\ncolormap = :tab10\ncolorrange = (1, 10)")

    scatter!(ax, 4, 0, color = 3, colormap = :tab10, colorrange = (1, 10))
    text!(ax, 4, 0, text = "color = 3\ncolormap = :tab10\ncolorrange = (1, 10)")

    text!(ax, 2.5, -1, text = "color = 1:10\ncolormap = :viridis\ncolorrange = automatic")
    scatter!(ax, range(1, 4, length = 10), fill(-1, 10), color = 1:10, colormap = :viridis)

    text!(ax, 2.5, -2, text = "color = [1, 2, 3, 4, NaN, 6, 7, 8, 9, 10]\ncolormap = :viridis\ncolorrange = (2, 9)")
    scatter!(ax, range(1, 4, length = 10), fill(-2, 10), color = [1, 2, 3, 4, NaN, 6, 7, 8, 9, 10], colormap = :viridis, colorrange = (2, 9))

    text!(ax, 2.5, -3, text = "color = [1, 2, 3, 4, NaN, 6, 7, 8, 9, 10]\ncolormap = :viridis\ncolorrange = (2, 9)\nnan_color = :red, highclip = :magenta, lowclip = :cyan")
    scatter!(ax, range(1, 4, length = 10), fill(-3, 10), color = [1, 2, 3, 4, NaN, 6, 7, 8, 9, 10], colormap = :viridis, colorrange = (2, 9), nan_color = :red, highclip = :magenta, lowclip = :cyan)
    
    text!(ax, 2.5, -4, text = "color = HSV.(range(0, 360, 10), 50, 50)")
    scatter!(ax, range(1, 4, length = 10), fill(-4, 10), color = HSV.(range(0, 360, 10), 50, 50))

    text!(ax, 2.5, -5, text = "color = 1:10\ncolormap = (:viridis, 0.5)\ncolorrange = automatic")
    scatter!(ax, range(1, 4, length = 10), fill(-5, 10), color = 1:10, colormap = (:viridis, 0.5))

    text!(ax, 2.5, -6, text = "color = 1:10\ncolormap = [:red, :orange, :brown]\ncolorrange = automatic")
    scatter!(ax, range(1, 4, length = 10), fill(-6, 10), color = 1:10, colormap = [:red, :orange, :brown])
    
    text!(ax, 2.5, -7, text = "color = 1:10\ncolormap = Reverse(:viridis)\ncolorrange = automatic")
    scatter!(ax, range(1, 4, length = 10), fill(-7, 10), color = 1:10, colormap = Reverse(:viridis))

    f
end
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_fbea9ec7_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_fbea9ec7.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_fbea9ec7.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide