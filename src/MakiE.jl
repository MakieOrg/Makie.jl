__precompile__(true)
module MakiE

using Colors, GeometryTypes, GLVisualize, GLAbstraction, ColorVectorSpace
using StaticArrays, GLWindow, ModernGL

using Base.Iterators: repeated, drop

include("utils.jl")
include("scene.jl")
include("converts.jl")

include("primitives/scatter.jl")
include("primitives/lines.jl")
include("primitives/text.jl")
include("primitives/surface.jl")
include("primitives/wireframe.jl")
include("primitives/mesh.jl")
include("axis.jl")

include("primitives.jl")


export Scene

export scatter, lines, linesegment, mesh, surface, wireframe, axis
export @ref, to_node, lift_node, to_world

end # module
