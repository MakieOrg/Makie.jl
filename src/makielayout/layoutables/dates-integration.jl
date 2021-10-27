# Some code to try to handle date types in Makie plots
# Currently only handles `Date` and `Day`.
"""
    number_to_date(::Type{T}, i::Int)

Attempts to reconstruct a Dates type by inverting `Dates.value(obj::T)`.
"""
number_to_date(::Type{Time}, i::Int64) = Time(Nanosecond(i))
number_to_date(::Type{Date}, i::Int64) = Date(Dates.UTInstant{Day}(Day(i)))
number_to_date(::Type{DateTime}, i::Int64) = DateTime(Dates.UTM(i))

date_to_number(::Type{T}, value::Dates.AbstractTime) where T = Float64(Dates.value(value))

function date_to_number(::Type{T}, value::Unitful.Quantity) where T
    isnan(value) && return NaN
    ns = Nanosecond(round(u"ns", value))
    return Float64(Dates.value(T(ns)))
end

struct DateTimeTicks
    # first element in tuple is the time type we converted from, which can be:
    # Time, Date, DateTime
    # Second entry in tuple is a value we use to normalize the number range,
    # so that they fit into float32
    type::Observable{Tuple{<: Type{<: Union{Time, Date, DateTime, Automatic}}, Int64}}
    DateTimeTicks(type=Automatic) = new(Observable{Tuple{Any, Float64}}((type, 0)))
end

ticks_from_type(::Type{<: Dates.TimeType}) = DateTimeTicks()

function convert_axis_dim(ticks::DateTimeTicks, values::Observable, limits::Observable)
    eltype = get_element_type(values[])
    T, mini = ticks.type[]
    new_type = T <: Automatic ? eltype : T
    if new_type != eltype
        error("Can't plot elements of type $(eltype) into axis with type $(T). Please use type $(T)")
    end

    init_vals = date_to_number.(T, values[])

    ticks.type[] = (new_type, Makie.nan_extrema(init_vals)[1])

    converted = map(values, ticks.type) do vals, (T, mini)
        return date_to_number.(T, vals) .- mini
    end
    return converted
end

function MakieLayout.get_ticks(ticks::DateTimeTicks, scale, formatter, vmin, vmax)
    T, mini = ticks.type[]
    T <: Automatic && return ([], [])

    if T <: DateTime
        ticks, dates = PlotUtils.optimize_datetime_ticks(Float64(vmin) + mini, Float64(vmax) + mini; k_min = 2, k_max = 3)
        return ticks .- mini, dates
    else
        tickvalues = MakieLayout.get_tickvalues(formatter, scale, vmin, vmax)
        dates = number_to_date.(T, round.(Int64, tickvalues .+ mini))
        return tickvalues, string.(dates)
    end
end
