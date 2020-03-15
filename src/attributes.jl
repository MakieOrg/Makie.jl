
"""
Main structure for holding attributes in e.g. plots!
"""
struct ObservableAttributes
    # name, for better error messages!
    name::String
    # We dont have one node per value anymore, but instead one node
    # that gets triggered on any setindex!, or whenever an input attribute node changes
    # This makes it easier to layer Observable{ObservableAttributes}()
    on_change::Observable{Pair{Symbol, Any}}
    # The supported fields, so we can throw an error, whenever fields are not supported
    supported_fields::Set{Symbol}
    # The attributes given at construction time, taking the highest priority
    from_user::Dict{Symbol, Any}
    # attributes filled in by e.g. a theme, or other processes in the pipeline
    from_theme::Dict{Symbol, Any}
    # The "global" default values for this specific attribute instance
    # Will be immutabe (maybe not a Dict then?) and shared between all similar objects
    default_values::Dict{Symbol, Any}

    function ObservableAttributes(name::String, default_values::Dict{Symbol, Any}, from_user::Dict{Symbol, Any})
        on_change = Observable{Pair{Symbol, Any}}()
        supported_fields = Set(keys(default_values))
        return new(name, on_change, supported_fields, from_user,
                   Dict{Symbol, Any}(), default_values)
    end
end

function ObservableAttributes(;kw...)
    return ObservableAttributes(kw)
end

value_convert2(x::Observables.AbstractObservable) = x[]
value_convert2(@nospecialize(x)) = x
function value_convert2(x::NTuple{N, Union{Any, Observables.AbstractObservable}}) where N
    return to_value.(x)
end
value_convert2(x::NamedTuple) = ObservableAttributes(x)

function ObservableAttributes(kw)
    defaults = Dict{Symbol, Any}()
    for (k, v) in pairs(kw)
        xx = value_convert2(v)
        defaults[k] = xx
        @assert !(xx isa Observable)
    end
    attributes = ObservableAttributes("", defaults, Dict{Symbol, Any}())
    for (k, v) in pairs(kw)
        if v isa Observables.AbstractObservable
            on(v) do value
                setproperty!(attributes, k, value)
            end
        end
    end
    return attributes
end

function Base.getindex(attributes::ObservableAttributes, field::Symbol)
    return getproperty(attributes, field)
end

function Base.getindex(attributes::ObservableAttributes, field::Symbol, b::Symbol)
    x = getproperty(attributes, b)
    return getproperty(x, field)
end

function Base.propertynames(attributes::ObservableAttributes)
    return getfield(attributes, :supported_fields)
end

function on_change(x::ObservableAttributes)
    return getfield(x, :on_change)
end

function on_change(f, x::ObservableAttributes)
    return on(f, on_change)
end

"""
attributes.attribute returns an observable.
Since we don't actually convert all values to Observables anymore,
we'll need to create new Observables on getproperty.
With OnFieldUpdate, we can do that lazily, store them in `listeners(onchange(obs))`,
and only create a new one for fields that aren't in listeners yet.
"""
struct OnFieldUpdate
    field::Symbol
    observable::Observable
end

function (of::OnFieldUpdate)(field_value::Pair{Symbol, <: Any})
    if field_value[1] === of.field
        of.observable[] = field_value[2]
    end
    return
end

function OnFieldUpdate(attributes::ObservableAttributes, field::Symbol)
    # We lazily store observables on field updates in the listeners
    # If we already have it in there, we just return the one we have.
    onchange = on_change(attributes)
    for listener in Observables.listeners(onchange)
        if listener isa OnFieldUpdate && listener.field === field
            return listener
        end
    end
    # we haven't found a listener, so we create a new one!
    result = Observable{Any}(get_value(attributes, field))
    of = OnFieldUpdate(field, result)
    on(of, onchange)
    return of
end

"""
    get_value(attributes::ObservableAttributes, field::Symbol)
Gets the value for `field`.
The values are looked up in the following order:
    1) user given at creation time
    2) theme given
    3) global defaults
"""
function get_value(attributes::ObservableAttributes, field::Symbol)
    name = getfield(attributes, :name)
    if field in propertynames(attributes)
        # The priority is:
        # User given
        from_user = getfield(attributes, :from_user)
        haskey(from_user, field) && return from_user[field]
        # ObservableAttributes given
        from_theme = getfield(attributes, :from_theme)
        haskey(from_theme, field) && return from_theme[field]
        # Construction defaults
        default_values = getfield(attributes, :default_values)
        haskey(default_values, field) && return default_values[field]
        error("Incorrectly constructed ObservableAttributes ($(name))! No value found for $(field)")
    else
        from_user = getfield(attributes, :from_user)
        default_values = getfield(attributes, :default_values)
        pn = propertynames(attributes)
        error("Field $(field) not in $(pn) $(from_user) $(default_values)!")
    end
