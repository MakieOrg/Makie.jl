__precompile__(true)
module MakiE

using Colors, GeometryTypes, GLVisualize, GLAbstraction, ColorVectorSpace
using StaticArrays, GLWindow, ModernGL

using Base.Iterators: repeated, drop
using Base: RefValue

const makie = Base.RefValue{:makie}
const current_backend = RefValue(makie())

include("plotsbase/utils.jl")
include("plotsbase/scene.jl")
include("plotsbase/converts.jl")

include("plotsbase/atomics.jl")
    include("atomics/scatter.jl")
    include("atomics/lines.jl")
    include("atomics/text.jl")
    include("atomics/surface.jl")
    include("atomics/wireframe.jl")
    include("atomics/mesh.jl")

include("plotsbase/axis.jl")





export Scene

export scatter, lines, linesegment, mesh, surface, wireframe, axis
export @ref, to_node, to_value, lift_node, to_world

end # module
