module CairoMakie

using Makie.ComputePipeline
using Makie, LinearAlgebra
using Colors, GeometryBasics, FileIO
import CRC32c
import Cairo

using Makie: Scene, Lines, Text, Image, Heatmap, Scatter, @key_str, broadcast_foreach
using Makie: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using Makie: @info, @get_attribute, Plot, MakieScreen
using Makie: to_value, to_colormap, extrema_nan
using Makie.Observables
using Makie: spaces, is_data_space, is_pixel_space, is_relative_space, is_clip_space
using Makie: numbers_to_colors
using Makie: Mat3f, Mat4f, Mat3d, Mat4d
using Makie: sv_getindex
using Makie: compute_colors

# re-export Makie, including deprecated names
for name in names(Makie, all = true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

include("cairo-extension.jl")
include("screen.jl")
include("display.jl")
include("plot-primitives.jl")
include("utils.jl")
include("lines.jl")
include("scatter.jl")
include("image-hmap.jl")
include("mesh.jl")
include("overrides.jl")

function __init__()
    return activate!()
end

include("precompiles.jl")

end
