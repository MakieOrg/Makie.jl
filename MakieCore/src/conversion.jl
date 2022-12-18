
function convert_arguments end

"""
    convert_attribute(value, attribute::Key[, plottype::Key])

Convert `value` into into a suitable domain for use as `attribute`.

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
convert_arguments(::NoConversion, args...) = args

struct PointBased <: ConversionTrait end
conversion_trait(::Type{<: XYBased}) = PointBased()
conversion_trait(::Type{<: Text}) = PointBased()

abstract type SurfaceLike <: ConversionTrait end

struct ContinuousSurface <: SurfaceLike end
conversion_trait(::Type{<: Union{Surface, Image}}) = ContinuousSurface()

struct DiscreteSurface <: SurfaceLike end
conversion_trait(::Type{<: Heatmap}) = DiscreteSurface()

struct VolumeLike <: ConversionTrait end
conversion_trait(::Type{<: Volume}) = VolumeLike()
