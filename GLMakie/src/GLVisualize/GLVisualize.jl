module GLVisualize

using ..GLAbstraction
using Makie: RaymarchAlgorithm, IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA

using ..GLMakie.GLFW
using ModernGL
using GeometryBasics
using Colors
using Makie
using FixedPointNumbers
using FileIO
using Markdown
using Observables
using GeometryBasics: StaticVector

import Base: merge, convert, show
using Base.Iterators: Repeated, repeated
using LinearAlgebra

import Makie: to_font, glyph_uv_width!, el32convert
import ..GLMakie: get_texture!, loadshader

const GLBoundingBox = Rect3f

include("visualize_interface.jl")
export visualize # Visualize an object

include(joinpath("visualize", "lines.jl"))
include(joinpath("visualize", "image_like.jl"))
include(joinpath("visualize", "mesh.jl"))
include(joinpath("visualize", "particles.jl"))
include(joinpath("visualize", "surface.jl"))

export CIRCLE, RECTANGLE, ROUNDED_RECTANGLE, DISTANCEFIELD, TRIANGLE

end # module
