function data_limits(x)
    FRect3D(x[:position][])
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

extrema_nan(itr::Pair) = (itr[1], itr[2])

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


function boundingbox(x, y, z = (0=>0))
    minmax = extrema_nan.((x, y, z))
    mini, maxi = first.(minmax), last.(minmax)
    FRect3D(mini, maxi .- mini)
end

function data_limits(x::Union{Heatmap, Contour, Image})
    boundingbox(value.((x.args[1], x.args[2]))...)
end

data_limits(x::Union{Surface}) = boundingbox(value.(x.args)...)

data_limits(x::Mesh) = FRect3D(value(x.args[1]))


function data_limits(x::Text)
    @extractvals x (textsize, font, align, rotation, model)
    txt = value(x.args[1])
    position = x.attributes[:position][]
    positions, scales = if isa(position, VecTypes)
        layout_text(txt * last(txt), args...)
    elseif  length(txt) == length(position) && length(txt) == length(textsize)
        position, textsize
    else
        error("Incompatible sizes found: $(length(textsize)) && $(length(txt)) && $(length(position))")
    end
    FRect3D(union(HyperRectangle(positions .+ scales), HyperRectangle(positions)))
end

function data_limits(x::Combined{:Annotations})
    # data limits is supposed to not include any transformation.
    # for the annotation, we use the model matrix directly, so we need to
    # to inverse that transformation for the correct limits
    bb = data_limits(x.plots[1])
    inv(value(x[:model])) * bb
end

Base.isfinite(x::Rect) = all(isfinite.(minimum(x))) &&  all(isfinite.(maximum(x)))

function data_limits(plots::Vector)
    isempty(plots) && return FRect3D(Vec3f0(0), Vec3f0(0))
    idx = start(plots)
    bb = FRect3D()
    println(typeof.(plots))
    while !done(plots, idx)
        plot, idx = next(plots, idx)
        # axis shouldn't be part of the data limit
        isaxis(plot) && continue
        bb2 = data_limits(plot)
        isfinite(bb) || (bb = bb2)
        isfinite(bb2) || continue
        bb = union(bb, bb2)
    end
    bb
end

data_limits(s::Scene) = data_limits(plots_from_camera(s))
data_limits(plot::Combined) = data_limits(plot.plots)


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
