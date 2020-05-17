"""
    abstract type Transformable
This is a bit of a weird name, but all scenes and plots are transformable,
so that's what they all have in common. This might be better expressed as traits.
"""
abstract type Transformable end

abstract type AbstractPlot{Typ} <: Transformable end
abstract type AbstractScene <: Transformable end
abstract type ScenePlot{Typ} <: AbstractPlot{Typ} end
abstract type AbstractScreen <: AbstractDisplay end

const SceneLike = Union{AbstractScene, ScenePlot}

"""
Main structure for holding attributes, for theming plots etc!
Will turn all values into nodes, so that they can be updated.
"""
struct Attributes
    attributes::Dict{Symbol, Node}
end
const Theme = Attributes

Base.broadcastable(x::AbstractScene) = Ref(x)
Base.broadcastable(x::AbstractPlot) = Ref(x)
Base.broadcastable(x::Attributes) = Ref(x)

# The rules that we use to convert values to a Node in Attributes
value_convert(x::Observables.AbstractObservable) = Observables.observe(x)
value_convert(@nospecialize(x)) = x

# We transform a tuple of observables into a Observable(tuple(values...))
function value_convert(x::NTuple{N, Union{Any, Observables.AbstractObservable}}) where N
    result = Observable(to_value.(x))
    onany((args...)-> args, x...)
    return result
end

value_convert(x::NamedTuple) = Attributes(x)

node_pairs(pair::Union{Pair, Tuple{Any, Any}}) = (pair[1] => convert(Node{Any}, value_convert(pair[2])))
node_pairs(pairs) = (node_pairs(pair) for pair in pairs)


Attributes(; kw_args...) = Attributes(Dict{Symbol, Node}(node_pairs(kw_args)))
Attributes(pairs::Pair...) = Attributes(Dict{Symbol, Node}(node_pairs(pairs)))
Attributes(pairs::AbstractVector) = Attributes(Dict{Symbol, Node}(node_pairs.(pairs)))
Attributes(pairs::Iterators.Pairs) = Attributes(collect(pairs))
Attributes(nt::NamedTuple) = Attributes(; nt...)
attributes(x::Attributes) = getfield(x, :attributes)
Base.keys(x::Attributes) = keys(x.attributes)
Base.values(x::Attributes) = values(x.attributes)
function Base.iterate(x::Attributes, state...)
    s = iterate(keys(x), state...)
    s === nothing && return nothing
    return (s[1] => x[s[1]], s[2])
end

function Base.copy(attributes::Attributes)
    result = Attributes()
    for (k, v) in attributes
        # We need to create a new Signal to have a real copy
        result[k] = copy(v)
    end
    return result
end
Base.filter(f, x::Attributes) = Attributes(filter(f, attributes(x)))
Base.empty!(x::Attributes) = (empty!(attributes(x)); x)
Base.length(x::Attributes) = length(attributes(x))

function Base.merge!(target::Attributes, args::Attributes...)
    for elem in args
        merge_attributes!(target, elem)
    end
    return target
end

Base.merge(target::Attributes, args::Attributes...) = merge!(copy(target), args...)

@generated hasfield(x::T, ::Val{key}) where {T, key} = :($(key in fieldnames(T)))

@inline function Base.getproperty(x::T, key::Symbol) where T <: Union{Attributes, Transformable}
    if hasfield(x, Val(key))
        getfield(x, key)
    else
        getindex(x, key)
    end
end

@inline function Base.setproperty!(x::T, key::Symbol, value) where T <: Union{Attributes, Transformable}
    if hasfield(x, Val(key))
        setfield!(x, key, value)
    else
        setindex!(x, value, key)
    end
end

function getindex(x::Attributes, key::Symbol)
    x = attributes(x)[key]
    # We unpack Attributes, even though, for consistency, we store them as nodes
    # this makes it easier to create nested attributes
    return x[] isa Attributes ? x[] : x
end

function setindex!(x::Attributes, value, key::Symbol)
    if haskey(x, key)
        x.attributes[key][] = value
    else
        x.attributes[key] = convert(Node{Any}, value)
    end
end

function setindex!(x::Attributes, value::Node, key::Symbol)
    if haskey(x, key)
        # error("You're trying to update an attribute node with a new node. This is not supported right now.
        # You can do this manually like this:
        # lift(val-> attributes[$key] = val, node::$(typeof(value)))
        # ")
        return x.attributes[key] = convert(Node{Any}, value)
    else
        #TODO make this error. Attributes should be sort of immutable
        return x.attributes[key] = convert(Node{Any}, value)
    end
    return x
