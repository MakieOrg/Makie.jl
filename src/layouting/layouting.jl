using FreeTypeAbstraction: hadvance, leftinkbound, inkwidth, get_extent, ascender, descender

function zerorect(x::Rect{N, T}) where {N, T}
    Rect(Vec{N, T}(0), widths(x))
end
function padrect(rect, pad)
    Rect(minimum(rect) .- pad, widths(rect) .+ 2pad)
end

one_attribute_per_char(attribute, string) = (attribute for char in string)

function one_attribute_per_char(font::NativeFont, string)
    return (find_font_for_char(char, font) for char in string)
end

function attribute_per_char(string, attribute)
    n_words = 0
    if attribute isa AbstractVector
        if length(attribute) == length(string)
            return attribute
        else
            n_words = length(split(string, r"\s+"))
            if length(attribute) == n_words
                i = 1
                return map(collect(string)) do char
                    f = attribute[i]
                    char == "\n" && (i += 1)
                    return f
                end
            end
        end
    else
        return one_attribute_per_char(attribute, string)
    end
    error("A vector of attributes with $(length(attribute)) elements was given but this fits neither the length of '$string' ($(length(string))) nor the number of words ($(n_words))")
end

function layout_text(
        string::AbstractString, startpos::VecTypes{N, T}, textsize::Union{AbstractVector, Number},
        font, align, rotation, model, justification, lineheight
    ) where {N, T}

    offset_vec = to_align(align)
    ft_font = to_font(font)
    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    atlas = get_texture_atlas()
    mpos = model * Vec4f0(to_ndim(Vec3f0, startpos, 0f0)..., 1f0)
    pos = to_ndim(Point3f0, mpos, 0)

    fontperchar = attribute_per_char(string, ft_font)
    textsizeperchar = attribute_per_char(string, rscale)

    glyphpos = glyph_positions(string, fontperchar, textsizeperchar, offset_vec[1],
        offset_vec[2], lineheight, justification)

    positions = Point3f0[]
    for (i, group) in enumerate(glyphpos)
        for gp in group
            p = to_ndim(Point3f0, gp, 0) #./ Point3f0(4, 4, 1)
            # rotate around the alignment point (this is now at [0, 0, 0])
            p_rotated = rot * p
            push!(positions, pos .+ p_rotated) # TODO why division by 4 necessary?
        end
        # between groups, push a random point for newline, it doesn't matter
        # what it is
        if i < length(glyphpos)
            push!(positions, Point3f0(0, 0, 0))
        end
    end

    return positions
end

function glyph_positions(str::AbstractString, font_per_char, fontscale_px, halign, valign, lineheight_factor, justification)

    char_font_scale = collect(zip([c for c in str], font_per_char, fontscale_px))

    linebreak_indices = (i for (i, c) in enumerate(str) if c == '\n')

    groupstarts = [1; linebreak_indices .+ 1]
    groupstops = [linebreak_indices .- 1; length(str)]

    cfs_groups = map(groupstarts, groupstops) do start, stop
        char_font_scale[start:stop]
    end

    extents = map(cfs_groups) do group
        # TODO: scale as SVector not Number
        [get_extent(font, char) .* SVector(scale, scale) for (char, font, scale) in group]
    end

    # add or subtract kernings?
    xs = map(extents) do extgroup
        cumsum([isempty(extgroup) ? 0.0 : -leftinkbound(extgroup[1]); hadvance.(extgroup[1:end-1])])
    end

    # each linewidth is the last origin plus inkwidth
    linewidths = last.(xs) .+ [isempty(extgroup) ? 0.0 : inkwidth(extgroup[end]) for extgroup in extents]
    maxwidth = maximum(linewidths)

    width_differences = maxwidth .- linewidths

    xs_justified = map(xs, width_differences) do xsgroup, wd
        xsgroup .+ wd * justification
    end

    # make lineheight a multiple of the largest lineheight in each line
    lineheights = map(cfs_groups) do group
        maximum(group) do (char, font, scale)
            font.height / font.units_per_EM * lineheight_factor * scale
        end
    end

    # how to define line height relative to font size?
    ys = cumsum([0; -lineheights[2:end]])


    # x alignment
    xs_aligned = [xsgroup .- halign * maxwidth for xsgroup in xs_justified]

    # y alignment
    # first_max_ascent = maximum(hbearing_ori_to_top, extents[1])
    # last_max_descent = maximum(x -> inkheight(x) - hbearing_ori_to_top(x), extents[end])

    first_line_ascender = maximum(cfs_groups[1]) do (char, font, scale)
        ascender(font) * scale
    end

    last_line_descender = minimum(cfs_groups[end]) do (char, font, scale)
        descender(font) * scale
    end

    overall_height = first_line_ascender - ys[end] - last_line_descender

    ys_aligned = ys .- first_line_ascender .+ (1 - valign) .* overall_height

    # we are still operating in freetype units, let's convert to the chosen scale by dividing with 64
    return [Vec2.(xsgroup, y) for (xsgroup, y) in zip(xs_aligned, ys_aligned)]
end

function text_bb(str, font, size)
    positions = layout_text(
        str, Point2f0(0), size,
        font, Vec2f0(0), Quaternionf0(0,0,0,1), Mat4f0(I), 0.5, 1.0
    )

    scale = widths.(first.(FreeTypeAbstraction.metrics_bb.(collect(str), font, size)))
    return union(FRect3D(positions),  FRect3D(positions .+ to_ndim.(Point3f0, scale, 0)))
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
    if align isa Vec
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
    return 0.0f0 # 0 default, or better to error?
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

Box the scenes together on the vertical axis.  For example, two Scenes `vbox`ed
will be placed side-by-side.

```
--------------------  --------------------
--                --  --                --
--    Scene 1     --  --    Scene 2     --
--                --  --                --
--------------------  --------------------
```
"""
vbox(plots::Transformable...; kw_args...) = vbox([plots...]; kw_args...)
"""
    hbox(scenes...; parent = Scene(clear = false), kwargs...)

Attach the given Scenes together on the horizontal axis.  For example, two Scenes `hbox`ed
will be placed one on top of the other.

```
--------------------
--                --
--    Scene 1     --
--                --
--------------------
--------------------
--                --
--    Scene 2     --
--                --
--------------------
```
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

function layout(
        plots::Vector{T}, dim;
        parent = Scene(clear = false), sizes = nothing, kw_args...
    ) where T <: Scene

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