end

function Base.getproperty(attributes::ObservableAttributes, field::Symbol)
    val = get_value(attributes, field)
    val isa ObservableAttributes && return val
    of = OnFieldUpdate(attributes, field)
    return of.observable
end

function Base.setproperty!(attributes::ObservableAttributes, field::Symbol, value)
    name = getfield(attributes, :name)
    # we always set the users data, since setting this is done by the user!
    from_user = getfield(attributes, :from_user)
    from_user[field] = value
    on_change = getfield(attributes, :on_change)
    # trigger change!
    on_change[] = field => value
    if !(field in propertynames(attributes))
        # TODO, dont let anyone change propertynames!
        push!(propertynames(attributes), field)
        default_values = getfield(attributes, :default_values)
        default_values[field] = value
    end
    return value
end

function Base.setproperty!(attributes::ObservableAttributes, field::Symbol, value::Observable)
    setproperty!(attributes, field, value[])
    on(value) do new_value
        setproperty!(attributes, field, value[])
    end
    return value
end

function Base.setindex!(attributes::ObservableAttributes, value, field::Symbol)
    setproperty!(attributes, field, value)
end

Base.broadcastable(x::ObservableAttributes) = Ref(x)

#######
## Dict interface
Base.keys(x::ObservableAttributes) = propertynames(x)
Base.values(x::ObservableAttributes) = (getproperty(x, field) for field in propertynames(x))
function Base.pop!(x::ObservableAttributes, field::Symbol)
    value = getproperty(x, field)
    delete!(x, field)
    return value
end

Base.haskey(x::ObservableAttributes, key::Symbol) = key in keys(x)

Base.filter(f, x::ObservableAttributes) = ObservableAttributes(filter(f, attributes(x)))
Base.empty!(x::ObservableAttributes) = (empty!(attributes(x)); x)
Base.length(x::ObservableAttributes) = length(attributes(x))

function Base.delete!(attributes::ObservableAttributes, field::Symbol)
    # The priority is:
    # User given
    from_user = getfield(attributes, :from_user)
    haskey(from_user, field) && delete!(from_user, field)
    # ObservableAttributes given
    from_theme = getfield(attributes, :from_theme)
    haskey(from_theme, field) && delete!(from_theme, field)
    # Construction defaults
    default_values = getfield(attributes, :default_values)
    haskey(default_values, field) && delete!(default_values, field)
    delete!(propertynames(attributes), field)
    return
end

function Base.iterate(x::ObservableAttributes, state...)
    s = iterate(keys(x), state...)
    s === nothing && return nothing
    return (s[1] => x[s[1]], s[2])
end

function Base.copy(attributes::ObservableAttributes)
    return ObservableAttributes(attributes)
end

Base.merge(target::ObservableAttributes, args::ObservableAttributes...) = merge!(copy(target), args...)

function merge_attributes!(input::ObservableAttributes, theme::ObservableAttributes)
    for (key, value) in theme
        if !haskey(input, key)
            input[key] = value
        else
            current_value = input[key]
            if value isa ObservableAttributes && current_value isa ObservableAttributes
                # if nested attribute, we merge recursively
                merge_attributes!(current_value, value)
            elseif value isa ObservableAttributes || current_value isa ObservableAttributes
                error("""
                Type missmatch while merging plot attributes with theme for key: $(key).
                Found $(to_value(value)) in theme, while attributes contains: $(current_value)
                """)
            else
                # we're good! input already has a value, can ignore theme
            end
        end
    end
    return input
end

function Base.merge!(target::ObservableAttributes, args::ObservableAttributes...)
    for elem in args
        merge_attributes!(target, elem)
    end
    return target
end

function Base.show(io::IO,::MIME"text/plain", attr::ObservableAttributes)
    d = Dict()
    for (k, v) in attr
        d[k] = to_value(v)
    end
    show(IOContext(io, :limit => false), MIME"text/plain"(), d)
end

Base.show(io::IO, attr::ObservableAttributes) = show(io, MIME"text/plain"(), attr)

"""
    get_attribute(dict::ObservableAttributes, key::Key)
Gets the attribute at `key`, converts it and extracts the value
"""
function get_attribute(dict::ObservableAttributes, key::Symbol)
    return convert_attribute(get_value(dict, key), Key{key}())
end


"""
    get_attribute(dict::ObservableAttributes, key::Key)
Gets the attribute at `key` as a converted signal
"""
function get_lifted_attribute(dict::ObservableAttributes, key::Symbol)
    return lift(x-> convert_attribute(x, Key{key}()), getproperty(dict, key))
end
