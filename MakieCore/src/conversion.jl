
function convert_arguments end
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

abstract type SurfaceLike <: ConversionTrait end

struct ContinuousSurface <: SurfaceLike end
conversion_trait(::Type{<: Union{Surface, Image}}) = ContinuousSurface()

struct DiscreteSurface <: SurfaceLike end
conversion_trait(::Type{<: Heatmap}) = DiscreteSurface()

struct VolumeLike <: ConversionTrait end
conversion_trait(::Type{<: Volume}) = VolumeLike()
conversion_trait(::T) where T <: AbstractPlot = conversion_trait(T)


"""
    convert_arguments_typed(::Type{<: AbstractPlot}, args...)::NamedTuple

Converts the arguments to their correct type for the Plot type.
Throws appropriate errors if it can't convert.
"""
function convert_arguments_typed end


function convert_arguments_typed(P::AbstractPlot, @nospecialize(args...))
    convert_arguments_typed(conversion_trait(P), args...)
end

function convert_arguments_typed(ct::ConversionTrait, @nospecialize(args...))
    # We currently just fall back to not doing anything if there isn't a convert_arguments_typed defined for certain plot types.
    # This makes `@convert_target` an optional feature right now.
    # It will require a bit more work to error here and request an overload for every plot type.
    # We will have to think more about how to integrate it with user recipes, because otherwise all user defined recipes would error by default without a convert target.
    return args
end

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
        all_fields = filter(x-> !(x isa LineNumberNode), body.args)
        if any(x-> !Meta.isexpr(x, :(::)), all_fields)
            error("All fields need to be of type `name::Type`. Found: $(all_fields)")
        end
        names = map(x-> x.args[1], all_fields)
        types = map(x-> :($(x.args[2]) where {$(targs...)}), all_fields)
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
            function MakieCore.convert_arguments_typed(::$(target_name), $(names...))
                $(convert_expr...)
                return NamedTuple{($(QuoteNode.(names)...),)}(($(converted...),))
            end
        end
        return esc(expr)
    end
    return
end
