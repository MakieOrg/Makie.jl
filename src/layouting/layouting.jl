function zerorect(x::HyperRectangle{N, T}) where {N, T}
    HyperRectangle(Vec{N, T}(0), widths(x))
end
function padrect(rect, pad)
    Rect(minimum(rect) .- pad, widths(rect) .+ 2pad)
end


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
    pos = to_ndim(Point3f0, mpos, 0)
    scales = Vec2f0[glyph_scale!(atlas, c, ft_font, rscale) for c in string]

    positions2d = calc_position(string, Point2f0(0), rscale, ft_font, atlas)
    aoffset = align_offset(Point2f0(0), positions2d[end], atlas, rscale, ft_font, offset_vec)
    aoffsetn = to_ndim(Point3f0, aoffset, 0f0)
    positions = map(positions2d) do p
        pn = rot * (to_ndim(Point3f0, p, 0f0) .+ aoffsetn)
        pn .+ (pos)
    end
    positions, scales
end

function text_bb(str, font, size)
    positions, scale = layout_text(
        str, Point2f0(0), size,
        font, Vec2f0(0), Quaternionf0(0,0,0,1), Mat4f0(I)
    )
    union(AABB(positions),  AABB(positions .+ to_ndim.(Point3f0, scale, 0)))
end

"""
    move_from_touch(
        parent::GeometryPrimitive{N, T}, child::GeometryPrimitive{N},
        pad::Vec{N}
    ) where {N, T}

calculates how much `child` rectangle needs to move to not touch the `parent`
"""
function move_from_touch(
        parent::GeometryPrimitive{N, T}, child::GeometryPrimitive{N},
        pad::Vec{N}
    ) where {N, T}
    pmini, cmini = minimum(parent), minimum(child) .- pad
    pmaxi, cmaxi = maximum(parent), maximum(child) .+ pad

    move = ntuple(Val(N)) do i
        posdir = ifelse(cmini[i] < pmini[i], (pmini[i] - cmini[i]), zero(T)) #always positive
        negdir = ifelse(cmaxi[i] > pmaxi[i], (pmaxi[i] - cmaxi[i]), zero(T)) #always minus
        ifelse(posdir > abs(negdir), posdir, negdir) # move in the bigger direction
    end
    Vec{N, T}(move)
end

"""
    dont_touch(
        parent::GeometryPrimitive{N}, child::GeometryPrimitive{N},
        pad::Vec{N}
    ) where N

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
    stretches = ntuple(Val(N)) do i
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
        i, j = Tuple(CartesianIndices(grid)[idx])
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


estimated_space(x, N, w) = 1/N

ispixelcam(x::Union{PixelCamera, Camera2D}) = true
ispixelcam(x) = false

"""
    vbox(scenes...; parent = Scene(clear = false), kwargs...)

Lay the given Scenes out on the vertical axis.  For example, two Scenes `vbox`ed
will be placed side-by-side.
"""
vbox(plots::Transformable...; kw_args...) = vbox([plots...]; kw_args...)
"""
    hbox(scenes...; parent = Scene(clear = false), kwargs...)

