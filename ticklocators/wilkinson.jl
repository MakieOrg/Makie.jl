function WilkinsonTicks(k_ideal::Int; k_min = 2, k_max = 10,
        Q = [(1.0,1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)],
        granularity_weight = 1/4,
        simplicity_weight = 1/6,
        coverage_weight = 1/3,
        niceness_weight = 1/4,
        min_px_dist = 50.0)

    if !(0 < k_min <= k_ideal <= k_max)
        error("Invalid tick number specifications k_ideal $k_ideal, k_min $k_min, k_max $k_max")
    end

    WilkinsonTicks(k_ideal, k_min, k_max, Q, granularity_weight, simplicity_weight,
        coverage_weight, niceness_weight, min_px_dist)
end


get_tick_labels(ticks::WilkinsonTicks, tickvalues) = linearly_spaced_tick_labels(tickvalues)

function compute_tick_values(ticks::WilkinsonTicks, vmin, vmax, pxwidth)

    min_px_dist = ticks.min_px_dist
    n_max_allowed_ticks = max(ticks.k_min, round(Int, pxwidth / min_px_dist))

    tickvalues, _ = PlotUtils.optimize_ticks(vmin, vmax;
        extend_ticks = false, strict_span=true, span_buffer = nothing,
        k_min = ticks.k_min,
        k_max = min(ticks.k_max, n_max_allowed_ticks),
        k_ideal = min(ticks.k_ideal, n_max_allowed_ticks),
        Q = ticks.Q,
        granularity_weight = ticks.granularity_weight,
        simplicity_weight = ticks.simplicity_weight,
        coverage_weight = ticks.coverage_weight,
        niceness_weight = ticks.niceness_weight)

    tickvalues
end
