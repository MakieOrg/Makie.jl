module CairoMakie

using Makie, LinearAlgebra
using Colors, GeometryBasics, FileIO, StaticArrays
import Cairo

using Makie: Scene, Lines, Text, Image, Heatmap, Scatter, @key_str, broadcast_foreach
using Makie: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using Makie: @info, @get_attribute, Combined
using Makie: to_value, to_colormap, extrema_nan
using Makie: inline!
const LIB_CAIRO = if isdefined(Cairo, :libcairo)
    Cairo.libcairo
else
    Cairo._jl_libcairo
end

const OneOrVec{T} = Union{
    T,
    Vec{N1, T} where N1,
    NTuple{N2, T} where N2,
}

# re-export Makie
for name in names(Makie)
    @eval using Makie: $(name)
    @eval export $(name)
end
export inline!

include("infrastructure.jl")
include("utils.jl")
include("fonts.jl")
include("primitives.jl")
include("overrides.jl")

function __init__()
    activate!()
    Makie.register_backend!(Makie.current_backend[])
end

function display_path(type::String)
    if !(type in ("svg", "png", "pdf", "eps"))
        error("Only \"svg\", \"png\", \"eps\" and \"pdf\" are allowed for `type`. Found: $(type)")
    end
    return joinpath(@__DIR__, "display." * type)
end

function activate!(; inline = true, type = "png", px_per_unit=1, pt_per_unit=1)
    backend = CairoBackend(display_path(type); px_per_unit=px_per_unit, pt_per_unit=pt_per_unit)
    Makie.current_backend[] = backend
    Makie.use_display[] = !inline
    return
end

end
