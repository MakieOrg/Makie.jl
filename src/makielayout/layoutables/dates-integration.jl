# Some code to try to handle date types in Makie plots
# Currently only handles `Date` and `Day`.
"""
    unvalue(::Type{T}, i::Int)

Attempts to reconstruct a Dates type by inverting `Dates.value(obj::T)`.
"""
unvalue(::Type{T}, i::Int64) where {T} = T(i)
unvalue(::Type{Date}, i::Int64) = Date(Dates.UTInstant{Day}(Day(i)))
unvalue(::Type{Time}, i::Int64) = Time(Nanosecond(i))
unvalue(::Type{<: Union{TimeType, DateTime}}, i::Int64) = DateTime(Dates.UTM(i))

struct DateTimeTicks
    # first element in tuple is the time type we converted from, which can be:
    # DateTime
    # Time
    # Date
    # Second entry in tuple is a value we use to normalize the number range,
    # so that they fit into float32
    type::Observable{Tuple{Any, Int64}}
    DateTimeTicks(type=Time) = new(Observable{Tuple{Any, Int64}}((type, 0)))
end

ticks_from_type(::Type{<: Dates.TimeType}) = DateTimeTicks()

function convert_axis_dim(ticks::DateTimeTicks, values::Observable, limits::Observable)
    eltype = get_element_type(values[])
    T, mini = ticks.type[]
    new_type = promote_type(T, eltype)
    if new_type == Dates.AbstractTime
        error("Can't promote time types $(T) with $(eltype). Please use a time that can be converted to $(T)")
    end
    init_vals = Dates.value.(values[])
    ticks.type[] = (new_type, minimum(init_vals))
    converted = map((vals, (T, mini))-> Dates.value.(vals) .- mini, values, ticks.type)
    return converted
end

function MakieLayout.get_ticks(ticks::DateTimeTicks, scale, formatter, vmin, vmax)
    T, mini = ticks.type[]
    if T <: DateTime
        ticks, dates = PlotUtils.optimize_datetime_ticks(vmin + mini, vmax + mini; k_min = 2, k_max = 4)
        return ticks .- mini, dates
    else
        tickvalues = MakieLayout.get_tickvalues(formatter, scale, vmin, vmax)
        dates = unvalue.(T, round.(Int64, tickvalues .+ mini))
        return tickvalues, string.(dates)
    end
end
