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

argument_docs(::PointBased) = """
## Arguments (`PointBased()`)
- `x`: A `Real`, `AbstractVector{<:Real}` or `ClosedInterval[<:Real]` corresponding to \
x positions. Intervals require another dimension to be given as an `AbstractVector`. \
Defaults to `eachindex(y)` if omitted.
- `y`: A `Real`, `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` corresponding to \
y positions. Intervals require another dimension to be given as an `AbstractVector`.
- `z`: A `Real`, `AbstractVector{<:Real}` or `AbstractMatrix{<:Real}` corresponding to \
z positions. Using a matrix will change `x` and `y` to be interpreted per matrix axis.
- `position`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` \
corresponding to `(x, y)` or `(x, y, z)` positions. Used instead of `x`, `y`, `z` arguments.
- `matrix`: A 2 or 3 by N matrix interpreted to contain N 2 or 3 dimensional positions. \
The matrix can also be transposed, i.e. N by 2 or 3.
- `geometry_primitive`: Coordinates of a `GeometryBasics.GeometryPrimitive` which can \
be decomposed into points. This includes for example `Rect`, `Sphere` and `GeometryBasics.Mesh`.
- `multi_point`: A `GeometryBasics.MultiPoint` or `AbstractVector` thereof, interpreted \
as a collection of positions.
- `line_string`: A `GeometryBasics.LineString`, `GeometryBasics.MultiLineString` or \
`AbstractVector{<:LineString}` interpreted as a collection of positions. The latter \
two will separate line strings by NaN points to disconnect them.
- `polygon`: A `GeometryBasics.Polygon`, `GeometryBasics.MultiPolygon` or \
`AbstractVector{<:Polygon}` disassembled into positions of the exterior and \
interior coordinates. Each polygon, interior and exterior is separated by a NaN \
point. Each exterior and interior is closed, meaning the first point is duplicated \
after the last.
- `bezierpath`: A `Makie.BezierPath` discretized into 2D positions.
"""

"""
    GridBased <: ConversionTrait

GridBased is an abstract conversion trait for data that exists on a grid.

Child types: [`VertexGrid`](@ref), [`CellGrid`](@ref)

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

"""
    ImageLike() <: ConversionTrait

Plots with the `ImageLike` trait convert their input data to
`(xs::Interval, ys::Interval, zs::Matrix{Float32})` where xs and ys mark the
limits of a quad containing zs.

Used for: Image \\
See also: [`CellGrid`](@ref), [`VertexGrid`](@ref)
"""
struct ImageLike <: ConversionTrait end
# Rect2f(xmin, ymin, xmax, ymax)


struct VolumeLike <: ConversionTrait end

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
