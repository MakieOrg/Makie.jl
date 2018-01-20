__precompile__(true)
module Makie

using Colors, GeometryTypes, GLVisualize, GLAbstraction, ColorVectorSpace
using StaticArrays, GLWindow, ModernGL, Contour, Quaternions

using Base.Iterators: repeated, drop
using Base: RefValue
using Fontconfig, FreeType, FreeTypeAbstraction, UnicodeFun

struct Backend{B} end


include("plotutils/utils.jl")

include("plotsbase/scene.jl")
include("plotsbase/conversions.jl")
include("plotutils/units.jl")

const makie = Scene{:makie}


# Until I find a non breaking way to integrate this into GLAbstraction, it lives here.
GLAbstraction.gl_convert(a::Vector{T}) where T = convert(Vector{GLAbstraction.gl_promote(T)}, a)

include("plotutils/layout.jl")

include("plotsbase/atomics.jl")
    # The actual implementation
    include("atomics/shared.jl")
    include("atomics/scatter.jl")
    include("atomics/lines.jl")
    include("atomics/text.jl")
    include("atomics/surface.jl")
    include("atomics/wireframe.jl")
    include("atomics/mesh.jl")
    include("atomics/imagelike.jl")
    include("plotsbase/contour.jl")
    include("plotsbase/legend.jl")

include("plotsbase/axis.jl")
include("plotsbase/output.jl")
include("iodevices.jl")
include("camera2d.jl")
# include("camera3d.jl")

export Scene, Node

export scatter, lines, linesegment, mesh, surface, wireframe, axis, text, text_overlay!
export @ref, @theme, @default, to_node, to_value, lift_node, to_world, save
export available_marker_symbols, available_gradients, render_frame

# conversion

export to_float, to_markersize2d, to_spritemarker, to_linestyle, to_pattern
export to_color, to_colormap, to_colornorm, to_array, to_mesh, to_surface

export to_scale
export to_offset
export to_rotation
export to_image
export to_bool
export to_index_buffer
export to_index_buffer
export to_positions
export to_position
export to_array
export to_scalefunc
export to_text
export to_font
export to_intensity
export to_surface
export to_spritemarker
export to_static_vec
export to_rotations
export to_markersize2d
export to_markersize3d
export to_linestyle
export to_normals
export to_faces
export to_attribut_id
export to_mesh
export to_float
export to_color
export to_colornorm
export to_colormap
export available_gradients
export to_spatial_order
export to_interval
export to_volume_algorithm
export to_3floats
export to_2floats
export to_textalign

end # module
