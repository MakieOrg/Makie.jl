"""
    convert_attribute(value, attribute::Key[, plottype::Key])

Convert `value` into a suitable domain for use as `attribute`.

# Example
```jldoctest
julia> using Makie

julia> Makie.convert_attribute(:black, key"color"())
RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0)
```
"""
function convert_attribute end
function used_attributes end

################################################################################
#                              Conversion Traits                               #
################################################################################

abstract type ConversionTrait end

const XYBased = Union{MeshScatter, Scatter, Lines, LineSegments}

struct NoConversion <: ConversionTrait end

# No conversion by default
conversion_trait(::Type) = NoConversion()
conversion_trait(T::Type, args...) = conversion_trait(T)

"""
    PointBased() <: ConversionTrait

Plots with the `PointBased` trait convert their input data to a
`Vector{Point{D, Float32}}`.
"""
struct PointBased <: ConversionTrait end
conversion_trait(::Type{<:XYBased}) = PointBased()

"""
    GridBased <: ConversionTrait

GridBased is an abstract conversion trait for data that exists on a grid.

Child types: [`VertexGrid`](@ref), [`CellGrid`](@ref)

Used for: Scatter, Lines \\
See also: [`ImageLike`](@ref)
"""
abstract type GridBased <: ConversionTrait end

"""
    VertexGrid() <: GridBased <: ConversionTrait

Plots with the `VertexGrid` trait convert their input data to
`(xs::Vector{Float32}, ys::Vector{Float32}, zs::Matrix{Float32})` such that
`(length(xs), length(ys)) == size(zs)`, or
`(xs::Matrix{Float32}, ys::Matrix{Float32}, zs::Matrix{Float32})` such that
`size(xs) == size(ys) == size(zs)`.

Used for: Surface \\
See also: [`CellGrid`](@ref), [`ImageLike`](@ref)
"""
struct VertexGrid <: GridBased end
conversion_trait(::Type{<:Surface}) = VertexGrid()

"""
    CellGrid() <: GridBased <: ConversionTrait

Plots with the `CellGrid` trait convert their input data to
`(xs::Vector{Float32}, ys::Vector{Float32}, zs::Matrix{Float32})` such that
`(length(xs), length(ys)) == size(zs) .+ 1`. After the conversion the x and y
values represent the edges of cells corresponding to z values.

Used for: Heatmap \\
See also: [`VertexGrid`](@ref), [`ImageLike`](@ref)
"""
struct CellGrid <: GridBased end
conversion_trait(::Type{<:Heatmap}) = CellGrid()

"""
    ImageLike() <: ConversionTrait

Plots with the `ImageLike` trait convert their input data to
`(xs::Interval, ys::Interval, zs::Matrix{Float32})` where xs and ys mark the
limits of a quad containing zs.

Used for: Image \\
See also: [`CellGrid`](@ref), [`VertexGrid`](@ref)
"""
struct ImageLike <: ConversionTrait end
conversion_trait(::Type{<:Image}) = ImageLike()
# Rect2f(xmin, ymin, xmax, ymax)


struct VolumeLike <: ConversionTrait end
conversion_trait(::Type{<:Volume}) = VolumeLike()

function convert_arguments end

convert_arguments(::NoConversion, args...; kw...) = args

get_element_type(::T) where {T} = T
function get_element_type(arr::AbstractArray{T}) where {T}
    if T == Any
        return mapreduce(typeof, promote_type, arr)
    else
        return T
    end
end

types_for_plot_arguments(trait) = nothing
function types_for_plot_arguments(P::Type{<:Plot}, Trait::ConversionTrait)
    p = types_for_plot_arguments(P)
    isnothing(p) || return p
    return types_for_plot_arguments(Trait)
end

function types_for_plot_arguments(::PointBased)
    return Tuple{AbstractVector{<:Union{Point2, Point3}}}
end

should_dim_convert(::Type) = false

