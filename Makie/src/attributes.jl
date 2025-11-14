const Theme = Attributes

Base.broadcastable(x::AbstractScene) = Ref(x)
Base.broadcastable(x::AbstractPlot) = Ref(x)
Base.broadcastable(x::Attributes) = Ref(x)

# The rules that we use to convert values to a Observable in Attributes
value_convert(x::Observables.AbstractObservable) = Observables.observe(x)
value_convert(@nospecialize(x)) = x

# We transform a tuple of observables into a Observable(tuple(values...))
function value_convert(x::NTuple{N, Union{Any, Observables.AbstractObservable}}) where {N}
    result = Observable(to_value.(x))
    onany((args...) -> args, x...)
    return result
end

value_convert(x::NamedTuple) = Attributes(x)

# Version of `convert(Observable{Any}, obj)` that doesn't require runtime dispatch
node_any(obj::Computed) = obj
function node_any(@nospecialize(obj))
    isa(obj, Observable{Any}) && return obj
    isa(obj, Observable) && return convert(Observable{Any}, obj)
    return Observable{Any}(obj)
end

node_pairs(pair::Union{Pair, Tuple{Any, Any}}) = (pair[1] => node_any(value_convert(pair[2])))
node_pairs(pairs) = (node_pairs(pair) for pair in pairs)

Attributes(; kw_args...) = Attributes(Dict{Symbol, Any}(node_pairs(kw_args)))
Attributes(pairs::Dict) = Attributes(Dict{Symbol, Any}(node_pairs(pairs)))
Attributes(pairs::Pair...) = Attributes(Dict{Symbol, Any}(node_pairs(pairs)))
Attributes(pairs::AbstractVector) = Attributes(Dict{Symbol, Any}(node_pairs.(pairs)))
Attributes(pairs::Iterators.Pairs) = Attributes(collect(pairs))
Attributes(nt::NamedTuple) = Attributes(; nt...)
attributes(x::Attributes) = getfield(x, :attributes)
attributes(x::AbstractPlot) = getfield(x, :attributes)
Base.keys(x::Attributes) = keys(x.attributes)
Base.values(x::Attributes) = values(x.attributes)
function Base.iterate(x::Attributes, state...)
    s = iterate(keys(x), state...)
    s === nothing && return nothing
    return (s[1] => x[s[1]], s[2])
end

function Base.copy(attr::Attributes)
    return Attributes(copy(attributes(attr)))
end

function Base.deepcopy(obs::Observable)
    return Observable{Any}(to_value(obs))
end

function Base.deepcopy(attributes::Attributes)
    result = Attributes()
    for (k, v) in attributes
        # We need to create a new Signal to have a real copy
        result[k] = deepcopy(v)
    end
    return result
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
    return if hasfield(typeof(x), key)
        getfield(x, key)
    else
        getindex(x, key)
    end
end

function Base.setproperty!(x::Union{Attributes, AbstractPlot}, key::Symbol, value::NamedTuple)
    return x[key] = Attributes(value)
end
function Base.setindex!(x::Attributes, value::NamedTuple, key::Symbol)
    return x[key] = Attributes(value)
end

function Base.setproperty!(x::Union{Attributes, AbstractPlot}, key::Symbol, value)
    return if hasfield(typeof(x), key)
        setfield!(x, key, value)
    else
        setindex!(x, value, key)
    end
end

function Base.getindex(x::Attributes, key::Symbol)
    x = attributes(x)[key]
    # We unpack Attributes, even though, for consistency, we store them as Observables
    # this makes it easier to create nested attributes
    return to_value(x) isa Attributes ? to_value(x) : x
end

function Base.setindex!(x::Attributes, value, key::Symbol)
    return if haskey(x, key)
        x.attributes[key][] = value
    else
        x.attributes[key] = node_any(value)
    end
end

function Base.setindex!(x::Attributes, value::Observable, key::Symbol)
    return x.attributes[key] = node_any(value)
end

_indent_attrs(s, n) = join(split(s, '\n'), "\n" * " "^n)

function Base.show(io::IO, ::MIME"text/plain", attr::Attributes)

    io = IOContext(io, :compact => true)

    d = Dict()
    print(io, """Attributes with $(length(attr)) $(length(attr) != 1 ? "entries" : "entry")""")

    if length(attr) < 1
        return
    end

    print(io, ":")

    ks = sort(collect(keys(attr)), by = lowercase ∘ String)
    maxlength = maximum(length ∘ String, ks)

    for k in ks
        print(io, "\n  ")
        print(io, k)
        print(io, " => ")
        v = to_value(attr[k])
        if v isa Attributes
            print(io, _indent_attrs(repr(v), 2))
        else
            print(io, to_value(attr[k]))
        end
    end
    return
end

Base.show(io::IO, attr::Attributes) = print(io, "Attributes()")
theme(x::AbstractPlot) = x.attributes
isvisible(x) = haskey(x, :visible) && to_value(x[:visible])

#dict interface
const AttributeOrPlot = Union{AbstractPlot, Attributes}
Base.pop!(x::AttributeOrPlot, args...) = pop!(x.attributes, args...)
Base.haskey(x::AttributeOrPlot, key) = haskey(x.attributes, key)
Base.delete!(x::AttributeOrPlot, key) = delete!(x.attributes, key)
function Base.get!(f::Function, x::AttributeOrPlot, key::Symbol)
    if haskey(x, key)
        return x[key]
    else
        val = f()
        x[key] = val
        return x[key]
    end
end
Base.get!(x::AttributeOrPlot, key::Symbol, default) = get!(() -> default, x, key)
Base.get(f::Function, x::AttributeOrPlot, key::Symbol) = haskey(x, key) ? x[key] : f()
Base.get(x::AttributeOrPlot, key::Symbol, default) = get(() -> default, x, key)

# This is a bit confusing, since for a plot it returns the attribute from the arguments
# and not a plot for integer indexing. But, we want to treat plots as "atomic"
# so from an interface point of view, one should assume that a plot doesn't contain subplots
# Plot plots break this assumption in some way, but the way to look at it is,
# that the plots contained in a Plot plot are not subplots, but _are_ actually
# the plot itself.
function Base.getindex(plot::Plot, idx::Integer)
    name = argument_names(plot)[idx]
    return plot.attributes[name]
end

function Base.getindex(plot::Plot, idx::UnitRange{<:Integer})
    names = argument_names(plot)[idx]
    return getindex.((plot.attributes,), names)
end
Base.setindex!(plot::Plot, value, idx::Integer) = (plot.args[idx][] = value)
Base.length(plot::Plot) = length(plot.converted)


function Base.getindex(x::AttributeOrPlot, key::Symbol, key2::Symbol, rest::Symbol...)
    dict = to_value(x[key])
    dict isa Attributes || error("Trying to access $(typeof(dict)) with multiple keys: $key, $key2, $(rest)")
    return dict[key2, rest...]
end

function Base.setindex!(x::AttributeOrPlot, value, key::Symbol, key2::Symbol, rest::Symbol...)
    dict = to_value(x[key])
    dict isa Attributes || error("Trying to access $(typeof(dict)) with multiple keys: $key, $key2, $(rest)")
    return dict[key2, rest...] = value
end

# a few shortcut functions to make attribute conversion easier
function get_attribute(dict, key, default = nothing)
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

function Base.propertynames(x::Attributes)
    return (keys(x.attributes)...,)
end

function Base.propertynames(x::AbstractPlot)
    return (keys(x.attributes.outputs)...,)
end
