module CairoMakie

using Makie, LinearAlgebra
using Colors, GeometryBasics, FileIO
import SHA
import Base64
import Cairo

using Makie: Scene, Lines, Text, Image, Heatmap, Scatter, @key_str, broadcast_foreach
using Makie: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using Makie: @info, @get_attribute, PlotObject
using Makie: to_value, to_colormap, extrema_nan
using Makie: inline!
using Makie.Observables
using Makie: spaces, is_data_space, is_pixel_space, is_relative_space, is_clip_space

const OneOrVec{T} = Union{
    T,
    Vec{N1, T} where N1,
    NTuple{N2, T} where N2,
}

# re-export Makie, including deprecated names
for name in names(Makie, all=true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
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

const _last_inline = Ref(true)
const _last_type = Ref("png")
const _last_px_per_unit = Ref(1.0)
const _last_pt_per_unit = Ref(0.75)
const _last_antialias = Ref(Cairo.ANTIALIAS_BEST)

function activate!(; inline = _last_inline[], type = _last_type[], px_per_unit=_last_px_per_unit[], pt_per_unit=_last_pt_per_unit[], antialias = _last_antialias[])
    backend = CairoBackend(display_path(type); px_per_unit=px_per_unit, pt_per_unit=pt_per_unit, antialias = antialias)
    Makie.current_backend[] = backend
    Makie.use_display[] = !inline
    _last_inline[] = inline
    _last_type[] = type
    _last_px_per_unit[] = px_per_unit
    _last_pt_per_unit[] = pt_per_unit
    _last_antialias[] = antialias
    return
end

if Base.VERSION >= v"1.4.2"
    include("precompiles.jl")
    _precompile_()
end


end
