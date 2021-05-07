module CairoMakie

using AbstractPlotting, LinearAlgebra
using Colors, GeometryBasics, FileIO, StaticArrays
import Cairo

using AbstractPlotting: Scene, Lines, Text, Image, Heatmap, Scatter, @key_str, broadcast_foreach
using AbstractPlotting: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using AbstractPlotting: @info, @get_attribute, Combined
using AbstractPlotting: to_value, to_colormap, extrema_nan

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

# re-export AbstractPlotting
for name in names(AbstractPlotting)
    @eval using AbstractPlotting: $(name)
    @eval export $(name)
end

include("infrastructure.jl")
include("utils.jl")
include("fonts.jl")
include("primitives.jl")
include("overrides.jl")

function __init__()
    activate!()
    AbstractPlotting.register_backend!(AbstractPlotting.current_backend[])
end

function display_path(type::String)
    if !(type in ("svg", "png", "pdf", "eps"))
        error("Only \"svg\", \"png\", \"eps\" and \"pdf\" are allowed for `type`. Found: $(type)")
    end
    return joinpath(@__DIR__, "display." * type)
end

function activate!(; inline = true, type = "png", px_per_unit=1, pt_per_unit=1)
    backend = CairoBackend(display_path(type); px_per_unit=px_per_unit, pt_per_unit=pt_per_unit)
    AbstractPlotting.current_backend[] = backend
    AbstractPlotting.use_display[] = !inline
    return
end

end
