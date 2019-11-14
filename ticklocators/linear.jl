function scale_range(vmin, vmax, n=1, threshold=100)
    dv = abs(vmax - vmin)  # > 0 as nonsingular is called before.
    meanv = (vmax + vmin) / 2
    offset = if abs(meanv) / dv < threshold
        0
    else
        copysign(10 ^ (log10(abs(meanv)) ÷ 1), meanv)
    end
    scale = 10 ^ (log10(dv / n) ÷ 1)
    scale, offset
end

function _staircase(steps)
    [0.1 .* steps[1:end-1]; steps; 10 .* steps[2]]
end


struct EdgeInteger
    step::Float64
    offset::Float64

    function EdgeInteger(step, offset)
        if step <= 0
            error("Step must be positive")
        end
        new(step, abs(offset))
    end
end

function closeto(e::EdgeInteger, ms, edge)
    tol = if e.offset > 0
        digits = log10(e.offset / e.step)
        tol = max(1e-10, 10 ^ (digits - 12))
        min(0.4999, tol)
    else
        1e-10
    end
    abs(ms - edge) < tol
end

function le(e::EdgeInteger, x)
    # 'Return the largest n: n*step <= x.'
    d, m = divrem(x, e.step)
    if closeto(e, m / e.step, 1)
        d + 1
    else
        d
    end
end

function ge(e::EdgeInteger, x)
    # 'Return the smallest n: n*step >= x.'
    d, m = divrem(x, e.step)
    if closeto(e, m / e.step, 0)
        d
    else
        d + 1
    end
end

"""
A cheaper function that tries to come up with usable tick locations for a given value range
"""
function locateticks(vmin, vmax, width_px, ideal_spacing_px; _integer=false, _min_n_ticks=2)

    _steps = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]
    _extended_steps = _staircase(_steps)

    # how many ticks would ideally fit?
    n_ideal = Int(round(width_px / ideal_spacing_px)) + 1

    scale, offset = scale_range(vmin, vmax, n_ideal)

    _vmin = vmin - offset
    _vmax = vmax - offset

    raw_step = (_vmax - _vmin) / n_ideal

    steps = _extended_steps * scale

    if _integer
        # For steps > 1, keep only integer values.
        igood = (steps .< 1) .| (abs.(steps .- round.(steps)) .< 0.001)
        steps = steps[igood]
    end

    #istep = np.nonzero(steps >= raw_step)[0][0]
    istep = findfirst(steps .>= raw_step)

    ticks = nothing
    for istep in istep:-1:1
        step = steps[istep]

        if _integer && (floor(_vmax) - ceil(_vmin) >= _min_n_ticks - 1)
            step = max(1, step)
        end
        best_vmin = (_vmin ÷ step) * step

        # Find tick locations spanning the vmin-vmax range, taking into
        # account degradation of precision when there is a large offset.
        # The edge ticks beyond vmin and/or vmax are needed for the
        # "round_numbers" autolimit mode.
        edge = EdgeInteger(step, offset)
        low = le(edge, _vmin - best_vmin)
        high = ge(edge, _vmax - best_vmin)
        low:high
        ticks = (low:high) .* step .+ best_vmin
        # Count only the ticks that will be displayed.
        # nticks = sum((ticks .<= _vmax) .& (ticks .>= _vmin))

        # manual sum because broadcasting was slow
        nticks = 0
        for t in ticks
            if _vmin <= t <= _vmax
                nticks += 1
            end
        end

        if nticks >= _min_n_ticks
            break
        end
    end
    ticks = ticks .+ offset
    filter(x -> vmin <= x <= vmax, ticks)
end
