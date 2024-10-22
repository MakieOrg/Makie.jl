
const Attributes = Dict{Symbol, Any}
const Theme = Attributes

Base.broadcastable(x::AbstractScene) = Ref(x)
Base.broadcastable(x::AbstractPlot) = Ref(x)

function apply_changes!(plot::Plot)
    isempty(plot.changed) && return
    if plot_arg_names(plot) in plot.changed
        apply_convert_arguments!(plot)
    end
    for (attributes, f) in plot.requested_updates
        if attributes in plot.changed
            f(plot)
        end
    end
    empty!(plot.changed)
    return
end

Base.filter(f, x::Attributes) = Attributes(filter(f, attributes(x)))
function Base.empty!(x::Attributes)
    attr = attributes(x)
    for (key, obs) in attr
        Observables.clear(obs)
    end
    empty!(attr)
    return x
end

Base.length(x::Attributes) = length(attributes(x))

function Base.merge!(target::Attributes, args::Attributes...)
    for elem in args
        merge_attributes!(target, elem)
    end
    return target
end

Base.merge(target::Attributes, args::Attributes...) = merge!(deepcopy(target), args...)

function Base.getproperty(x::Union{Attributes, AbstractPlot}, key::Symbol)
    if hasfield(typeof(x), key)
        getfield(x, key)
    else
        getindex(x, key)
    end
end

function Base.setproperty!(x::Union{Attributes,AbstractPlot}, key::Symbol, value::NamedTuple)
    x[key] = Attributes(value)
end

function Base.setindex!(x::Attributes, value::NamedTuple, key::Symbol)
    return x[key] = Attributes(value)
end

function Base.setproperty!(x::Union{Attributes, AbstractPlot}, key::Symbol, value)
    if hasfield(typeof(x), key)
        setfield!(x, key, value)
    else
        setindex!(x, value, key)
    end
end

function Base.getindex(x::Attributes, key::Symbol)
    x = attributes(x)[key]
    # We unpack Attributes, even though, for consistency, we store them as Observables
    # this makes it easier to create nested attributes
    return x[] isa Attributes ? x[] : x
end

function Base.setindex!(x::Attributes, value, key::Symbol)
    if haskey(x, key)
        x.attributes[key][] = value
    else
        x.attributes[key] = node_any(value)
    end
end

function Base.setindex!(x::Attributes, value::Observable, key::Symbol)
    return x.attributes[key] = node_any(value)
end

_indent_attrs(s, n) = join(split(s, '\n'), "\n" * " "^n)

isvisible(x) = x.visible

Base.haskey(x::Plot, key) = key in propertynames(x)

Base.get(f::Function, x::AttributeOrPlot, key::Symbol) = haskey(x, key) ? x[key] : f()
Base.get(x::AttributeOrPlot, key::Symbol, default) = get(()-> default, x, key)


function Base.getindex(plot::Plot, idx::Integer)
    name = argument_name(plot, idx)
    return getindex(plot, name)
end

Base.getindex(plot::Plot, idx::UnitRange{<:Integer}) = getindex.(Ref(plot), idx)
Base.setindex!(plot::Plot, value, idx::Integer) = setindex!(plot, value, argument_name(plot, idx))
Base.length(plot::Plot) = length(plot.converted)

function Base.getindex(x::T, key::Symbol) where {T <: Plot}
    return x.computed[key]
end

function Base.getindex(x::AttributeOrPlot, key::Symbol, key2::Symbol, rest::Symbol...)
    dict = to_value(x[key])
    dict isa Attributes || error("Trying to access $(typeof(dict)) with multiple keys: $key, $key2, $(rest)")
    dict[key2, rest...]
end

function Base.setindex!(x::AttributeOrPlot, value, key::Symbol, key2::Symbol, rest::Symbol...)
    dict = to_value(x[key])
    dict isa Attributes || error("Trying to access $(typeof(dict)) with multiple keys: $key, $key2, $(rest)")
    dict[key2, rest...] = value
end

function Base.setindex!(x::AbstractPlot, value, key::Symbol)
    x.input[key] = value
end

function Base.setindex!(x::AbstractPlot, value::Observable, key::Symbol)
    x.input[key] = value
end

# a few shortcut functions to make attribute conversion easier
function get_attribute(dict, key, default=nothing)
    if haskey(dict, key)
        value = to_value(dict[key])
        value isa Automatic && return default
        plot_k = plotkey(dict)
        if isnothing(plot_k)
            return convert_attribute(value, Key{key}())
        else
            return convert_attribute(value, Key{key}(), Key{plot_k}())
        end
    else
        return default
    end
end

function merge_attributes!(input::Attributes, theme::Attributes)
    for (key, value) in attributes(theme)
        if !haskey(input, key)
            input[key] = value
        else
            current_value = input[key]
            tvalue = to_value(value)
            if tvalue isa Attributes && current_value isa Attributes
                # if nested attribute, we merge recursively
                merge_attributes!(current_value, tvalue)
            end
            # we're good! input already has a value, can ignore theme
        end
    end
    return input
end

function Base.propertynames(x::Union{Attributes, AbstractPlot})
    return (keys(x.attributes)...,)
end