Lay the given Scenes out on the horizonral axis.  For example, two Scenes `vbox`ed
will be placed side-by-side.
"""
hbox(plots::Transformable...; kw_args...) = hbox([plots...]; kw_args...)

function hbox(plots::Vector{T}; parent = Scene(clear = false), kw_args...) where T <: Scene
    layout(plots, 2; parent = parent, kw_args...)
end
function vbox(plots::Vector{T}; parent = Scene(clear = false), kw_args...) where T <: Scene
    layout(plots, 1; parent = parent, kw_args...)
end

function to_sizes(x::AbstractVector{<: Number}, widths, dim)
    x .* widths[dim]
end

function layout(plots::Vector{T}, dim; parent = Scene(clear = false), sizes = nothing, kw_args...) where T <: Scene
    N = length(plots)
    w = 0.0
    area = pixelarea(parent)
    sizes_node = if sizes == nothing
        lift(a-> layout_sizes(plots, widths(a), dim), area)
    else
        lift(a-> to_sizes(sizes, widths(a), dim), area)
    end
    summed_size = lift(sizes_node) do s
        last_s = 0.0
        map(s) do x
            r = last_s; last_s += x; return r
        end
    end
    for idx in 1:N
        p = plots[idx]
        on(area) do a
            h = sizes_node[][idx]
            last = summed_size[][idx]
            mask = unit(Vec2f0, dim)
            # TODO this is terrible!
            new_w = Vec2f0(ntuple(2) do i
                i == dim ? h : widths(a)[i]
            end)
            resize!(p, IRect(minimum(a) .+ (mask .* last), new_w))
        end
        push!(parent.children, p)
        p.parent = parent
        nodes = map(fieldnames(Events)) do field
            if field != :window_area
                connect!(getfield(parent.events, field), getfield(p.events, field))
            end
        end
    end
    area[] = area[]
    parent
end


otherdim(dim) = dim == 1 ? 2 : 1


function scaled_width(bb, other_size, dim)
    wh = widths(bb)
    scaling = other_size / wh[otherdim(dim)]
    wh[dim] * scaling
end

function pixel_boundingbox(scene::Scene)
    if cameracontrols(scene) isa PixelCamera
        return true
    elseif cameracontrols(scene) isa EmptyCamera
        # scene doesn't supply the camera itself, check children
        return all(pixel_boundingbox, scene.children)
    else
        false
    end
end


function layout_sizes(scenes, size, dim)
    odim = otherdim(dim)
    this_size = size[dim]
    other_size = size[odim]
    N = length(scenes)
    pix_size = 0.0 # combined height of pixel bbs
    sizes = fill(-1.0, N)
    scenepix = findall(pixel_boundingbox, scenes)
    perfect_size = this_size / N # equal size for all!
    for i in scenepix
        scene = scenes[i]
        ds = widths(boundingbox(scene))[dim] .+ 10 # pad a bit
        sizes[i] = ds
        pix_size += ds
    end
    perfect_size = (this_size - pix_size) / (N - length(scenepix))
    for i in 1:N
        if sizes[i] == -1
            sizes[i] = perfect_size
        end
    end
    npixies = length(scenepix)
    # # We should only use 1/N per window, so if the accumulated size is bigger
    # # than that, we need to rescale the sizes
    total_size = sum(sizes)
    if this_size <= total_size # we need to rescale
        # no pixelsizes or all pixelsizes, we can just resize everything
        if npixies == 0 || npixies == N
            for i in 1:N
                sizes[i] = (sizes[i] / total_size) * this_size
            end
        else # we have a mix of pix + non pix sizes - only scale non pix
            total_px_size = sum(sizes[scenepix])
            # TODO too big total_px_size
            remaining = total_size - total_px_size
            space = this_size - total_px_size
            for i in 1:N
                (i in scenepix) && continue
                sizes[i] = (sizes[i] / remaining) * space
            end
        end
    end
    # final_pix_size = pix_size
    #
    # if max_pix_size < pix_size
    #     for i in scenes2d
    #         sizes[i] = (sizes[i] / pix_size) * max_pix_size
    #     end
    #     final_pix_size = max_pix_size
    # end
    # nonpixel_size = (this_size - final_pix_size) / (N - npixies)
    # for i in 1:N
    #     if !(i in scenes2d)
    #         sizes[i] = nonpixel_size
    #     end
    # end
    sizes
end


function vbox!(plots::Vector{T}; kw_args...) where T <: AbstractPlot
    N = length(plots)
    w = 0.0
    for idx in 1:N
        p = plots[idx]
        translate!(p, w, 0.0, 0.0)
        swidth = widths(boundingbox(p))
        w += (swidth[1] * 1.1)
    end
end
function hbox!(plots::Vector{T}; kw_args...) where T <: AbstractPlot
    N = length(plots)
    h = 0.0
    for idx in 1:N
        p = plots[idx]
        translate!(p, 0.0, h, 0.0)
        swidth = widths(boundingbox(p))
        h += (swidth[2] * 1.2)
    end
end
