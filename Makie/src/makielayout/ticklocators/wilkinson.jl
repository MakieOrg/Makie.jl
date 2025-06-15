"""
    WilkinsonTicks(
        k_ideal::Int;
        k_min = 2, k_max = 10,
        Q = [(1.0, 1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)],
        granularity_weight = 1/4,
        simplicity_weight = 1/6,
        coverage_weight = 1/3,
        niceness_weight = 1/4
    )

`WilkinsonTicks` is a thin wrapper over `PlotUtils.optimize_ticks`, the docstring of which is reproduced below:

$(@doc PlotUtils.optimize_ticks)
"""
function WilkinsonTicks(
        k_ideal::Int;
        k_min = 2, k_max = 10,
        Q = [(1.0, 1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)],
        granularity_weight = 1 / 4,
        simplicity_weight = 1 / 6,
        coverage_weight = 1 / 3,
        niceness_weight = 1 / 4
    )
    if !(0 < k_min <= k_ideal <= k_max)
        error("Invalid tick number specifications k_ideal $k_ideal, k_min $k_min, k_max $k_max")
    end

    return WilkinsonTicks(
        k_ideal, k_min, k_max, Q, granularity_weight,
        simplicity_weight, coverage_weight, niceness_weight
    )
end

get_tickvalues(ticks::WilkinsonTicks, vmin, vmax) = get_tickvalues(ticks, Float64(vmin), Float64(vmax))

function get_tickvalues(ticks::WilkinsonTicks, vmin::Float64, vmax::Float64)

    ticklocations, _ = PlotUtils.optimize_ticks(
        Float64(vmin), Float64(vmax);
        extend_ticks = false, strict_span = true, span_buffer = nothing,
        k_min = ticks.k_min,
        k_max = ticks.k_max,
        k_ideal = ticks.k_ideal,
        Q = ticks.Q,
        granularity_weight = ticks.granularity_weight,
        simplicity_weight = ticks.simplicity_weight,
        coverage_weight = ticks.coverage_weight,
        niceness_weight = ticks.niceness_weight
    )

    return ticklocations
end