end

function Base.show(io::IO,::MIME"text/plain", attr::Attributes)
    d = Dict()
    for p in pairs(attr.attributes)
        d[p.first] = to_value(p.second)
    end
    show(IOContext(io, :limit => false), MIME"text/plain"(), d)

end

Base.show(io::IO, attr::Attributes) = show(io, MIME"text/plain"(), attr)


theme(x::AbstractPlot) = x.attributes
isvisible(x) = haskey(x, :visible) && to_value(x[:visible])

#dict interface
const AttributeOrPlot = Union{AbstractPlot, Attributes}
Base.pop!(x::AttributeOrPlot, args...) = pop!(x.attributes, args...)
haskey(x::AttributeOrPlot, key) = haskey(x.attributes, key)
delete!(x::AttributeOrPlot, key) = delete!(x.attributes, key)
function get!(f::Function, x::AttributeOrPlot, key::Symbol)
    if haskey(x, key)
        return x[key]
    else
        val = f()
        x[key] = val
        return x[key]
    end
end
get!(x::AttributeOrPlot, key::Symbol, default) = get!(()-> default, x, key)
get(f::Function, x::AttributeOrPlot, key::Symbol) = haskey(x, key) ? x[key] : f()
get(x::AttributeOrPlot, key::Symbol, default) = get(()-> default, x, key)

# This is a bit confusing, since for a plot it returns the attribute from the arguments
# and not a plot for integer indexing. But, we want to treat plots as "atomic"
# so from an interface point of view, one should assume that a plot doesn't contain subplots
# Combined plots break this assumption in some way, but the way to look at it is,
# that the plots contained in a Combined plot are not subplots, but _are_ actually
# the plot itself.
getindex(plot::AbstractPlot, idx::Integer) = plot.converted[idx]
getindex(plot::AbstractPlot, idx::UnitRange{<:Integer}) = plot.converted[idx]
setindex!(plot::AbstractPlot, value, idx::Integer) = (plot.input_args[idx][] = value)
Base.length(plot::AbstractPlot) = length(plot.converted)

function getindex(x::AbstractPlot, key::Symbol)
    argnames = argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx == nothing
        return x.attributes[key]
    else
        x.converted[idx]
    end
end

function getindex(x::AttributeOrPlot, key::Symbol, key2::Symbol, rest::Symbol...)
    dict = to_value(x[key])
    dict isa Attributes || error("Trying to access $(typeof(dict)) with multiple keys: $key, $key2, $(rest)")
    dict[key2, rest...]
end

function setindex!(x::AttributeOrPlot, value, key::Symbol, key2::Symbol, rest::Symbol...)
    dict = to_value(x[key])
    dict isa Attributes || error("Trying to access $(typeof(dict)) with multiple keys: $key, $key2, $(rest)")
    dict[key2, rest...] = value
end

function setindex!(x::AbstractPlot, value, key::Symbol)
    argnames = argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx == nothing && haskey(x.attributes, key)
        return x.attributes[key][] = value
    elseif !haskey(x.attributes, key)
        x.attributes[key] = convert(Node, value)
    else
        return setindex!(x.converted[idx], value)
    end
end

function setindex!(x::AbstractPlot, value::Node, key::Symbol)
    argnames = argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx == nothing
        if haskey(x, key)
            # error("You're trying to update an attribute node with a new node. This is not supported right now.
            # You can do this manually like this:
            # lift(val-> attributes[$key] = val, node::$(typeof(value)))
            # ")
            return x.attributes[key] = value
        else
            return x.attributes[key] = value
        end
    else
        return setindex!(x.converted[idx], value)
    end
end

# a few shortcut functions to make attribute conversion easier
function get_attribute(dict, key)
    convert_attribute(to_value(dict[key]), Key{key}())
end

function merge_attributes!(input::Attributes, theme::Attributes)
    for (key, value) in theme
        if !haskey(input, key)
            input[key] = copy(value)
        else
            current_value = input[key]
            if value isa Attributes && current_value isa Attributes
                # if nested attribute, we merge recursively
                merge_attributes!(current_value, value)
            elseif value isa Attributes || current_value isa Attributes
                error("""
                Type missmatch while merging plot attributes with theme for key: $(key).
                Found $(value) in theme, while attributes contains: $(current_value)
                """)
            else
                # we're good! input already has a value, can ignore theme
            end
        end
    end
    return input
end
