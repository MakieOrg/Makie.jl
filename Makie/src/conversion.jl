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

## Arguments

* `positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` corresponding to `(x, y)` or `(x, y, z)` positions.
* `xs, ys[, zs]`: Positions given per dimension. Can be `Real` to define a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to define multiple. Using `ClosedInterval` requires at least one dimension to be given as an array. `zs` can also be given as a `AbstractMatrix` which will cause `xs` and `ys` to be interpreted per matrix axis.
* `ys`: Defaults `xs` positions to `eachindex(ys)`.
"""
struct PointBased <: ConversionTrait end
conversion_trait(::Type{<:XYBased}) = PointBased()

"""
    PointBased2D() <: ConversionTrait

Similar to `PointBased`, but specifically for 2D plots. Converts input data to a
`Vector{Point{2, Float32}}`. Uses the same conversion methods as `PointBased`.

## Arguments

* `positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` corresponding to `(x, y)` positions.
* `xs, ys`: Positions given per dimension. Can be `Real` to define a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to define multiple. Using `ClosedInterval` requires at least one dimension to be given as an array. If omitted, `xs` defaults to `eachindex(ys)`.
"""
struct PointBased2D <: ConversionTrait end

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

## Arguments

* `zs`: Defines z values for vertices of a grid using an `AbstractMatrix{<:Real}`.
* `xs, ys`: Defines the (x, y) positions of grid vertices. A `ClosedInterval{<:Real}` or `Tuple{<:Real, <:Real}` is interpreted as the outer limits of the grid, between which vertices are spaced regularly. An `AbstractVector{<:Real}` defines vertex positions directly for the respective dimension. An `AbstractMatrix{<:Real}` allows grid positions to be defined per vertex, i.e. in a non-repeating fashion. If `xs` and `ys` are omitted they default to `axes(data, dim)`.
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

## Arguments

* `data`: Defines data values for cells of a grid using an `AbstractMatrix{<:Real}`.
* `xs, ys`: Defines the positions of grid cells. A `ClosedInterval{<:Real}` or `Tuple{<:Real, <:Real}` is interpreted as the outer edges of the grid, between which cells are spaced regularly. An `AbstractVector{<:Real}` defines cell positions directly for the respective dimension. This define either `size(data, dim)` cell centers or `size(data, dim) + 1` cell edges. These are allowed to be spaced irregularly. If `xs` and `ys` are omitted they default to `axes(data, dim)`.
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

## Arguments

* `image`: An `AbstractMatrix{<:Colorant}` defining the colors of an image, or an `AbstractMatrix{<:Real}` defining colors through colormapping.
* `x, y`: Defines the boundary of the image rectangle. Can be a `Tuple{<:Real, <:Real}` or `ClosedInterval{<:Real}`. Defaults to `0 .. size(image, 1)` and `0 .. size(image, 2)` respectively.
"""
struct ImageLike <: ConversionTrait end
conversion_trait(::Type{<:Image}) = ImageLike()
# Rect2f(xmin, ymin, xmax, ymax)


"""
    VolumeLike() <: ConversionTrait

Plots with the `VolumeLike` trait convert their input data for volume rendering.

## Arguments

* `volume_data`: An `AbstractArray{<:Real, 3}` defining volume data.
* `x, y, z`: Defines the boundary of a 3D rectangle with a `Tuple{<:Real, <:Real}` or `ClosedInterval{<:Real}`. If omitted `x`, `y` and `z` default to `0 .. size(volume)`.
"""
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

function types_for_plot_arguments(::PointBased2D)
    return Tuple{AbstractVector{<:Point2}}
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
