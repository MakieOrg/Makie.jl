
function data_limits(x)
    map_once(to_node(x[:position])) do points
        ex = Tuple.(extrema_nan(points))
    end
end

function extrema_nan(x::ClosedInterval)
    (minimum(x), maximum(x))
end
_isfinite(x) = isfinite(x)
_isfinite(x::VecTypes) = all(isfinite, x)
scalarmax(x::AbstractArray, y::AbstractArray) = max.(x, y)
scalarmax(x, y) = max(x, y)
scalarmin(x::AbstractArray, y::AbstractArray) = min.(x, y)
scalarmin(x, y) = min(x, y)

function extrema_nan(itr)
    s = start(itr)
    done(itr, s) && throw(ArgumentError("collection must be non-empty"))
    (v, s) = next(itr, s)
    vmin = vmax = v
    while !_isfinite(v) && !done(itr, s)
        (v, s) = next(itr, s)
        vmin = vmax = v
    end
    while !done(itr, s)
        (x, s) = next(itr, s)
        _isfinite(x) || continue
        vmax = scalarmax(x, vmax)
        vmin = scalarmin(x, vmin)
    end
    return (vmin, vmax)
end

function data_limits(x::Union{Heatmap, Contour, Image})
    map_once(to_node(x.args[1]), to_node(x.args[2])) do x, y
        xy_e = extrema_nan(x), extrema_nan(y)
        (first.(xy_e), last.(xy_e))
    end
end
function data_limits(x::Mesh)
    map_once(to_node(x.args[1])) do mesh
        bb = AABB(mesh)
        (minimum(bb), maximum(bb))
    end
end

function data_limits(x::Text)
    keys = (:position, :textsize, :font, :align, :rotation, :model)
    map_once(to_node(x.args[1]), getindex.(x.attributes, keys)...) do txt, args...
        positions, scale = layout_text(txt * last(txt), args...)
        ex = union(HyperRectangle(positions .+ scale), HyperRectangle(positions))
        Tuple.((minimum(ex), maximum(ex)))
    end
end

"""
calculates how much `child` needs to move to not touch `parent`
"""
function move_from_touch(
        parent::GeometryPrimitive{N, T}, child::GeometryPrimitive{N},
        pad::Vec{N}
    ) where {N, T}
    pmini, cmini = minimum(parent), minimum(child) .- pad
    pmaxi, cmaxi = maximum(parent), maximum(child) .+ pad

    move = ntuple(Val{N}) do i
        posdir = ifelse(cmini[i] < pmini[i], (pmini[i] - cmini[i]), zero(T)) #always positive
        negdir = ifelse(cmaxi[i] > pmaxi[i], (pmaxi[i] - cmaxi[i]), zero(T)) #always minus
        ifelse(posdir > abs(negdir), posdir, negdir) # move in the bigger direction
    end
    Vec{N, T}(move)
end

"""
Moves `child` so that it doesn't touch parent. Leaves a gap to parent defined by `pad`.
"""
function dont_touch(
        parent::GeometryPrimitive{N}, child::GeometryPrimitive{N},
        pad::Vec{N}
    ) where N
    child + move_from_touch(parent, child, pad)
end



"""
    fit_factor_stretch(rect, lims::NTuple{N}) where N

Calculates the stretch factor to fill `rect` in all dimension.
Returns a stretch `N` dimensional fit factor.
"""
function fit_factor_stretch(rect, lims::NTuple{N, Any}) where N
    w = widths(rect)
    stretches = ntuple(Val{N}) do i
        from, to = lims[i]
        w[i] / abs(to - from)
    end
    stretches
end

"""
    fit_factor(rect, lims::NTuple{N}) where N

Calculates the scaling one needs to apply to lims to fit `rect` without changing aspect ratio.
Returns float scaling and the full strech as given by [`fit_factor_stretch`](@ref)
"""
function fit_factor(rect, lims::NTuple{N, Any}) where N
    stretches = fit_factor_stretch(rect, lims)
    minimum(stretches), stretches
end


"""
    fit_ratio(rect, lims)

Calculates the ratio one needs to stretch `lims` in order to get the same aspect ratio
"""
function fit_ratio(rect, lims)
    s, stretches = fit_factor(rect, lims)
    stretches ./ s
end


function align_offset(startpos, lastpos, atlas, rscale, font, align)
    xscale, yscale = GLVisualize.glyph_scale!('X', rscale)
    xmove = (lastpos-startpos)[1] + xscale
    if isa(align, GeometryTypes.Vec)
        return -Vec2f0(xmove, yscale) .* align
    elseif align == :top
        return -Vec2f0(xmove/2f0, yscale)
    elseif align == :right
        return -Vec2f0(xmove, yscale/2f0)
    else
        error("Align $align not known")
    end
end

function alignment2num(x::Symbol)
    (x == :center) && return 0.5f0
    (x in (:left, :bottom)) && return 0.0f0
    (x in (:right, :top)) && return 1.0f0
    0.0f0 # 0 default, or better to error?
end




# using GeometryTypes
#
# using Base.Test
#
# x = HyperRectangle(Vec3f0(-2), Vec3f0(2))
# c = HyperRectangle(Vec3f0(-2), Vec3f0(2))
# @test dont_touch(x, c, Vec3f0(0)) == x
# c = HyperRectangle(Vec3f0(-2), Vec3f0(1.5))
# @test dont_touch(x, c, Vec3f0(0.25)) == HyperRectangle(Vec3f0(-1.75), Vec3f0(1.5))
# c = HyperRectangle(Vec3f0(0), Vec3f0(1, 1.75, 1))
# @test dont_touch(x, c, Vec3f0(0.25)) == HyperRectangle(Vec3f0(-1.25, -2.0, -1.25), Vec3f0(1.0, 1.75, 1.0))
# x = SimpleRectangle(0, 0, 1, 1)
# SimpleRectangle(HyperRectangle(x))
