module CairoMakie

using Makie, LinearAlgebra
using Colors, GeometryBasics, FileIO
import SHA
import Base64
import Cairo

using Makie: Scene, Lines, Text, Image, Heatmap, Scatter, @key_str, broadcast_foreach
using Makie: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using Makie: @info, @get_attribute, Combined, MakieScreen
using Makie: to_value, to_colormap, extrema_nan, apply_scale
using Makie.Observables
using Makie: spaces, is_data_space, is_pixel_space, is_relative_space, is_clip_space
using Makie: numbers_to_colors

# re-export Makie, including deprecated names
for name in names(Makie, all=true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

include("cairo-extension.jl")
include("screen.jl")
include("display.jl")
include("infrastructure.jl")
include("utils.jl")
include("primitives.jl")
include("overrides.jl")

function __init__()
    activate!()
end

include("precompiles.jl")

end