"""
    should_dim_convert(::Type{<: Plot}, args)::Bool
    should_dim_convert(eltype::DataType)::Bool

Returns `true` if the plot type should convert its arguments via DimConversions.
Needs to be overloaded for recipes that want to use DimConversions. Also needs
to be overloaded for DimConversions, e.g. for CategoricalConversion:

```julia
    should_dim_convert(::Type{Categorical}) = true
```

`should_dim_convert(::Type{<: Plot}, args)` falls back on checking if
`has_typed_convert(plot_or_trait)` and `should_dim_convert(get_element_type(args))`
 are true. The former is defined as true by `@convert_target`, i.e. when
`convert_arguments_typed` is defined for the given plot type or conversion trait.
The latter marks specific types as convertible.

If a recipe wants to use dim conversions, it should overload this function:
```julia
    should_dim_convert(::Type{<:MyPlotType}, args) = should_dim_convert(get_element_type(args))
``
"""
function should_dim_convert(P, arg)
    isnothing(types_for_plot_arguments(P)) && return false
    return should_dim_convert(get_element_type(arg))
end

################################################################################
#                           Material Conversion                                #
################################################################################

"""
    convert_material(material) -> HikariBase.Material

Convert a user-defined material type into a `HikariBase.Material` for rendering.

Backends use `HikariBase.Material` as the canonical material representation:
- TraceMakie/RayMakie: uses Hikari materials directly for path tracing
- GLMakie/WGLMakie: converts Hikari materials to shader uniforms internally

Users can extend this function for their own material types:

```julia
function Makie.convert_material(m::MySurfaceMaterial)
    HikariBase.MatteMaterial(Kd=HikariBase.RGBSpectrum(m.albedo...))
end
```
"""
function convert_material end

# Identity: HikariBase materials pass through unchanged
convert_material(m::HikariBase.Material) = m

# Vectors of materials
convert_material(v::AbstractVector) = convert_material.(v)

# Dict palette (UInt32 keys)
function convert_material(d::AbstractDict{<:Integer})
    Dict{UInt32, HikariBase.Material}(UInt32(k) => convert_material(v) for (k, v) in d)
end

# Fallback with helpful error
function convert_material(m)
    error("No `Makie.convert_material` method defined for $(typeof(m)). " *
          "Define `Makie.convert_material(::$(typeof(m)))` to return a `HikariBase.Material`.")
end

"""
    material_to_color(material::HikariBase.Material) -> RGBAf

Extract a representative RGBA color from a HikariBase material for rasterization backends.
"""
function material_to_color end

function _extract_color(tex::HikariBase.Texture)
    if tex.isconst
        v = tex.constval
        if v isa HikariBase.RGBSpectrum
            c = v.c
            return RGBAf(c[1], c[2], c[3], c[4])
        elseif v isa Real
            return RGBAf(v, v, v, 1f0)
        end
    end
    return RGBAf(0.8, 0.8, 0.8, 1)
end

material_to_color(m::HikariBase.MatteMaterial) = _extract_color(m.Kd)
material_to_color(m::HikariBase.MirrorMaterial) = _extract_color(m.Kr)
material_to_color(m::HikariBase.GlassMaterial) = _extract_color(m.Kt)
material_to_color(m::HikariBase.ConductorMaterial) = _extract_color(m.reflectance)
material_to_color(m::HikariBase.CoatedDiffuseMaterial) = _extract_color(m.reflectance)
material_to_color(m::HikariBase.CoatedConductorMaterial) = _extract_color(m.reflectance)
material_to_color(m::HikariBase.ThinDielectricMaterial) = RGBAf(0.95, 0.95, 0.95, 0.3)
material_to_color(m::HikariBase.DiffuseTransmissionMaterial) = _extract_color(m.reflectance)
material_to_color(m::HikariBase.CoatedDiffuseTransmissionMaterial) = _extract_color(m.reflectance)
material_to_color(m::HikariBase.Emissive) = _extract_color(m.Le)
function material_to_color(m::HikariBase.MediumInterface)
    if !isnothing(m.emission)
        # Blend emission with base color
        base = material_to_color(m.material)
        emit = material_to_color(m.emission)
        return RGBAf(
            min(1f0, base.r + emit.r * 0.5f0),
            min(1f0, base.g + emit.g * 0.5f0),
            min(1f0, base.b + emit.b * 0.5f0),
            base.alpha
        )
    end
    return material_to_color(m.material)
end
material_to_color(::HikariBase.Material) = RGBAf(0.8, 0.8, 0.8, 1)
