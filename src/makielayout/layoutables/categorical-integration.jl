struct CategoricalTicks
    category_to_int::Observable{Dict{Any, Int}}
    int_to_category::Dict{Int, Any}
    sortby::Function
end

CategoricalTicks(; sortby=last) = CategoricalTicks(Observable(Dict{Any, Int}()), Dict{Int, Any}(), sortby)

ticks_from_type(::Type{String}) = CategoricalTicks()

function convert_axis_dim(ticks::CategoricalTicks, values::Observable, limits::Observable)
    function cat2int(val)
        int = get!(ticks.category_to_int[], val, length(ticks.category_to_int[]))
        ticks.int_to_category[int] = val
        return int
    end
    map(values) do values
        foreach(cat2int, values)
        notify(ticks.category_to_int)
    end
    return map(x-> cat2int.(x), values)
end

function MakieLayout.get_ticks(ticks::CategoricalTicks, scale, formatter, vmin, vmax)
    categories = sort(collect(ticks.category_to_int[]), by=ticks.sortby)

    return last.(categories), string.(first.(categories))
end
