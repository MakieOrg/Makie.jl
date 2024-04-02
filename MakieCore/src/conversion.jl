

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
conversion_trait(::Type{<: XYBased}) = PointBased()
conversion_trait(::Type{<: Text}) = PointBased()

"""
    GridBased <: ConversionTrait

GridBased is an abstract conversion trait for data that exists on a grid.

Child types: [`VertexGrid`](@ref), [`CellGrid`](@ref)
See also: [`ImageLike`](@ref)
Used for: Scatter, Lines
"""
abstract type GridBased <: ConversionTrait end

"""
    VertexGrid() <: GridBased <: ConversionTrait

Plots with the `VertexGrid` trait convert their input data to
`(xs::Vector{Float32}, ys::Vector{Float32}, zs::Matrix{Float32})` such that
`(length(xs), length(ys)) == size(zs)`, or
`(xs::Matrix{Float32}, ys::Matrix{Float32}, zs::Matrix{Float32})` such that
`size(xs) == size(ys) == size(zs)`.

See also: [`CellGrid`](@ref), [`ImageLike`](@ref)
Used for: Surface
"""
struct VertexGrid <: GridBased end
conversion_trait(::Type{<: Surface}) = VertexGrid()

"""
    CellGrid() <: GridBased <: ConversionTrait

Plots with the `CellGrid` trait convert their input data to
`(xs::Vector{Float32}, ys::Vector{Float32}, zs::Matrix{Float32})` such that
`(length(xs), length(ys)) == size(zs) .+ 1`. After the conversion the x and y
values represent the edges of cells corresponding to z values.

See also: [`VertexGrid`](@ref), [`ImageLike`](@ref)
Used for: Heatmap
"""
struct CellGrid <: GridBased end
conversion_trait(::Type{<: Heatmap}) = CellGrid()

"""
    ImageLike() <: ConversionTrait

Plots with the `ImageLike` trait convert their input data to
`(xs::Interval, ys::Interval, zs::Matrix{Float32})` where xs and ys mark the
limits of a quad containing zs.

See also: [`CellGrid`](@ref), [`VertexGrid`](@ref)
Used for: Image
"""
struct ImageLike <: ConversionTrait end
conversion_trait(::Type{<: Image}) = ImageLike()
# Rect2f(xmin, ymin, xmax, ymax)


struct VolumeLike <: ConversionTrait end
conversion_trait(::Type{<: Volume}) = VolumeLike()

function convert_arguments end

convert_arguments(::NoConversion, args...; kw...) = args

"""
    convert_arguments_typed(::Type{<: AbstractPlot}, args...)::NamedTuple

Converts the arguments to their correct type for the Plot type.
Throws appropriate errors if it can't convert.
Returns:

* `NoConversion()` if no conversion is defined for the plot type.
* `args` untouched, if no conversion is requested via the `NoConversion` trait.
* `NamedTuple` of the converted arguments, if a conversion is defined.
"""
function convert_arguments_typed end

function convert_arguments_typed(::P, @nospecialize(args...)) where {P<:ConversionTrait}
    return convert_arguments_typed(P, args...)
end
function convert_arguments_typed(P::Type{<:AbstractPlot}, @nospecialize(args...))
    return convert_arguments_typed(typeof(conversion_trait(P, args...)), args...)
end

function convert_arguments_typed(::Type{<:ConversionTrait}, @nospecialize(args...))
    # We currently just fall back to not doing anything if there isn't a convert_arguments_typed defined for certain plot types.
    # This makes `@convert_target` an optional feature right now.
    # It will require a bit more work to error here and request an overload for every plot type.
    # We will have to think more about how to integrate it with user recipes, because otherwise all user defined recipes would error by default without a convert target.
    # we return NoConversion to indicate, that no conversion is defined, while a conversion was requested, which is different from the below case where no conversion was requested.
    return NoConversion()
end

struct ConversionError
    type::Any
    name::String
    arg::Any
end

function Base.show(io::IO, ce::ConversionError)
    println(io, """
       Can't convert argument $(ce.name)::$(typeof(ce.arg)) to target type $(ce.type).
        Either define:

    """)
end

get_element_type(::T) where {T} = T
function get_element_type(arr::AbstractArray{T}) where {T}
    if T == Any
        return mapreduce(typeof, promote_type, arr)
    else
        return T
    end
end

should_dim_convert(::Type) = false
has_typed_convert(::Type) = false

