

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

# Explicitely requested no conversion (default for recipes)
convert_arguments_typed(::NoConversion, args...) = args

"""
    @convert_target(expr)
Allows to define a conversion target for a plot type, so that `convert_arguments` can be checked properly, if it converts to the correct types.
Usage:
```Julia
@convert_target struct PointBased{N} # Can be the Plot type or a ConversionTrait
    positions::AbstractVector{Point{N, Float32}}
end
```
This defines an overload of `convert_arguments_typed` pretty much in this way (error handling etc omitted):
```Julia
function convert_arguments_typed(ct::Type{<: PointBased}, positions)
    converted_positions = convert(AbstractVector{Point{N, Float32}} where N, positions)
    return (positions = converted_positions,) # returns a NamedTuple corresponding to the layout of the struct
end
```
This way, we can throw nice errors, if `convert_arguments` doesn't convert to `AbstractVector{Point{N, Float32}}`.
Take a look at Makie/src/conversions.jl, to see a few of the core conversion targets.
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
                if $name isa $TargetType
                    $conv_name = $name
                else
                    $conv_name = try
                        convert($TargetType, $name)
                    catch e
                        arg_types = map(typeof, ($(names...),))
                        err = """
                        Can't convert argument $($(string(name)))::$(typeof($name)) to target type $($TargetType).
                        Either define:
                            convert_arguments(::Type{<: $($target_name)}, $(join(arg_types, ", "))) where {$($targs...)}) = ...
                        Or use a type that can get converted to $($TargetType).
                        """
                        error(err)
                    end
                end
            end
            push!(convert_expr, expr)
        end

        expr = quote
            function MakieCore.convert_arguments_typed(::Type{<:$(target_name)}, $(names...))
                $(convert_expr...)
                return NamedTuple{($(QuoteNode.(names)...),)}(($(converted...),))
            end
        end
        return esc(expr)
    end
    return
end
