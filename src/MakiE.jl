__precompile__(true)
module MakiE

using Colors, GeometryTypes, GLVisualize, GLAbstraction, ColorVectorSpace
using StaticArrays, GLWindow, ModernGL

using Base.Iterators: repeated, drop
using Base: RefValue

struct Backend{B} end

const makie = Backend{:makie}
const current_backend = RefValue(makie())

include("plotsbase/utils.jl")
include("plotsbase/scene.jl")
include("plotsbase/converts.jl")

include("plotsbase/atomics.jl")
    # The actual implementation
    include("atomics/scatter.jl")
    include("atomics/lines.jl")
    include("atomics/text.jl")
    include("atomics/surface.jl")
    include("atomics/wireframe.jl")
    include("atomics/mesh.jl")

include("plotsbase/axis.jl")
include("plotsbase/output.jl")

export Scene

export scatter, lines, linesegment, mesh, surface, wireframe, axis
export @ref, @theme, @default, to_node, to_value, lift_node, to_world, save
export available_marker_symbols, available_gradients, render_frame

# conversion

export to_float, to_markersize, to_spritemarker, to_linestyle, to_pattern
export to_color, to_colormap, to_colornorm, to_array, to_mesh, to_surface
export to_positions, to_rotations

end # module
