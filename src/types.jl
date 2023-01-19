abstract type AbstractCamera end

# placeholder if no camera is present
struct EmptyCamera <: AbstractCamera end

@enum RaymarchAlgorithm begin
    IsoValue # 0
    Absorption # 1
    MaximumIntensityProjection # 2
    AbsorptionRGBA # 3
    AdditiveRGBA # 4
    IndexedAbsorptionRGBA # 5
end


"""
    Camera(pixel_area)

Struct to hold all relevant matrices and additional parameters, to let backends
apply camera based transformations.
"""
struct Camera
    """
    projection used to convert pixel to device units
    """
    pixel_space::Observable{Mat4f}

    """
    View matrix is usually used to rotate, scale and translate the scene
    """
    view::Observable{Mat4f}

    """
    Projection matrix is used for any perspective transformation
    """
    projection::Observable{Mat4f}

    """
    just projection * view
    """
    projectionview::Observable{Mat4f}

    """
    resolution of the canvas this camera draws to
    """
    resolution::Observable{Vec2f}

    """
    Eye position of the camera, sued for e.g. ray tracing.
    """
    eyeposition::Observable{Vec3f}

    """
    To make camera interactive, steering observables are connected to the different matrices.
    We need to keep track of them, so, that we can connect and disconnect them.
    """
    steering_nodes::Vector{ObserverFunction}
end

"""
Holds the transformations for Scenes.
## Fields
$(TYPEDFIELDS)
"""
struct Transformation <: Transformable
    parent::RefValue{Transformation}
    translation::Observable{Vec3f}
    scale::Observable{Vec3f}
    rotation::Observable{Quaternionf}
    model::Observable{Mat4f}
    # data conversion observable, for e.g. log / log10 etc
    transform_func::Observable{Any}
    function Transformation(translation, scale, rotation, model, transform_func)
        return new(
            RefValue{Transformation}(),
            translation, scale, rotation, model, transform_func
        )
    end
end

"""
`PlotSpec{P<:AbstractPlot}(args...; kwargs...)`

Object encoding positional arguments (`args`), a `NamedTuple` of attributes (`kwargs`)
as well as plot type `P` of a basic plot.
"""
struct PlotSpec{P<:AbstractPlot}
    args::Tuple
    kwargs::NamedTuple
    PlotSpec{P}(args...; kwargs...) where {P<:AbstractPlot} = new{P}(args, values(kwargs))
end

PlotSpec(args...; kwargs...) = PlotSpec{Combined{Any}}(args...; kwargs...)

Base.getindex(p::PlotSpec, i::Int) = getindex(p.args, i)
Base.getindex(p::PlotSpec, i::Symbol) = getproperty(p.kwargs, i)

to_plotspec(::Type{P}, args; kwargs...) where {P} =
    PlotSpec{P}(args...; kwargs...)

to_plotspec(::Type{P}, p::PlotSpec{S}; kwargs...) where {P, S} =
    PlotSpec{plottype(P, S)}(p.args...; p.kwargs..., kwargs...)

plottype(::PlotSpec{P}) where {P} = P


struct ScalarOrVector{T}
    sv::Union{T, Vector{T}}
end

Base.convert(::Type{<:ScalarOrVector}, v::AbstractVector{T}) where T = ScalarOrVector{T}(collect(v))
Base.convert(::Type{<:ScalarOrVector}, x::T) where T = ScalarOrVector{T}(x)
Base.convert(::Type{<:ScalarOrVector{T}}, x::ScalarOrVector{T}) where T = x

function collect_vector(sv::ScalarOrVector, n::Int)
    if sv.sv isa Vector
        if length(sv.sv) != n
            error("Requested collected vector with $n elements, contained vector had $(length(sv.sv)) elements.")
        end
        sv.sv
    else
        fill(sv.sv, n)
    end
end

"""
    GlyphExtent

Store information about the bounding box of a single glyph.
"""
struct GlyphExtent
    ink_bounding_box::Rect2f
    ascender::Float32
    descender::Float32
    hadvance::Float32
end

function GlyphExtent(font, char)
    extent = get_extent(font, char)
    ink_bb = FreeTypeAbstraction.inkboundingbox(extent)
    ascender = FreeTypeAbstraction.ascender(font)
    descender = FreeTypeAbstraction.descender(font)
    hadvance = FreeTypeAbstraction.hadvance(extent)

    return GlyphExtent(ink_bb, ascender, descender, hadvance)
end

function GlyphExtent(texchar::TeXChar)
    l = MathTeXEngine.leftinkbound(texchar)
    r = MathTeXEngine.rightinkbound(texchar)
    b = MathTeXEngine.bottominkbound(texchar)
    t = MathTeXEngine.topinkbound(texchar)
    ascender = MathTeXEngine.ascender(texchar)
    descender = MathTeXEngine.descender(texchar)
    hadvance = MathTeXEngine.hadvance(texchar)

    return GlyphExtent(Rect2f((l, b), (r - l, t - b)), ascender, descender, hadvance)
end

"""
    GlyphCollection

Stores information about the glyphs in a string that had a layout calculated for them.
"""
struct GlyphCollection
    glyphs::Vector{UInt64}
    fonts::Vector{FTFont}
    origins::Vector{Point3f}
    extents::Vector{GlyphExtent}
    scales::ScalarOrVector{Vec2f}
    rotations::ScalarOrVector{Quaternionf}
    colors::ScalarOrVector{RGBAf}
    strokecolors::ScalarOrVector{RGBAf}
    strokewidths::ScalarOrVector{Float32}

    function GlyphCollection(glyphs, fonts, origins, extents, scales, rotations,
            colors, strokecolors, strokewidths)

        n = length(glyphs)
        @assert length(fonts) == n
        @assert length(origins) == n
        @assert length(extents) == n
        @assert attr_broadcast_length(scales) in (n, 1)
        @assert attr_broadcast_length(rotations) in (n, 1)
        @assert attr_broadcast_length(colors) in (n, 1)

        rotations = convert_attribute(rotations, key"rotation"())
        fonts = [convert_attribute(f, key"font"()) for f in fonts]
        colors = convert_attribute(colors, key"color"())
        strokecolors = convert_attribute(strokecolors, key"color"())
        strokewidths = Float32.(strokewidths)
        new(glyphs, fonts, origins, extents, scales, rotations, colors, strokecolors, strokewidths)
    end
end


# The color type we ideally use for most color attributes
const RGBColors = Union{RGBAf, Vector{RGBAf}, Vector{Float32}}
