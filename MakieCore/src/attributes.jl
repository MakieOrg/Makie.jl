
const Theme = Attributes

Base.broadcastable(x::AbstractScene) = Ref(x)
Base.broadcastable(x::AbstractPlot) = Ref(x)
Base.broadcastable(x::Attributes) = Ref(x)

function Attributes(; kw_args...)
    attr = Dict{Symbol, Any}()
    for (k, v) in kw_args
        if v isa NamedTuple
            attr[k] = Attributes(v)
        else
            attr[k] = v
        end
    end
    return Attributes(attr)
end

function Attributes(nt::NamedTuple)
    attr = Dict{Symbol, Any}()
    for (k, v) in pairs(nt)
        if v isa NamedTuple
            attr[k] = Attributes(v)
        else
            attr[k] = v
        end
    end
    return Attributes(attr)
end

function Attributes(pairs::Base.Pairs)
    attr = Dict{Symbol, Any}()
    for (k, v) in pairs
        if v isa NamedTuple
            attr[k] = Attributes(v)
        else
            attr[k] = v
        end
    end
    return Attributes(attr)
end

attributes(x::Union{AbstractPlot, Attributes}) = getfield(x, :attributes)
Base.keys(x::Attributes) = keys(attributes(x))
Base.values(x::Attributes) = values(attributes(x))

function Base.iterate(x::Attributes, state...)
    s = iterate(keys(x), state...)
    s === nothing && return nothing
    return (s[1] => x[s[1]], s[2])
end

function Base.copy(x::Attributes)
    result = Attributes()
    setfield!(result, :convert, getfield(x, :convert))
    setfield!(result, :plotkey, getfield(x, :plotkey))
    attr = attributes(x)
    obs = getfield(x, :observables)
    res_attr = attributes(result)
    for k in keys(x)
        res_attr[k] = get(obs, k, attr[k])
    end
    return result
end

function Base.deepcopy(x::Attributes)
    result = Attributes()
    setfield!(result, :convert, getfield(x, :convert))
    setfield!(result, :plotkey, getfield(x, :plotkey))
    attr = attributes(x)
    obs = getfield(x, :observables)
    res_attr = attributes(result)
    for k in keys(x)
        res_attr[k] = to_value(get(obs, k, attr[k]))
    end
    return result
end

Base.filter(f, x::Attributes) = filter!(f, copy(x))

function Base.filter!(f, x::Attributes)
    for kv in x
        !f(kv)::Bool && delete!(x, kv[1])
    end
    return x
end

function Base.empty!(x::Attributes)
    for (k, v) in x
        if v isa Attributes
            empty!(v)
        elseif v isa Observable
            close(v)
        else
            # should be unreachable
            error("Attributes should only contain Observables or Attributes")
        end
    end
    empty!(attributes(x))
end

Base.length(x::Attributes) = length(attributes(x))

function Base.merge!(target::Attributes, args::Attributes...)
    for elem in args
        merge_attributes!(target, elem)
    end
    return target
end

Base.merge(target::Attributes, args::Attributes...) = merge!(copy(target), args...)

function Base.getproperty(x::Attributes, key::Symbol)
    attr = attributes(x)
    haskey(attr, key) || throw(KeyError(key))
    value = attr[key]
    value isa Attributes && return value

    observables = getfield(x, :observables)
    return get!(observables, key) do
        value_raw = to_value(value)
        obs = if getfield(x, :convert)
            Observable(convert_attribute(value_raw, Key{key}(), Key{getfield(x, :plotkey)}()))
        else
            Observable{Any}(value_raw)
        end
        if value isa Observable
            on(new_val-> x[key] = new_val, value)
        end
        return obs
    end
end

function Base.setproperty!(x::Attributes, key::Symbol, value::Any)
    if !haskey(x, key)
        attributes(x)[key] = value
    end
    obs = x[key]
    if obs isa Attributes
        attributes(x)[key] = value
        return value
    else
        val = if getfield(x, :convert)
            convert_attribute(to_value(value), Key{key}(), Key{getfield(x, :plotkey)}())
        else
            to_value(value)
        end
        obs[] = val
        return val
    end
end

Base.getindex(x::Attributes, key::Symbol) = Base.getproperty(x, key)
Base.setindex!(x::Attributes, val, key::Symbol) = Base.setproperty!(x, key, val)


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
theme(x::AbstractPlot) = attributes(x)

#dict interface
const AttributeOrPlot = Union{AbstractPlot, Attributes}

function Base.pop!(x::AttributeOrPlot, key::Symbol)
    value = x[key]
    delete!(x, key)
    return value
end

function Base.pop!(x::AttributeOrPlot, key::Symbol, default)
    haskey(x, key) || return default
    value = x[key]
    delete!(x, key)
    return value
end

Base.haskey(x::AttributeOrPlot, key) = haskey(attributes(x), key)

function Base.delete!(x::Attributes, key::Symbol)
    delete!(attributes(x), key)
    delete!(getfield(x, :observables), key)
    return x
end
function Base.delete!(x::AbstractPlot, key::Symbol)
    delete!(attributes(x), key)
    return x
end

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

# This is a bit confusing, since for a plot it returns the attribute from the arguments
# and not a plot for integer indexing. But, we want to treat plots as "atomic"
# so from an interface point of view, one should assume that a plot doesn't contain subplots
# Combined plots break this assumption in some way, but the way to look at it is,
# that the plots contained in a Combined plot are not subplots, but _are_ actually
# the plot itself.
Base.getindex(plot::AbstractPlot, idx::Integer) = plot.converted[idx]
Base.getindex(plot::AbstractPlot, idx::UnitRange{<:Integer}) = plot.converted[idx]
Base.setindex!(plot::AbstractPlot, value, idx::Integer) = (plot.input_args[idx][] = value)
Base.length(plot::AbstractPlot) = length(plot.converted)

function Base.getindex(x::AbstractPlot, key::Symbol)
    argnames = argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx === nothing
        return getproperty(attributes(x), key)
    else
        x.converted[idx]
    end
end

function Base.setindex!(x::AbstractPlot, value, key::Symbol)
    argnames = argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    attr = attributes(x)
    if idx === nothing
        return setproperty!(attr, key, value)
    else
        return setindex!(x.converted[idx], value)
    end
end

@generated hasfield(x::T, ::Val{key}) where {T, key} = :($(key in fieldnames(T)))

function Base.getproperty(x::AbstractPlot, key::Symbol)
    if hasfield(x, Val(key))
        getfield(x, key)
    else
        getindex(x, key)
    end
end

function Base.setproperty!(x::AbstractPlot, key::Symbol, value)
    if hasfield(x, Val(key))
        setfield!(x, key, value)
    else
        setindex!(x, value, key)
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
            input[key] = copy(value)
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
    return (keys(attributes(x))...,)
end
