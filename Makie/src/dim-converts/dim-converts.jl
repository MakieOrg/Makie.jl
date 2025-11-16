abstract type AbstractDimConversion end

struct NoDimConversion <: AbstractDimConversion end

struct DimConversions
    conversions::NTuple{3, Observable{Union{Nothing, AbstractDimConversion}}}
    function DimConversions()
        conversions = map((1, 2, 3)) do i
            Observable{Union{Nothing, AbstractDimConversion}}(nothing)
        end
        return new(conversions)
    end
end

dim_observable(conversions::DimConversions, dim::Int) = conversions.conversions[dim]

function Base.getindex(conversions::DimConversions, i::Int)
    return conversions.conversions[i][]
end

function Base.setindex!(conversions::DimConversions, value::Observable, i::Int)
    return on(value; update = true) do val
        conversions[i] = val
    end
end

function needs_dimconvert(conversions::DimConversions)
    for i in 1:3
        if !(conversions[i] isa Union{Nothing, NoDimConversion})
            return true
        end
    end
    return false
end

function Base.setindex!(conversions::DimConversions, value, i::Int)
    isnothing(value) && return # ignore no conversions
    conversions[i] === value && return # ignore same conversion
    if isnothing(conversions[i])
        # only set new conversion if there is none yet
        conversions.conversions[i][] = value
        return
    else
        throw(ArgumentError("Cannot change dim conversion for dimension $i, since it already is set to a conversion: $(conversions[i])."))
    end
end


## Interface to be overloaded for any AbstractDimConversion type
function convert_dim_value(conversions::DimConversions, dim::Int, value)
    if isnothing(conversions[dim])
        return value
    end
    return convert_dim_value(conversions[dim], value)
end


function convert_dim_value(axislike::AbstractAxis, dim::Int, value)
    return convert_dim_value(get_conversions(axislike), dim, value)
end

convert_dim_value(::NoDimConversion, value) = value
function convert_dim_value(conversion::AbstractDimConversion, value, deregister)
    error("AbstractDimConversion $(typeof(conversion)) not supported for value of type $(typeof(value))")
end

# Return instance of AbstractDimConversion for a given type
create_dim_conversion(argument_eltype::DataType) = NoDimConversion()
should_dim_convert(::Type{<:Real}) = false
function convert_dim_observable(::NoDimConversion, value::Observable, deregister)
    return value
end

# get_ticks needs overloading for Dim Conversion
# Which gets ignored for no conversion/nothing
function get_ticks(::Union{Nothing, NoDimConversion}, ticks, scale, formatter, vmin, vmax)
    return get_ticks(ticks, scale, formatter, vmin, vmax)
end

# Recursively gets the dim convert from the plot
# This needs to be recursive to allow recipes to use dim convert
# TODO, should a recipe always set the dim convert to it's parent?
get_conversions(any) = nothing

function get_conversions(ax::AbstractAxis)
    if hasproperty(ax, :scene)
        return get_conversions(ax.scene)
    else
        return nothing
    end
end

function get_conversions(plot::Plot)
    if haskey(plot.kw, :dim_conversions)
        return to_value(plot.kw[:dim_conversions])
    else
        for elem in plot.plots
            x = get_conversions(elem)
            isnothing(x) || return x
        end
    end
    return nothing
end

# For e.g. Axis attributes
function get_conversions(attr::Union{Attributes, Dict, NamedTuple})
    conversions = DimConversions()
    for i in 1:3
        dim_sym = Symbol("dim$(i)_conversion")
        if haskey(attr, dim_sym)
            conversions[i] = to_value(attr[dim_sym])
        end
    end
    return conversions
end

function dim_conversion_from_args(values)
    return create_dim_conversion(get_element_type(values))
end

function connect_conversions!(new_conversions::DimConversions, ax::AbstractAxis)
    for i in 1:3
        dim_sym = Symbol("dim$(i)_conversion")
        if hasproperty(ax, dim_sym)
            # merge
            ax_conversion = getproperty(ax, dim_sym)
            new_conversions[i] = ax_conversion
            # update in case new_conversions has a new conversion
            getproperty(ax, dim_sym)[] = new_conversions[i]
            deregister = nothing
            # if the conversion changes, update the axis as well.
            # This should only ever happen once, since conversions are mutable after setting it to a new value
            deregister = on(dim_observable(new_conversions, i)) do val
                getproperty(ax, dim_sym)[] = val
                off(deregister)
            end
        end
    end
    return
end

function connect_conversions!(conversions::DimConversions, new_conversions::DimConversions)
    for i in 1:3
        conversions[i] = new_conversions.conversions[i]
    end
    return
end

# If axis conversion has global state which needs an update of the tick values,
# This functions needs to be overloaded, returning an observable that updates
# When ticks need to be updated. The concrete value doesn't matterm, since the AbstractDimConversion type will get passed to get_ticks regardless
#=
    obs = needs_tick_update_observable(dim_convert) # make sure we update tick calculation when needed
    ticks = map(obs, ...) do _, args...
        return get_ticks(dim_convert, args...)
    end
=#
needs_tick_update_observable(x) = nothing

function needs_tick_update_observable(conversion::Observable)
    if isnothing(conversion[])
        # At any point, conversion may change from nothing to an actual AbstractDimConversion
        # so we need to listen for that change and then listen to the updates from that conversion.
        # This should only ever happen once, since you can only change a conversion once, IFF it was nothing.
        tick_update = Observable{Any}(nothing)
        deregister = nothing
        deregister = on(conversion) do conversion
            if !isnothing(conversion)
                obs = needs_tick_update_observable(conversion)
                if !isnothing(obs)
                    connect!(tick_update, obs)
                end
                # this one doesn't need to listen anymore, since this update can only happen once
                off(deregister)
            end
        end
        return tick_update
    else
        return needs_tick_update_observable(conversion[])
    end
end

convert_dim_value(conv, attr, value, last_value) = value

function update_dim_conversion!(conversions::DimConversions, dim, value)
    conversion = conversions[dim]
    if !(conversion isa Union{Nothing, NoDimConversion})
        return
    end
    c = dim_conversion_from_args(value)
    return conversions[dim] = c
end

function try_dim_convert(P::Type{<:Plot}, PTrait::ConversionTrait, user_attributes, args_obs::Tuple, deregister)
    # Only 2 and 3d conversions are supported, and only
    if !(length(args_obs) in (2, 3))
        return args_obs
    end
    converts = to_value(get!(() -> DimConversions(), user_attributes, :dim_conversions))
    return ntuple(length(args_obs)) do i
        arg = args_obs[i]
        argval = to_value(arg)
        # We only convert if we have a conversion struct (which isn't NoDimConversion),
        # or if we we should dim_convert
        if !isnothing(converts[i]) || should_dim_convert(P, argval) || should_dim_convert(PTrait, argval)
            return convert_dim_observable(converts, i, arg, deregister)
        end
        return arg
    end
end

function convert_dim_observable(conversions::DimConversions, dim::Int, value::Observable, deregister)
    conversion = conversions[dim]
    if !(conversion isa Union{Nothing, NoDimConversion})
        return convert_dim_observable(conversion, value, deregister)
    end
    c = dim_conversion_from_args(value[])
    conversions[dim] = c
    return convert_dim_observable(c, value, deregister)
end
