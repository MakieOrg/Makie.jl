dist(a, b) = abs(a-b)
mindist(x, a, b) = NaNMath.min(dist(a, x), dist(b, x))

function gappy(x, ps)
    n = length(ps)
    x <= first(ps) && return first(ps) - x
    for j=1:(n-1)
        p0 = ps[j]
        p1 = ps[NaNMath.min(j+1, n)]
        if p0 <= x && p1 >= x
            return mindist(x, p0, p1) * (isodd(j) ? 1 : -1)
        end
    end
    return last(ps) - x
end

function ticks(points, resolution)
    Float16[gappy(x, points) for x = linspace(first(points),last(points), resolution)]
end


function insert_pattern!(points, kw_args)
    tex = GLAbstraction.Texture(ticks(points, 100), x_repeat=:repeat)
    kw_args[:pattern] = tex
    kw_args[:pattern_length] = Float32(last(points))
end
function extract_linestyle(d, kw_args)
    haskey(d, :linestyle) || return
    ls = d[:linestyle]
    lw = d[:linewidth]
    kw_args[:thickness] = lw
    if ls == :dash
        points = [0.0, lw, 2lw, 3lw, 4lw]
        insert_pattern!(points, kw_args)
    elseif ls == :dot
        tick, gap = lw/2, lw/4
        points = [0.0, tick, tick+gap, 2tick+gap, 2tick+2gap]
        insert_pattern!(points, kw_args)
    elseif ls == :dashdot
        dtick, dgap = lw, lw
        ptick, pgap = lw/2, lw/4
        points = [0.0, dtick, dtick+dgap, dtick+dgap+ptick, dtick+dgap+ptick+pgap]
        insert_pattern!(points, kw_args)
    elseif ls == :dashdotdot
        dtick, dgap = lw, lw
        ptick, pgap = lw/2, lw/4
        points = [0.0, dtick, dtick+dgap, dtick+dgap+ptick, dtick+dgap+ptick+pgap, dtick+dgap+ptick+pgap+ptick,  dtick+dgap+ptick+pgap+ptick+pgap]
        insert_pattern!(points, kw_args)
    end
    extract_c(d, kw_args, :line)
    nothing
end
