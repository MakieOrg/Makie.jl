
const Theme = Attributes

Base.broadcastable(x::AbstractScene) = Ref(x)
Base.broadcastable(x::AbstractPlot) = Ref(x)
Base.broadcastable(x::Attributes) = Ref(x)

#dict interface
const AttributeOrPlot = Union{AbstractPlot, Attributes}

Attributes(; kw_args...) = Attributes(kw_args)
Attributes(pairs::Pair...) = Attributes(pairs)
Attributes(nt::NamedTuple) = Attributes(pairs(nt))

Base.pop!(x::AttributeOrPlot, args...) = pop!(x.attributes, args...)
Base.haskey(x::AttributeOrPlot, key::Symbol) = haskey(x.attributes, key)
Base.delete!(x::AttributeOrPlot, key::Symbol) = delete!(x.attributes, key)
function Base.get!(f::Function, x::AttributeOrPlot, key::Symbol)
    if haskey(x, key)
        return x[key]
    else
        val = f()
        x[key] = val
        return x[key]
    end
end
Base.get!(x::AttributeOrPlot, key::Symbol, default) = get!(()-> default, x, key)
Base.get(f::Function, x::AttributeOrPlot, key::Symbol) = haskey(x, key) ? x[key] : f()
Base.get(x::AttributeOrPlot, key::Symbol, default) = get(()-> default, x, key)

attributes(x::Attributes) = getfield(x, :attributes)

Base.keys(x::Attributes) = keys(x.attributes)
Base.values(x::Attributes) = values(x.attributes)
function Base.iterate(x::Attributes, state...)
    s = iterate(keys(x), state...)
    s === nothing && return nothing
    key = s[1]::Symbol
    return (key => x[key]::Union{Observable{Any}, Attributes}, s[2])
end

function Base.copy(attr::Attributes)
    return Attributes(copy(attributes(attr)))
end

# Deepcopy with special treatment for observables
# to deepcopy Attributes
_deepcopy(x) = x isa Observable ? Observable{Any}(to_value(x)) : deepcopy(x)
function Base.deepcopy(attributes::Attributes)
    result = Attributes()
    for (k, v) in attributes
        # We need to create a new Signal to have a real copy
        result[k] = _deepcopy(v)
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

function Base.getproperty(x::Attributes, key::Symbol)
    key === :attributes && return getfield(x, :attributes)
    return getindex(x, key)
end

Base.setproperty!(x::Attributes, key::Symbol, @nospecialize(value)) = setindex!(x, value, key)


function Base.getindex(x::Attributes, key::Symbol)
    x = attributes(x)[key]
    # We unpack Attributes, even though, for consistency, we store them as Observables
    # this makes it easier to create nested attributes
    return x[] isa Attributes ? x[] : x
end

function Base.setindex!(x::Attributes, @nospecialize(value), key::Symbol)
    if haskey(x, key)
        attributes(x)[key][] = value
    else
        attributes(x)[key] = Observable{Any}(value)
    end
end

function Base.setindex!(x::Attributes, value::Observable, key::Symbol)
    return attributes(x)[key] = convert(Observable{Any}, value)
end

_indent_attrs(s, n) = join(split(s, '\n'), "\n" * " "^n)

function Base.show(io::IO,::MIME"text/plain", attr::Attributes)

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
end

Base.show(io::IO, attr::Attributes) = show(io, MIME"text/plain"(), attr)
theme(x::AbstractPlot) = x.attributes
isvisible(x) = haskey(x, :visible) && to_value(x[:visible])


# This is a bit confusing, since for a plot it returns the attribute from the arguments
# and not a plot for integer indexing. But, we want to treat plots as "atomic"
# so from an interface point of view, one should assume that a plot doesn't contain subplots
# PlotObject plots break this assumption in some way, but the way to look at it is,
# that the plots contained in a PlotObject plot are not subplots, but _are_ actually
# the plot itself.
Base.getindex(plot::AbstractPlot, idx::Integer) = plot.converted[idx]
Base.getindex(plot::AbstractPlot, idx::UnitRange{<:Integer}) = plot.converted[idx]
Base.setindex!(plot::AbstractPlot, value, idx::Integer) = (plot.input_args[idx][] = value)
Base.length(plot::AbstractPlot) = length(plot.converted)

function Base.getindex(x::AbstractPlot, key::Symbol)
    argnames = argument_names(x.type, length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx === nothing
        arr = getfield(x, :attributes)
        res = arr[key]
        return res
    else
        return getfield(x, :converted)[idx]
    end
end

function Base.getindex(x::AttributeOrPlot, key::Symbol, key2::Symbol, rest::Symbol...)
    dict = to_value(x[key])
    dict isa Attributes || error("Trying to access $(typeof(dict)) with multiple keys: $key, $key2, $(rest)")
    dict[key2, rest...]
end

function Base.setindex!(x::AttributeOrPlot, @nospecialize(value), key::Symbol, key2::Symbol, rest::Symbol...)
    dict = to_value(x[key])
    dict isa Attributes || error("Trying to access $(typeof(dict)) with multiple keys: $key, $key2, $(rest)")
    dict[key2, rest...] = value
end

function Base.setindex!(x::AbstractPlot, @nospecialize(value), key::Symbol)
    argnames = argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx === nothing && haskey(x.attributes, key)
        return x.attributes[key][] = value
    elseif !haskey(x.attributes, key)
        x.attributes[key] = convert(Observable, value)
    else
        return setindex!(x.converted[idx], value)
    end
end

function Base.setindex!(x::AbstractPlot, value::Observable, key::Symbol)
    argnames = argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx === nothing
        if haskey(x, key)
            # error("You're trying to update an attribute Observable with a new Observable. This is not supported right now.
            # You can do this manually like this:
            # lift(val-> attributes[$key] = val, Observable::$(typeof(value)))
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
function get_attribute(dict, key, default=nothing)
    if haskey(dict, key)
        value = to_value(dict[key])
        value isa Automatic && return default
        return convert_attribute(to_value(dict[key]), Key{key}())
    else
        return default
    end
end

function merge_attributes!(input::Attributes, theme::Attributes)
    for (key, value) in theme
        if !haskey(input, key)
            input[key] = value
        else
            current_value = input[key]
            if value isa Attributes && current_value isa Attributes
                # if nested attribute, we merge recursively
                merge_attributes!(current_value, value)
            end
            # we're good! input already has a value, can ignore theme
        end
    end
    return input
end

function Base.propertynames(x::Union{Attributes, AbstractPlot})
    return (keys(x.attributes)...,)
end
