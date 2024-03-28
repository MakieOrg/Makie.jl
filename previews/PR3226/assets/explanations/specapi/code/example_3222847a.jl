# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
import Makie.SpecApi as S
using Random
CairoMakie.activate!() # hide

Random.seed!(123)

# define a struct for `convert_arguments`
struct CustomMatrix
    data::Matrix{Float32}
    style::Symbol
    kw::Dict{Symbol,Any}
end
CustomMatrix(data; style, kw...) = CustomMatrix(data, style, Dict{Symbol,Any}(kw))

function Makie.convert_arguments(::Type{<:AbstractPlot}, obj::CustomMatrix)
    plots = PlotSpec[]
    if obj.style === :heatmap
        push!(plots, S.Heatmap(obj.data; obj.kw...))
    elseif obj.style === :contourf
        push!(plots, S.Contourf(obj.data; obj.kw...))
    end
    max_position = Tuple(argmax(obj.data))
    push!(plots, S.Scatter(max_position; markersize = 30, strokecolor = :white, color = :transparent, strokewidth = 4))
    return plots
end

data = randn(30, 30)

f = Figure()
ax = Axis(f[1, 1])
# We can either plot into an existing Axis
plot!(ax, CustomMatrix(data, style = :heatmap, colormap = :Blues))
# Or create a new one automatically as we are used to from the standard API
plot(f[1, 2], CustomMatrix(data, style = :contourf, colormap = :inferno))
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_3222847a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_3222847a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide