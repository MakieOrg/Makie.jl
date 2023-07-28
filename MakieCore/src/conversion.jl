
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

struct PointBased <: ConversionTrait end
conversion_trait(::Type{<: XYBased}) = PointBased()
conversion_trait(::Type{<: Text}) = PointBased()

abstract type GridBased <: ConversionTrait end

struct VertexBasedGrid <: GridBased end
conversion_trait(::Type{<: Surface}) = VertexBasedGrid()
# [Point3f(xs[i], ys[j], zs[i, j]) for i in axes(zs, 1), j in axes(zs, 2)]

struct CellBasedGrid <: GridBased end
conversion_trait(::Type{<: Heatmap}) = CellBasedGrid()
# [Rect2f(xs[i], ys[j], xs[i+1], ys[j+1]) for i in axes(zs, 1), j in axes(zs, 2)]

struct ImageLike end
conversion_trait(::Type{<: Image}) = ImageLike()
# Rect2f(xmin, ymin, xmax, ymax)

# Deprecations
function ContinuousSurface()
    error("ContinuousSurface has been deprecated. Use `ImageLike()` or `VertexBasedGrid()`")
end

@deprecate DiscreteSurface CellLike()

struct VolumeLike <: ConversionTrait end
conversion_trait(::Type{<: Volume}) = VolumeLike()