using Observables, Colors

abstract type AttributeFields end

struct Field{K} end
Base.broadcastable(x::Field) = (x,)
Field(sym) = Field{sym}()

struct NotConverted end

@nospecialize
# Fallback, that doesn't convert anything
convert_field(value, k) = NotConverted()
@specialize

function convert_field(attr::AttributeFields, value, k::Field{field}) where {field}
    # We need to jump through some hoops, to be able to overload convert_field(value, k),
    # without needing to do crazy things like hasmethod(convert, Tuple{T, typeof(value)})
    converted = convert_field(value, k)
    if converted isa NotConverted
        # If no convert_field overload, we fallback to convert
        T = fieldtype(typeof(attr), field)
        return convert(T, value)
    else
        # We done!
        return converted
    end
end

convert_field(value::Union{Symbol,AbstractString}, ::Field{:color}) = to_color(value)

struct FieldCallback
    callback::Function
    fields::Vector{Symbol}
end

struct Attributes{Fields<:AttributeFields}
    callback_table::Dict{Symbol,Set{FieldCallback}}
    has_value::Set{Symbol}
    observables::Dict{Symbol,Observable}
    # Type containing the actual values and fields
    attributes::Fields
end

function notify(attributes::Attributes, fields::Set{Symbol})
    table = getfield(attributes, :callback_table)
    callbacks = Set{FieldCallback}()
    for field in fields
        if haskey(table, field)
            union!(callbacks, table[field])
        end
    end
    for callback in callbacks
        f = callback.callback
        args = map(field -> getproperty(attributes, field), callback.fields)
        Base.invokelatest(f, args...)
    end
    return
end

function register_callback!(attributes::Attributes, @nospecialize(f::Function), fields::Vector{Symbol})
    table = getfield(attributes, :callback_table)
    callback = FieldCallback(f, fields)
    for field in fields
        set = get!(() -> Set{FieldCallback}(), table, field)
        push!(set, callback)
    end
    return callback
end

function remove_callback!(attributes::Attributes, @nospecialize(f::Function), fields::Vector{Symbol})
    callback = FieldCallback(f, fields)
    remove_callback!(attributes, callback)
    return
end

function remove_callback!(attributes::Attributes, callback::FieldCallback)
    table = getfield(attributes, :callback_table)
    for (_, callbacks) in table
        Base.delete!(callbacks, callback)
    end
    return
end

function Attributes(@nospecialize(attributes))
    return Attributes(
        Dict{Symbol,Set{FieldCallback}}(),
        Set{Symbol}(),
        Dict{Symbol,Observable}(),
        attributes
    )
end

Base.propertynames(attributes::Attributes) = propertynames(getfield(attributes, :attributes))

@inline function Base.getproperty(attributes::Attributes, field::Symbol)
    getproperty(getfield(attributes, :attributes), field)
end

function setproperty_noupdate!(attributes::Attributes, field::Symbol, value::Any)
    return setproperty!(getfield(attributes, :attributes), field, value)
end

function Base.setproperty!(attributes::AttributeFields, field::Symbol, value::Any)
    converted = convert_field(attributes, value, Field(field))
    FT = fieldtype(typeof(attributes), field)
    if !(converted isa FT)
        error("Attribute $(field) couldn't be converted to required type. Converted type $(typeof(converted)). Required type: $(FT)")
    end
    setfield!(attributes, field, converted)
    return converted
end

function update!(attributes::Attributes, values::Dict{Symbol})
    for (key, value) in values
        setproperty_noupdate!(attributes, key, value)
    end
    notify(attributes, Set(keys(values)))
    return
end

@nospecialize
update!(attributes::Attributes; kw...) = update!(attributes, Dict(pairs(kw)))
@specialize

function Base.setproperty!(attributes::Attributes, field::Symbol, value::Any)
    setproperty_noupdate!(attributes, field, value)
    notify(attributes, Set([field]))
    return
end

function Base.setproperty!(attributes::Attributes, field::Symbol, value::Observable)
    f(value) = setproperty!(attributes, field, value)
    on(f, value)
    f(value[])
    return
end

function on_update(f, attributes::Attributes, field::Symbol, fields::Symbol...)
    return register_callback!(attributes, f, [field, fields...])
end

function observe(attributes::Attributes{F}, ::Field{field}) where {F,field}
    ObsType = Observable{fieldtype(F, field)}
    return get!(getfield(attributes, :observables), field) do
        value = getproperty(attributes, field)
        obs = ObsType(value)
        on_update(attributes, Field(field)) do new_value
            obs[] = new_value
        end
        return obs
    end::ObsType
end
