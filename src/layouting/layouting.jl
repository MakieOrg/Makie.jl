
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
calculates how much `child` rectangle needs to move to not touch the `parent`
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


grid(x::Transformable...; kw_args...) = grid([x...]; kw_args...)
function grid(plots::Vector{<: Transformable}; kw_args...)
    N = length(plots)
    grid = close2square(N)
    grid(reshape(plots, grid))
end
function grid(plots::Matrix{<: Transformable}; kw_args...)
    N = length(plots)
    grid = size(plots)
    w, h = (0.0, 0.0)
    pscene = Scene()
    cam2d!(pscene)
    for idx in 1:N
        i, j = ind2sub(grid, idx)
        child = plots[idx]
        push!(pscene.children, child)
        translate!(child, w, h, 0.0)
        swidth = widths(boundingbox(child))
        if i == grid[1]
            h += (swidth[2] * 1.1)
            w = 0.0
        else
            w += (swidth[1] * 1.1)
        end
    end
    center!(pscene)
    pscene
end

vbox(plots::Transformable...; kw_args...) = vbox([plots...]; kw_args...)

estimated_space(x, N, w) = 1/N


function Base.resize!(scene::Scene, rect::Rect2D)
    pixelarea(scene)[] = rect
    force_update!()
    yield()
end


function vbox(plots::Vector{T}; kw_args...) where T <: Scene
    N = length(plots)
    w = 0.0
    pscene = Scene()
    area = pixelarea(pscene)

    for idx in 1:N
        p = plots[idx]
        foreach(area) do a
            # TODO this is terrible!
            w2 = widths(a) .* Vec((1/N), 1)
            resize!(p, IRect(minimum(a) .+ Vec((idx - 1) * w2[1], 0), w2))
            center!(p)
        end
        push!(pscene.children, p)
        nodes = map(fieldnames(Events)) do field
            if field != :window_area
                foreach(getfield(pscene.events, field)) do val
                    push!(getfield(p.events, field), val)
                end
            end
        end
    end
    pscene
end


function vbox(plots::Vector{T}; kw_args...) where T <: AbstractPlot
    N = length(plots)
    w = 0.0
    for idx in 1:N
        p = plots[idx]
        translate!(p, w, 0.0, 0.0)
        swidth = widths(boundingbox(p))
        w += (swidth[1] * 1.1)
    end
end
