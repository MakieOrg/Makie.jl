
function convert_arguments end

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

convert_arguments(::NoConversion, args...) = args

"""
    PointBased() <: ConversionTrait

Plots with the `PointBased` trait convert their input data to a
`Vector{Point{D, Float32}}`.
"""
struct PointBased <: ConversionTrait end
conversion_trait(::Type{<: XYBased}) = PointBased()
conversion_trait(::Type{<: Text}) = PointBased()

"""
    GridBased <: ConversionTrait

GridBased is an abstract conversion trait for data that exists on a grid.

Child types: [`VertexBasedGrid`](@ref), [`CellBasedGrid`](@ref)
See also: [`ImageLike`](@ref)
Used for: Scatter, Lines
"""
abstract type GridBased <: ConversionTrait end

"""
    VertexBasedGrid() <: GridBased <: ConversionTrait

Plots with the `VertexBasedGrid` trait convert their input data to
`(xs::Vector{Float32}, ys::Vector{Float32}, zs::Matrix{Float32})` such that
`(length(xs), length(ys)) == size(zs)`, or
`(xs::Matrix{Float32}, ys::Matrix{Float32}, zs::Matrix{Float32})` such that
`size(xs) == size(ys) == size(zs)`.

See also: [`CellBasedGrid`](@ref), [`ImageLike`](@ref)
Used for: Surface
"""
struct VertexBasedGrid <: GridBased end
conversion_trait(::Type{<: Surface}) = VertexBasedGrid()

"""
    CellBasedGrid() <: GridBased <: ConversionTrait

Plots with the `CellBasedGrid` trait convert their input data to
`(xs::Vector{Float32}, ys::Vector{Float32}, zs::Matrix{Float32})` such that
`(length(xs), length(ys)) == size(zs) .+ 1`. After the conversion the x and y
values represent the edges of cells corresponding to z values.

See also: [`VertexBasedGrid`](@ref), [`ImageLike`](@ref)
Used for: Heatmap
"""
struct CellBasedGrid <: GridBased end
conversion_trait(::Type{<: Heatmap}) = CellBasedGrid()

"""
    ImageLike() <: ConversionTrait

Plots with the `ImageLike` trait convert their input data to
`(xs::Interval, ys::Interval, zs::Matrix{Float32})` where xs and ys mark the
limits of a quad containing zs.

See also: [`CellBasedGrid`](@ref), [`VertexBasedGrid`](@ref)
Used for: Image
"""
struct ImageLike <: ConversionTrait end
conversion_trait(::Type{<: Image}) = ImageLike()
# Rect2f(xmin, ymin, xmax, ymax)

# Deprecations
function ContinuousSurface()
    error("ContinuousSurface has been deprecated. Use `ImageLike()` or `VertexBasedGrid()` instead.")
end
@deprecate DiscreteSurface CellBasedGrid()

struct VolumeLike <: ConversionTrait end
conversion_trait(::Type{<: Volume}) = VolumeLike()