"""
    MakieCore.should_dim_convert(::Type{<: Plot}, args)::Bool
    MakieCore.should_dim_convert(eltype::DataType)::Bool

Returns `true` if the plot type should convert its arguments via DimConversions.
Needs to be overloaded for recipes that want to use DimConversions. Also needs
to be overloaded for DimConversions, e.g. for CategoricalConversion:

```julia
    MakieCore.should_dim_convert(::Type{Categorical}) = true
```

`should_dim_convert(::Type{<: Plot}, args)` falls back on checking if
`has_typed_convert(plot_or_trait)` and `should_dim_convert(get_element_type(args))`
 are true. The former is defined as true by `@convert_target`, i.e. when
`convert_arguments_typed` is defined for the given plot type or conversion trait.
The latter marks specific types as convertable.

If a recipe wants to use dim conversions, it should overload this function:
```julia
    MakieCore.should_dim_convert(::Type{<:MyPlotType}, args) = should_dim_convert(get_element_type(args))
``
"""
function should_dim_convert(P::Type{<: Plot}, args)
    typed_convert = has_typed_convert(P) || has_typed_convert(typeof(conversion_trait(P)))
    ax_convert = should_dim_convert(get_element_type(args))
    return typed_convert && ax_convert
end


function makie_convert(::Type{T}, x) where T
    convert(T, x)
end

"""
    @convert_target struct ...
        ...
    end

Allows to define a conversion target for a plot type so that `convert_arguments`
can properly check if it converts to the correct types.

Usage:
```Julia
@convert_target struct PointBased{N} # Plot Type or Conversion Trait
    # one or multiple fields defining the target data structure (can be abstract)
    positions::AbstractVector{Point{N, Float32}}
end
```

Skipping error handling, this defines an overload of `convert_arguments_typed`
which produces a `NamedTuple` corresponding to the layout of the struct:
```Julia
function convert_arguments_typed(ct::Type{<: PointBased}, positions)
    converted_positions = makie_convert(AbstractVector{Point{N, Float32}} where N, positions)
    return (positions = converted_positions,)
end
```
This way we can throw a nice error if `convert_arguments` doesn't convert to
an `AbstractVector{Point{N, Float32}}`. Take a look at Makie/src/conversions.jl
to see the core conversion targets.
"""
macro convert_target(struct_expr)
    if !Meta.isexpr(struct_expr, :struct)
        error("Expression must be `struct Target; fields...; end`")
    else
        target_name = struct_expr.args[2]

        if Meta.isexpr(target_name, :curly)
            target_name, targs... = target_name.args
        else
            targs = ()
        end

        body = struct_expr.args[3]
        convert_expr = []
        converted = Symbol[]
        all_fields = filter(x -> !(x isa LineNumberNode), body.args)
        if any(x -> !Meta.isexpr(x, :(::)), all_fields)
            error("All fields need to be of type `name::Type`. Found: $(all_fields)")
        end
        names = map(x -> x.args[1], all_fields)
        types = map(x -> :($(x.args[2]) where {$(targs...)}), all_fields)
        for (name, TargetType) in zip(names, types)
            conv_name = Symbol("converted_$name")
            push!(converted, conv_name)
            # We always add the where clause, since it's too complicated to match the static type parameters to the types that use them.
            # This seems to work well, since Julia drops any unecessary where clause/ type parameter, while lowering.
            # TODO figure out a way to drop the where close... Eval is the only thing I found, but shouldn't be used here.

            expr = quote
                # Unions etc don't work well with `convert(T, x)`, so we try not to convert if already the right type!
                $conv_name = try
                    MakieCore.makie_convert($TargetType, $name)
                catch e
                    return MakieCore.ConversionError($(string(TargetType)), $(string(name)), $name)
                end
            end
            push!(convert_expr, expr)
        end

        expr = quote
            # Fallback for args missmatch, which should also return an error instead of NoConversion
            function MakieCore.convert_arguments_typed(TTT::Type{<:$(target_name)}, args...)
                return MakieCore.ConversionError($(target_name), "Args dont match", "Args don't match")
            end
            function MakieCore.convert_arguments_typed(TTT::Type{<:$(target_name)}, $(names...))
                $(convert_expr...)
                return NamedTuple{($(QuoteNode.(names)...),)}(($(converted...),))
            end
            MakieCore.has_typed_convert(::Type{<:$(target_name)}) = true
        end
        return esc(expr)
    end
    return
end
