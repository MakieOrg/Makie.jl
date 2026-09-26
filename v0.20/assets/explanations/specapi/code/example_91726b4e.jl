# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
import Makie.SpecApi as S
CairoMakie.activate!() # hide

# Our custom type we want to write a conversion method for
struct PlotGrid
    nplots::Tuple{Int,Int}
end

# If we want to use the `color` attribute in the conversion, we have to
# mark it via `used_attributes`
Makie.used_attributes(::PlotGrid) = (:color,)

# The conversion method creates a grid of `Axis` objects with `Lines` plot inside
# We restrict to Plot{plot}, so that only `plot(PlotGrid(...))` works, but not e.g. `scatter(PlotGrid(...))`.
function Makie.convert_arguments(::Type{Plot{plot}}, obj::PlotGrid; color=:black)
    axes = [
        S.Axis(plots=[S.Lines(cumsum(randn(1000)); color=color)])
            for i in 1:obj.nplots[1],
                j in 1:obj.nplots[2]
    ]
    return S.GridLayout(axes)
end

# Now, when we plot `PlotGrid` we get a whole facet layout
plot(PlotGrid((3, 4)))
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_91726b4e_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_91726b4e.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_91726b4e.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide