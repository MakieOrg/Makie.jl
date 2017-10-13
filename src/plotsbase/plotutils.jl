# Things that will go into PlotUtils.jl


function optimal_ticks_and_labels(axis::Axis, ticks = nothing)
    amin,amax = axis_limits(axis)

    # scale the limits
    scale = axis[:scale]
    sf = scalefunc(scale)

    # If the axis input was a Date or DateTime use a special logic to find
    # "round" Date(Time)s as ticks
    # This bypasses the rest of optimal_ticks_and_labels, because
    # optimize_datetime_ticks returns ticks AND labels: the label format (Date
    # or DateTime) is chosen based on the time span between amin and amax
    # rather than on the input format
    # TODO: maybe: non-trivial scale (:ln, :log2, :log10) for date/datetime
    if ticks == nothing && scale == :identity
        if axis[:formatter] == dateformatter
            # optimize_datetime_ticks returns ticks and labels(!) based on
            # integers/floats corresponding to the DateTime type. Thus, the axes
            # limits, which resulted from converting the Date type to integers,
            # are converted to 'DateTime integers' (actually floats) before
            # being passed to optimize_datetime_ticks.
            # (convert(Int, convert(DateTime, convert(Date, i))) == 87600000*i)
            ticks, labels = optimize_datetime_ticks(864e5 * amin, 864e5 * amax;
                k_min = 2, k_max = 4)
            # Now the ticks are converted back to floats corresponding to Dates.
            return ticks / 864e5, labels
        elseif axis[:formatter] == datetimeformatter
            return optimize_datetime_ticks(amin, amax; k_min = 2, k_max = 4)
        end
    end

    # get a list of well-laid-out ticks
    if ticks == nothing
        scaled_ticks = optimize_ticks(
            sf(amin),
            sf(amax);
            k_min = 4, # minimum number of ticks
            k_max = 8, # maximum number of ticks
        )[1]
    elseif typeof(ticks) <: Int
        scaled_ticks, viewmin, viewmax = optimize_ticks(
            sf(amin),
            sf(amax);
            k_min = ticks, # minimum number of ticks
            k_max = ticks, # maximum number of ticks
            k_ideal = ticks,
            # `strict_span = false` rewards cases where the span of the
            # chosen  ticks is not too much bigger than amin - amax:
            strict_span = false,
        )
        axis[:lims] = map(invscalefunc(scale), (viewmin, viewmax))
    else
        scaled_ticks = map(sf, (filter(t -> amin <= t <= amax, ticks)))
    end
    unscaled_ticks = map(invscalefunc(scale), scaled_ticks)

    labels = if any(isfinite, unscaled_ticks)
        formatter = axis[:formatter]
        if formatter == :auto
            # the default behavior is to make strings of the scaled values and then apply the labelfunc
            map(labelfunc(scale, backend()), Showoff.showoff(scaled_ticks, :plain))
        elseif formatter == :scientific
            Showoff.showoff(unscaled_ticks, :scientific)
        else
            # there was an override for the formatter... use that on the unscaled ticks
            map(formatter, unscaled_ticks)
        end
    else
        # no finite ticks to show...
        String[]
    end

    # @show unscaled_ticks labels
    # labels = Showoff.showoff(unscaled_ticks, scale == :log10 ? :scientific : :auto)
    unscaled_ticks, labels
end

# return (continuous_values, discrete_values) for the ticks on this axis
function get_ticks(axis::Axis)
    ticks = _transform_ticks(axis[:ticks])
    ticks in (nothing, false) && return nothing

    dvals = axis[:discrete_values]
    cv, dv = if !isempty(dvals) && ticks == :auto
        # discrete ticks...
        axis[:continuous_values], dvals
    elseif ticks == :auto
        # compute optimal ticks and labels
        optimal_ticks_and_labels(axis)
    elseif typeof(ticks) <: Union{AVec, Int}
        # override ticks, but get the labels
        optimal_ticks_and_labels(axis, ticks)
    elseif typeof(ticks) <: NTuple{2, Any}
        # assuming we're passed (ticks, labels)
        ticks
    else
        error("Unknown ticks type in get_ticks: $(typeof(ticks))")
    end
    # @show ticks dvals cv dv

    # TODO: better/smarter cutoff values for sampling ticks
    if length(cv) > 30 && ticks == :auto
        rng = Int[round(Int,i) for i in linspace(1, length(cv), 15)]
        cv[rng], dv[rng]
    else
        cv, dv
    end
end
