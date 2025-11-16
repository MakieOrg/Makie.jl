"""
    CategoricalConversion(; sortby=identity)

Categorical conversion. Gets chosen automatically only for `Categorical(array_of_objects)` and `Enums` right now.
The categories work with any sortable value though, so one can always do `Axis(fig; dim1_conversion=CategoricalConversion())`,
to use it for other categories.
One can use `CategoricalConversion(sortby=func)`, to change the sorting, or make unsortable objects sortable.

# Examples

```julia
# Ticks get chosen automatically as categorical
scatter(1:4, Categorical(["a", "b", "c", "a"]))
```

```julia
# Explicitly set them for other types:
struct Named
    value
end
Base.show(io::IO, s::SomeStruct) = println(io, "[\$(s.value)]")

conversion = Makie.CategoricalConversion(sortby=x->x.value)
barplot(Named.([:a, :b, :c]), 1:3, axis=(dim1_conversion=conversion,))
```
"""
struct CategoricalConversion <: AbstractDimConversion
    # TODO, use ordered sets/dicts?
    # I've run into problems with OrderedCollections.jl
    # Which seems to be the only ordered set/dict implementation
    # It's another dependency as well, so right now we just use vectors
    sets::Vector{Pair{String, Vector{Any}}}
    category_to_int::Observable{Dict{Any, Int}}
    int_to_category::Vector{Pair{Int, Any}}
    sortby::Union{Nothing, Function}
end

function CategoricalConversion(; sortby = nothing)
    return CategoricalConversion(
        Pair{String, Vector{Any}}[],
        Observable(Dict{Any, Int}(); ignore_equal_values = true),
        Pair{Int, Any}[],
        sortby
    )
end

expand_dimensions(::PointBased, y::Categorical) = (keys(y.values), y)
needs_tick_update_observable(conversion::CategoricalConversion) = conversion.category_to_int
should_dim_convert(::Type{Categorical}) = true
create_dim_conversion(::Type{Categorical}) = CategoricalConversion(; sortby = identity)

# Support enums as categorical per default
expand_dimensions(::PointBased, y::AbstractVector{<:Enum}) = (keys(y), y)
should_dim_convert(::Type{<:Enum}) = true
create_dim_conversion(::Type{<:Enum}) = CategoricalConversion(; sortby = identity)

function recalculate_categories!(conversion::CategoricalConversion)
    all_categories = []
    for (id, set) in conversion.sets
        append!(all_categories, set)
    end
    unique!(all_categories)
    if !isnothing(conversion.sortby)
        sort!(all_categories; by = conversion.sortby)
    end
    empty!(conversion.category_to_int[])
    empty!(conversion.int_to_category)
    i2c = pairs(all_categories)
    append!(conversion.int_to_category, i2c)
    return merge!(conversion.category_to_int[], Dict(reverse(p) for p in i2c))
end


get_values(x) = x
get_values(x::Categorical) = x.values

function convert_dim_value(conversion::CategoricalConversion, value::Categorical)
    return getindex.(Ref(conversion.category_to_int[]), get_values(value))
end

# TODO, use ordered sets/dicts?
function dict_get!(f, dict, key)
    idx = findfirst(x -> x[1] == key, dict)
    if isnothing(idx)
        val = f()
        push!(dict, key => val)
        return val
    else
        return dict[idx][2]
    end
end

function dict_setindex!(dict, key, value)
    idx = findfirst(x -> x[1] == key, dict)
    return if isnothing(idx)
        push!(dict, key => value)
    else
        dict[idx] = key => value
    end
end

function convert_dim_value(conversion::CategoricalConversion, value)
    if !haskey(conversion.category_to_int[], value)
        set = dict_get!(() -> [], conversion.sets, "")
        push!(set, value)
        unique!(set)
        recalculate_categories!(conversion)
        notify(conversion.category_to_int)
    end
    return conversion.category_to_int[][value]
end

function convert_categorical(conversion::CategoricalConversion, value)
    return conversion.category_to_int[][value]
end

function convert_categorical(conversion::CategoricalConversion, value::Integer)
    return conversion.category_to_int[][value]
end

function convert_dim_value(conversion::CategoricalConversion, attr, values, prev_values)
    # This is a bit tricky...
    # We need to recalculate the categories on each values_obs update,
    # but we also need to update the cat->int mapping each time the categories get recalculated
    # So category_to_int needs to be notified every time values_obs introduces new categories
    # but we don't want to recalculate cat->int two times, when value changes + category_to_int
    # so we introduce a placeholder observable that gets triggered when an update is needed
    # outside of category_to_int updating
    unwrapped_values = get_values(values)
    new_values = unique!(Any[v for v in unwrapped_values])
    if any(x -> !haskey(conversion.category_to_int[], x), new_values)
        dict_setindex!(conversion.sets, string(objectid(attr)), new_values)
        recalculate_categories!(conversion)
        # Others need to be updated too
        # This will also call this `convert_dim_value` again
        # But will then not trigger a new recalc of categories, since last == prev
        # Would be nice, to get out of that to not do `Any[v for v in unwrapped_values]` with a `==`
        notify(conversion.category_to_int)
    else
        # TODO, what do if no change?
    end
    # So now we update when either category_to_int changes, or
    # when values changes and an update is needed
    return convert_categorical.(Ref(conversion), unwrapped_values)
end


function get_ticks(conversion::CategoricalConversion, ticks, scale, formatter, vmin, vmax)
    scale != identity && error("Scale $(scale) not supported for categorical conversion")
    if ticks isa Automatic
        # TODO, do we want to support leaving out conversion? Right now, every category will become a tick
        # Maybe another function like filter?
        categories = last.(conversion.int_to_category)
    else
        categories = ticks
    end
    # TODO filter out ticks greater vmin vmax?
    numbers = convert_dim_value.(Ref(conversion), categories)
    labels_str = formatter isa Automatic ? string.(categories) : get_ticklabels(formatter, categories)
    return numbers, labels_str
end
