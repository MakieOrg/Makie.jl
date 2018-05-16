
function optimal_ticks_and_labels(limits, ticks = nothing)
    amin, amax = limits
    # scale the limits
    scale = :identity
    sf = identity
    invscale = identity #invscalefunc(scale)
    # If the axis input was a Date or DateTime use a special logic to find
    # "round" Date(Time)s as ticks
    # This bypasses the rest of optimal_ticks_and_labels, because
    # optimize_datetime_ticks returns ticks AND labels: the label format (Date
    # or DateTime) is chosen based on the time span between amin and amax
    # rather than on the input format
    # TODO: maybe: non-trivial scale (:ln, :log2, :log10) for date/datetime
    # get a list of well-laid-out ticks
    if ticks == nothing
        scaled_ticks = optimize_ticks(
            sf(amin),
            sf(amax);
            k_min = 4, # minimum number of ticks
            k_max = 8, # maximum number of ticks
        )[1]
    elseif isa(ticks, Integer) # a single integer for number of ticks
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
    else
        scaled_ticks = map(sf, (filter(t -> amin <= t <= amax, ticks)))
    end
    unscaled_ticks = map(invscale, scaled_ticks)

    labels = if any(isfinite, unscaled_ticks)
        formatter = :auto #axis[:formatter]
        if formatter == :auto
            # the default behavior is to make strings of the scaled values and then apply the labelfunc
            lfunc = identity#labelfunc(scale, backend())
            map(identity, Showoff.showoff(scaled_ticks, :plain))
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
    unscaled_ticks, labels
end

function range_labels(limits)
    ticks, labels = optimal_ticks_and_labels(limits, nothing)
    zip(ticks, labels)
end
