function WilkinsonTicks(k_ideal::Int = 6; k_min::Int = k_ideal - 4, k_max::Int = k_ideal + 4,
        Q = [(1.0,1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)],
        granularity_weight = 1/4,
        simplicity_weight = 1/6,
        coverage_weight = 1/3,
        niceness_weight = 1/4,
        min_px_dist = 50.0)

    if !(0 < k_min <= k_ideal <= k_max)
        error("Invalid tick number specifications `k_ideal` $k_ideal, `k_min` $k_min, `k_max` $k_max.  `k_ideal` must be between `k_min` and `k_max`!")
    end

    WilkinsonTicks(k_ideal, k_min, k_max, Q, granularity_weight, simplicity_weight,
        coverage_weight, niceness_weight, min_px_dist)
end

get_tickvalues(ticks::WilkinsonTicks, vmin, vmax) = get_tickvalues(ticks, Float64(vmin), Float64(vmax))

function get_tickvalues(ticks::WilkinsonTicks, vmin::Float64, vmax::Float64)

    tickvalues, _ = PlotUtils.optimize_ticks(Float64(vmin), Float64(vmax);
        extend_ticks = false, strict_span=true, span_buffer = nothing,
        k_min = ticks.k_min,
        k_max = ticks.k_max,
        k_ideal = ticks.k_ideal,
        Q = ticks.Q,
        granularity_weight = ticks.granularity_weight,
        simplicity_weight = ticks.simplicity_weight,
        coverage_weight = ticks.coverage_weight,
        niceness_weight = ticks.niceness_weight)

    tickvalues
end
