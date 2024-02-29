# Some code to try to handle date types in Makie plots
# Currently only handles `Date` and `Day`.
"""
    number_to_date(::Type{T}, i::Int)

Attempts to reconstruct a Dates type by inverting `Dates.value(obj::T)`.
"""
number_to_date(::Type{Time}, i) = Time(Nanosecond(round(Int64, Float64(i)))) # TODO, lossless TwicePrecision -> Nanosecond
number_to_date(::Type{Date}, i) = Date(Dates.UTInstant{Day}(Day(round(Int64, Float64(i)))))
number_to_date(::Type{DateTime}, i) = DateTime(Dates.UTM(round(Int64, Float64(i))))

date_to_number(::Type{T}, value::Dates.AbstractTime) where {T} = Dates.value(value)
date_to_number(value::Dates.AbstractTime) = Dates.value(value)

# Allow to plot quantities into a Time unit axis
function date_to_number(::Type{Time}, value::Unitful.Quantity)
    isnan(value) && return NaN
    nanis = Nanosecond(round(u"ns", value))
    return Dates.value(Time(nanis))
end

"""
    DateTimeConversion(type=Automatic; k_min=automatic, k_max=automatic, k_ideal=automatic)

Creates conversion & conversions for Date, DateTime and Time. For other time units one should use `UnitfulTicks`, which work with e.g. Seconds.

For DateTimes `PlotUtils.optimize_datetime_ticks` is used for getting the conversion, otherwise `WilkinsonTicks` are used on the integer representation of the date.

# Arguments

- `type=automatic`: when left at automatic, the first plot into the axis will determine the type. Otherwise, one can set this to `Time`, `Date`, or `DateTime`.
- `k_min=automatic`: gets passed to `PlotUtils.optimize_datetime_ticks` for DateTimes, and otherwise to `WilkinsonTicks`.
- `k_max=automatic`: gets passed to `PlotUtils.optimize_datetime_ticks` for DateTimes, and otherwise to `WilkinsonTicks`.
- `k_ideal=automatic`: will be ignored for DateTime, and passed to `WilkinsonTicks` for Time / Date.

# Examples

```julia
date_time = DateTime("2021-10-27T11:11:55.914")
date_time_range = range(date_time, step=Week(5), length=10)
# Automatically chose xticks as DateTeimeTicks:
scatter(date_time_range, 1:10)

# explicitely chose DateTimeConversion and use it to plot unitful values into it and display in the `Time` format:
using Unitful
yticks = DateTimeConversion(Time)
scatter(1:4, (1:4) .* u"s", axis=(yticks=yticks,))
```
"""
struct DateTimeConversion
    # first element in tuple is the time type we converted from, which can be:
    # Time, Date, DateTime
    # Second entry in tuple is a value we use to normalize the number range,
    # so that they fit into float32
    type::Observable{Tuple{DataType,Float32Scaling{Int64}}}
    k_min::Union{Automatic, Int}
    k_max::Union{Automatic, Int}
    k_ideal::Union{Automatic, Int}
    function DateTimeConversion(type=Automatic; k_min=automatic, k_max=automatic, k_ideal=automatic)
        F32S = Float32Scaling{Int64}
        obs = Observable{Tuple{DataType,F32S}}((type, F32S(1.0, 0.0)); ignore_equal_values=true)
        return new(obs, k_min, k_max, k_ideal)
    end
end

dim_conversion_type(::Type{<: Dates.TimeType}) = DateTimeConversion()
MakieCore.can_axis_convert_type(::Type{<: Dates.TimeType}) = true

function convert_axis_dim(conversion::DateTimeConversion, values::Observable)
    eltype = MakieCore.get_element_type(values[])
    T, scaling = conversion.type[]
    if T <: Automatic
        new_type = eltype
        init_vals = date_to_number.(T, values[])
        # TODO update minimum in connect! on limit change!
        scaling = update_scaling_factors(scaling, extrema(init_vals)...)
        conversion.type[] = (new_type, scaling)
    elseif T != eltype
        if !(T <: Time && eltype <: Unitful.Quantity)
            error("Plotting unit $(eltype) into axis with type $(T) not supported.")
        end
    end
    return map(values, conversion.type) do vals, (T, scaling)
        return scale_value.(Ref(scaling), date_to_number.(T, vals))
    end
end

function connect_conversion!(ax::Axis, conversion_obs::Observable, conversion::DateTimeConversion, dim)
    on(ax.blockscene, ax.finallimits) do limits
        # Don't update if nothing plotted yet
        if isempty(ax.scene.plots)
            return
        end
        T, scaling = conversion.type[]
        # Get scaled extrema of the limits of the dimension
        mini, maxi = getindex.(extrema(limits), dim)
        # Calculate new scaling
        new_scaling = update_scaling_factors(scaling, mini, maxi)
        if new_scaling != scaling
            # Only update if the scaling changed
            conversion.type[] = (T, new_scaling)
            notify(conversion_obs)
        end
    end
end

function get_ticks(conversion::DateTimeConversion, ticks, scale, formatter, vmin, vmax)
    if !(formatter isa Automatic)
        error("You can't use a formatter with DateTime conversion")
    end

    if scale != identity
        error("$(scale) scale not supported for DateTimeConversion")
    end

    T, f32scaling = conversion.type[]

    # When automatic, we haven't actually plotted anything yet, so no unit chosen
    # in that case, we can't really have any conversion
    T <: Automatic && return [], []
    umin = unscale_value(f32scaling, vmin)
    umax = unscale_value(f32scaling, vmax)
    if T <: DateTime
        k_min = conversion.k_min isa Automatic ? 2 : conversion.k_min
        k_max = conversion.k_max isa Automatic ? 3 : conversion.k_max
        conversion, dates = PlotUtils.optimize_datetime_ticks(umin, umax; k_min=k_min, k_max=k_max)
        return scale_value.(Ref(f32scaling), conversion), dates
    else
        # TODO implement proper conversion for Time Date
        k_min = conversion.k_min isa Automatic ? 3 : conversion.k_min
        k_max = conversion.k_max isa Automatic ? 6 : conversion.k_max
        k_ideal = conversion.k_ideal isa Automatic ? 4 : conversion.k_ideal
        formatter = WilkinsonTicks(k_ideal; k_min=k_min, k_max=k_max)
        tickvalues = get_tickvalues(formatter, scale, umin, umax)
        dates = number_to_date.(T, round.(Int64, tickvalues))
        return scale_value.(Ref(f32scaling), tickvalues), string.(dates)
    end
end
