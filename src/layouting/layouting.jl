const Plot{Typ, Arg} = Union{Atomic{Typ, Arg}, Combined{Typ, Arg}}


data_limits(x::Plot{Typ, <: Tuple{Arg1}}) where {Typ, Arg1} = FRect3D(value(x[1]))

function data_limits(x::Plot{Typ, <: Tuple{X, Y, Z}}) where {Typ, X, Y, Z}
    _boundingbox(value.(x[1:3])...)
end

function data_limits(x::Plot{Typ, <: Tuple{X, Y}}) where {Typ, X, Y}
    _boundingbox(value.(x[1:2])...)
end

_isfinite(x) = isfinite(x)
_isfinite(x::VecTypes) = all(isfinite, x)
scalarmax(x::AbstractArray, y::AbstractArray) = max.(x, y)
scalarmax(x, y) = max(x, y)
scalarmin(x::AbstractArray, y::AbstractArray) = min.(x, y)
scalarmin(x, y) = min(x, y)

extrema_nan(itr::Pair) = (itr[1], itr[2])
extrema_nan(itr::ClosedInterval) = (minimum(itr), maximum(itr))

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


function _boundingbox(x, y, z = (0=>0))
    minmax = extrema_nan.((x, y, z))
    mini, maxi = first.(minmax), last.(minmax)
    FRect3D(mini, maxi .- mini)
end

const ImageLike{Arg} = Union{Heatmap{Arg}, Image{Arg}}
function data_limits(x::ImageLike{<: Tuple{X, Y, Z}}) where {X, Y, Z}
    _boundingbox(value.((x[1], x[2]))...)
end

function data_limits(x::Volume)
    _boundingbox(value.((x[1], x[2], x[3]))...)
end



function data_limits(x::Text)
    @extractvalue x (textsize, font, align, rotation, model)
    txt = value(x[1])
    position = x.attributes[:position][]
    positions, scales = if isa(position, VecTypes)
        layout_text(txt * last(txt), position, textsize, font, align, rotation, model)
    elseif  length(txt) == length(position) && length(txt) == length(textsize)
        position, textsize
    else
        error("Incompatible sizes found: $(length(textsize)) && $(length(txt)) && $(length(position))")
    end
    pos_scale = map(scales, positions) do s, p
        sn = to_ndim(typeof(p), s, 0)
        sn .+ p
    end
    FRect3D(union(HyperRectangle(pos_scale), HyperRectangle(positions)))
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

function layout_text(
        string::AbstractString, startpos::VecTypes{N, T}, textsize::Number,
        font, align, rotation, model
    ) where {N, T}

    offset_vec = to_align(align)
    ft_font = to_font(font)
    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    atlas = get_texture_atlas()
    mpos = model * Vec4f0(to_ndim(Vec3f0, startpos, 0f0)..., 1f0)
    pos = to_ndim(Point{N, Float32}, mpos, 0)

    positions2d = calc_position(string, Point2f0(0), rscale, ft_font, atlas)
    aoffset = align_offset(Point2f0(0), positions2d[end], atlas, rscale, ft_font, offset_vec)
    aoffsetn = to_ndim(Point{N, Float32}, aoffset, 0f0)
    scales = Vec2f0[glyph_scale!(atlas, c, ft_font, rscale) for c = string]
    positions = map(positions2d) do p
        pn = rot * (to_ndim(Point{N, Float32}, p, 0f0) .+ aoffsetn)
        pn .+ (pos)
    end
    positions, scales
end
function text_bb(str, font, size)
    positions, scale = layout_text(
        str, Point2f0(0), size,
        font, Vec2f0(0), Quaternionf0(0,0,0,1), eye(Mat4f0)
    )
    union(AABB(positions),  AABB(positions .+ scale))
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
    xscale, yscale = glyph_scale!('X', rscale)
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







function real_limits(scene::Scene)
    bb = AABB{Float32}()
    for plot in flatten_combined(plots_from_camera(scene))
        bb2 = data_limits(plot)
        bb == AABB{Float32}() && (bb = bb2)
        bb = union(bb, bb2)
    end
    bb
end

grid(x::Transformable...; kw_args...) = grid([x...]; kw_args...)
function grid(plots::Vector{T}; kw_args...) where T <: Transformable
    N = length(plots)
    grid = close2square(N)
    w, h = (0.0, 0.0)
    pscene = Makie.current_scene()
    for idx in 1:N
        i, j = ind2sub(grid, idx)
        p = Base.parent(plots[idx])
        translate!(p, w, h, 0.0)
        swidth = widths(real_limits(p))
        if i == grid[1]
            h += (swidth[2] * 1.1)
            w = 0.0
        else
            w += (swidth[1] * 1.1)
        end
    end
    pscene
end

vbox(plots::Transformable...; kw_args...) = vbox([plots...]; kw_args...)

function vbox(plots::Vector{T}; kw_args...) where T <: Transformable
    N = length(plots)
    w = 0.0
    pscene = Makie.current_scene()
    for idx in 1:N
        p = Base.parent(plots[idx])
        translate!(p, w, 0.0, 0.0)
        swidth = widths(real_limits(p))
        w += (swidth[1] * 1.1)
    end
    pscene
end
export vbox
