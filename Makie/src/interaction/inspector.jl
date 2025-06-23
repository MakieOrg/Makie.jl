### indicator data -> string
########################################

vec2string(p::VecTypes{2}) = @sprintf("(%0.3f, %0.3f)", p[1], p[2])
vec2string(p::VecTypes{3}) = @sprintf("(%0.3f, %0.3f, %0.3f)", p[1], p[2], p[3])

position2string(p::VecTypes{2}) = @sprintf("x: %0.6f\ny: %0.6f", p[1], p[2])
position2string(p::VecTypes{3}) = @sprintf("x: %0.6f\ny: %0.6f\nz: %0.6f", p[1], p[2], p[3])

function bbox2string(bbox::Rect3)
    p0 = origin(bbox)
    p1 = p0 .+ widths(bbox)
    return @sprintf(
        """
        Bounding Box:
         x: (%0.3f, %0.3f)
         y: (%0.3f, %0.3f)
         z: (%0.3f, %0.3f)
        """,
        p0[1], p1[1], p0[2], p1[2], p0[3], p1[3]
    )
end

function bbox2string(bbox::Rect2)
    p0 = origin(bbox)
    p1 = p0 .+ widths(bbox)
    return @sprintf(
        """
        Bounding Box:
         x: (%0.3f, %0.3f)
         y: (%0.3f, %0.3f)
        """,
        p0[1], p1[1], p0[2], p1[2]
    )
end

color2text(c::AbstractFloat) = @sprintf("%0.3f", c)
color2text(c::Symbol) = string(c)
color2text(c) = color2text(to_color(c))
function color2text(c::RGBAf)
    return if c.alpha == 1.0
        @sprintf("RGB(%0.2f, %0.2f, %0.2f)", c.r, c.g, c.b)
    else
        @sprintf("RGBA(%0.2f, %0.2f, %0.2f, %0.2f)", c.r, c.g, c.b, c.alpha)
    end
end

color2text(name, i::Integer, j::Integer, c) = "$name[$i, $j] = $(color2text(c))"
function color2text(name, i, j, c)
    idxs = @sprintf("%0.2f, %0.2f", i, j)
    return "$name[$idxs] = $(color2text(c))"
end


### dealing with markersize and rotations
########################################

_to_scale(f::Real, idx) = Vec3f(f)
_to_scale(v::VecTypes{2}, idx) = Vec3f(v[1], v[2], 1)
_to_scale(v::VecTypes{3}, idx) = v
_to_scale(v::Vector, idx) = _to_scale(v[idx], idx)

_to_rotation(x, idx) = to_rotation(x)
_to_rotation(x::Vector, idx) = to_rotation(x[idx])


### Selecting a point on a nearby line
########################################

function closest_point_on_line(A::VecTypes{2}, B::VecTypes{2}, P::VecTypes{2})
    # This only works in 2D
    AP = P .- A; AB = B .- A
    return A .+ AB .* clamp(dot(AP, AB) / dot(AB, AB), 0, 1)
end

function point_in_triangle(A::VecTypes{2}, B::VecTypes{2}, C::VecTypes{2}, P::VecTypes{2}, ϵ = 1.0e-6)
    # adjusted from ray_triangle_intersection
    AO = A .- P
    BO = B .- P
    CO = C .- P
    A1 = 0.5 * (BO[1] * CO[2] - BO[2] * CO[1])
    A2 = 0.5 * (CO[1] * AO[2] - CO[2] * AO[1])
    A3 = 0.5 * (AO[1] * BO[2] - AO[2] * BO[1])

    # ϵ > 0 gives bias to `true`
    return (A1 > -ϵ && A2 > -ϵ && A3 > -ϵ) || (A1 < ϵ && A2 < ϵ && A3 < ϵ)
end


### Mapping mesh vertex indices to Vector{Polygon} index
########################################

function vertexindex2poly(polys, idx)
    counter = 0
    for i in eachindex(polys)
        step = ncoords(polys[i])
        if idx <= counter + step
            return i
        else
            counter += step
        end
    end
    return length(polys)
end

ncoords(x) = length(coordinates(x))
ncoords(mesh::Mesh) = length(coordinates(mesh))
function ncoords(poly::Polygon)
    N = length(poly.exterior) + 1
    for int in poly.interiors
        N += length(int) + 1
    end
    return N
end

## Band Sections
########################################

"""
    point_in_quad_parameter(A, B, C, D, P[; iterations = 20, epsilon = 1e-6])

Given a quad

```
   A --- B
  /       \\
 /    __-- C
D -'''
```

this computes parameter `f` such that the line from `A + f * (B - A)` to
`D + f * (C - D)` crosses through the given point `P`. This assumes that `P` is
inside the quad and that none of the edges cross.
"""
function point_in_quad_parameter(
        A::Point2, B::Point2, C::Point2, D::Point2, P::Point2;
        iterations = 50, epsilon = 1.0e-6
    )

    # Our initial guess is that P is in the center of the quad (in terms of AB and DC)
    f = 0.5
    AB = B - A
    DC = C - D
    for _ in 0:iterations
        # vector between top and bottom point of the current line
        dir = (D + f * (C - D)) - (A + f * (B - A))
        # solves P + _ * dir = A + f1 * (B - A) (intersection point of ray & line)
        f1, _ = inv(Mat2f(AB..., dir...)) * (P - A)
        f2, _ = inv(Mat2f(DC..., dir...)) * (P - D)

        # next fraction estimate should be between f1 and f2
        # adding 2f to this helps avoid jumping between low and high values
        old_f = f
        f = 0.25 * (2f + f1 + f2)
        if abs(old_f - f) < epsilon
            return f
        end
    end

    return f
end


## Shifted projection
########################################

@deprecate shift_project(scene, plot, pos) shift_project(scene, pos) false

function shift_project(scene, pos)
    return project(
        camera(scene).projectionview[],
        Vec2f(size(scene)),
        f32_convert(scene, pos),
    ) .+ Vec2f(origin(viewport(scene)[]))
end


################################################################################
### Interactive selection via DataInspector
################################################################################


# TODO destructor?
mutable struct DataInspector
    root::Scene
    attributes::Attributes
    cached_plots::Dict{Tuple{Scene, Type}, Plot}
    temp_plots::Vector{Plot}
    plot::Tooltip
    selection::Plot

    obsfuncs::Vector{Any}
    hover_channel::Channel{Nothing}
end


function DataInspector(scene::Scene, plot::AbstractPlot, attributes)
    return DataInspector(scene, attributes, Dict{UInt64, Plot}(), Plot[], plot, plot, Any[], Channel{Nothing}())
end

function cleanup(inspector::DataInspector)
    foreach(off, inspector.obsfuncs)
    empty!(inspector.obsfuncs)
    delete!(inspector.root, inspector.plot)
    clear_temporary_plots!(inspector, inspector.selection)
    close(inspector.hover_channel)
    inspector.root.data_inspector = nothing
    return inspector
end

function Base.delete!(::Union{Scene, Figure}, inspector::DataInspector)
    return cleanup(inspector)
end

enable!(inspector::DataInspector) = inspector.attributes.enabled[] = true
disable!(inspector::DataInspector) = inspector.attributes.enabled[] = false

"""
    DataInspector(figure_axis_or_scene = current_figure(); kwargs...)

Creates a data inspector which will show relevant information in a tooltip
when you hover over a plot.

This functionality can be disabled on a per-plot basis by setting
`plot.inspectable[] = false`. The displayed text can be adjusted by setting
`plot.inspector_label` to a function `(plot, index, position) -> "my_label"`
returning a label. See Makie documentation for more detail.

### Keyword Arguments:
- `range = 10`: Controls the snapping range for selecting an element of a plot.
- `priority = 100`: The priority of creating a tooltip on a mouse movement or
    scrolling event.
- `enabled = true`: Disables inspection of plots when set to false. Can also be
    adjusted with `enable!(inspector)` and `disable!(inspector)`.
- `indicator_color = :red`: Color of the selection indicator.
- `indicator_linewidth = 2`: Linewidth of the selection indicator.
- `indicator_linestyle = nothing`: Linestyle of the selection indicator
- `enable_indicators = true`: Enables or disables indicators
- `depth = 9e3`: Depth value of the tooltip. This should be high so that the
    tooltip is always in front.
- `apply_tooltip_offset = true`: Enables or disables offsetting tooltips based
    on, for example, markersize.
- and all attributes from `Tooltip`
"""
function DataInspector(fig_or_block; kwargs...)
    return DataInspector(get_scene(fig_or_block); kwargs...)
end

function DataInspector(scene::Scene; priority = 100, blocking = false, kwargs...)
    parent = root(scene)
    if !isnothing(parent.data_inspector)
        return parent.data_inspector
    end
    @assert origin(viewport(parent)[]) == Vec2f(0)

    attrib_dict = Dict(kwargs)
    base_attrib = Attributes(
        # General DataInspector settings
        range = pop!(attrib_dict, :range, 10),
        enabled = pop!(attrib_dict, :enabled, true),
        depth = pop!(attrib_dict, :depth, 9.0e3),
        enable_indicators = pop!(attrib_dict, :show_bbox_indicators, true),
        offset = get(attrib_dict, :offset, 10.0f0),
        apply_tooltip_offset = pop!(attrib_dict, :apply_tooltip_offset, true),

        # Settings for indicators (plots that highlight the current selection)
        indicator_color = pop!(attrib_dict, :indicator_color, :red),
        indicator_linewidth = pop!(attrib_dict, :indicator_linewidth, 2),
        indicator_linestyle = pop!(attrib_dict, :indicator_linestyle, nothing),

        # Reusable values for creating indicators
        indicator_visible = false,

        # General reusable
        _color = RGBAf(0, 0, 0, 0),
    )

    plot = tooltip!(parent, Observable(Point2f(0)), text = Observable(""); visible = false, attrib_dict...)
    on(z -> translate!(plot, 0, 0, z), base_attrib.depth)
    notify(base_attrib.depth)

    inspector = DataInspector(parent, plot, base_attrib)
    parent.data_inspector = inspector
    e = events(parent)
    # We delegate the hover processing to another channel,
    # So that we can skip queued up updates with empty_channel!
    # And also not slow down the processing of e.mouseposition/e.scroll
    channel = Channel{Nothing}(blocking ? 0 : Inf) do ch
        while isopen(ch)
            take!(ch) # wait for event
            if isopen(parent)
                on_hover(inspector)
            end
        end
    end
    inspector.hover_channel = channel
    listeners = onany(e.mouseposition, e.scroll) do _, _
        empty_channel!(channel) # remove queued up hover requests
        put!(channel, nothing)
    end
    append!(inspector.obsfuncs, listeners)
    on(base_attrib.enable_indicators) do enabled
        if !enabled
            yield()
            clear_temporary_plots!(inspector, inspector.plot)
        end
        return
    end

    return inspector
end

DataInspector(; kwargs...) = DataInspector(current_figure(); kwargs...)

function on_hover(inspector)
    parent = inspector.root
    (inspector.attributes.enabled[] && is_mouseinside(parent)) || return Consume(false)

    mp = mouseposition_px(parent)
    should_clear = true
    for (plt, idx) in pick_sorted(parent, mp, inspector.attributes.range[])
        if to_value(get(plt, :inspectable, true))
            # show_data should return true if it created a tooltip
            if show_data_recursion(inspector, plt, idx)
                should_clear = false
                break
            end
        end
    end

    if should_clear
        inspector.plot.visible[] = false
        clear_temporary_plots!(inspector, inspector.plot)
    end

    return Consume(false)
end


function show_data_recursion(inspector, plot, idx)
    processed = show_data_recursion(inspector, plot.parent, idx, plot)
    if processed
        return true
    else
        # Some show_data methods use the current selection to tell whether the
        # temporary plots (indicator plots) are theirs or not, so we want to
        # reset after processing them. We also don't want to reset when the
        processed = if to_value(get(plot, :inspector_hover, automatic)) == automatic
            show_data(inspector, plot, idx)
        else
            plot[:inspector_hover][](inspector, plot, idx)
        end

        if processed && inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
        end

        return processed
    end
end
show_data_recursion(inspector, plot, idx, source) = false
function show_data_recursion(inspector, plot::AbstractPlot, idx, source)
    processed = show_data_recursion(inspector, plot.parent, idx, source)
    if processed
        return true
    else
        # Some show_data methods use the current selection to tell whether the
        # temporary plots (indicator plots) are theirs or not, so we want to
        # reset after processing them. We also don't want to reset when the
        processed = if to_value(get(plot, :inspector_hover, automatic)) == automatic
            show_data(inspector, plot, idx, source)
        else
            plot[:inspector_hover][](inspector, plot, idx, source)
        end

        if processed && inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
        end

        return processed
    end
end

# clears temporary plots (i.e. bboxes) and update selection
function clear_temporary_plots!(inspector::DataInspector, plot)
    inspector.attributes.indicator_visible[] = false
    foreach(p -> p.visible[] = false, values(inspector.cached_plots))

    if inspector.selection !== plot
        if to_value(get(inspector.selection, :inspector_clear, automatic)) !== automatic
            inspector.selection[:inspector_clear][](inspector, inspector.selection)
        end
        inspector.selection = plot
    end

    for i in length(inspector.obsfuncs):-1:3
        off(pop!(inspector.obsfuncs))
    end

    for p in inspector.temp_plots
        delete!(parent_scene(p), p)
    end

    # clear attributes which are reused for indicator plots
    for key in (
            :indicator_color, :indicator_linestyle,
            :indicator_linewidth, :indicator_visible,
        )
        empty!(inspector.attributes[key].listeners)
    end

    empty!(inspector.temp_plots)
    return
end

function get_indicator_plot(inspector, scene, PlotType)
    return get!(inspector.cached_plots, (scene, PlotType)) do
        # Band-aid for LScene where a new plot triggers re-centering of the scene
        cc = cameracontrols(scene)
        if cc isa Camera3D
            eyeposition = cc.eyeposition[]
            lookat = cc.lookat[]
            upvector = cc.upvector[]
        end

        plot = construct_indicator_plot(scene, PlotType, inspector.attributes)

        # Compat: cached plots need to become invisible when indicator_visible
        # turns false, but not visible when it turns true as that would turn
        # every cached plot visible.
        on(plot, inspector.attributes.indicator_visible) do vis
            plot.visible = ifelse(vis, plot.visible[], false)
        end

        # Restore camera
        cc isa Camera3D && update_cam!(scene, eyeposition, lookat, upvector)

        return plot
    end
end

function construct_indicator_plot(scene, ::Type{<:LineSegments}, a)
    return linesegments!(
        scene, Point3f[], transformation = Transformation(), color = a.indicator_color,
        linewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
        visible = false, inspectable = false, depth_shift = -1.0f-6
    )
end

function construct_indicator_plot(scene, ::Type{<:Lines}, a)
    return lines!(
        scene, Point3f[], transformation = Transformation(), color = a.indicator_color,
        linewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
        visible = false, inspectable = false, depth_shift = -1.0f-6
    )
end

function construct_indicator_plot(scene, ::Type{<:Scatter}, a)
    return scatter!(
        scene, Point3d(0), color = RGBAf(0, 0, 0, 0),
        marker = Rect, markersize = map((r, w) -> 2r - 2 - w, a.range, a.indicator_linewidth),
        strokecolor = a.indicator_color,
        strokewidth = a.indicator_linewidth,
        inspectable = false, visible = false,
        depth_shift = -1.0f-6
    )
end

# update alignment direction
function update_tooltip_alignment!(inspector, proj_pos; visible = true, offset = inspector.attributes.offset[], kwargs...)
    wx, wy = widths(viewport(inspector.root)[])
    px, py = proj_pos

    placement = py < 0.75wy ? (:above) : (:below)
    px < 0.25wx && (placement = :right)
    px > 0.75wx && (placement = :left)
    update!(inspector.plot; arg1 = proj_pos, placement, visible, offset, kwargs...)
    return
end


################################################################################
### show_data for primitive plots
################################################################################


# TODO: better 3D scaling
function show_data(inspector::DataInspector, plot::Scatter, idx)
    a = inspector.attributes
    scene = parent_scene(plot)

    pos = position_on_plot(plot, idx, apply_transform = false)
    proj_pos = shift_project(scene, apply_transform_and_model(plot, pos))

    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        position2string(pos)
    else
        plot[:inspector_label][](plot, idx, pos)
    end
    offset = ifelse(
        a.apply_tooltip_offset[],
        0.5 * maximum(sv_getindex(plot.markersize[], idx)) + 2,
        a.offset[]
    )
    update_tooltip_alignment!(inspector, proj_pos; text, offset)
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end


function show_data(inspector::DataInspector, plot::MeshScatter, idx)
    a = inspector.attributes
    scene = parent_scene(plot)

    if a.enable_indicators[]
        # Compat with temp_plots
        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
        end
        a.indicator_visible[] = true

        translation = apply_transform_and_model(plot, plot[1][][idx])
        rotation = to_rotation(_to_rotation(plot.rotation[], idx))
        scale = inv_f32_scale(plot, _to_scale(plot.markersize[], idx))

        bbox = Rect3d(
            convert_attribute(
                plot.marker[], Key{:marker}(), Key{Makie.plotkey(plot)}()
            )
        )

        ps = convert_arguments(LineSegments, bbox)[1]
        ps = map(ps) do p
            p3d = to_ndim(Point3d, p, 0)
            return rotation * (scale .* p3d) + translation
        end

        # Cached
        indicator = get_indicator_plot(inspector, scene, LineSegments)
        update!(indicator, arg1 = ps, visible = true)
    end

    pos = position_on_plot(plot, idx, apply_transform = false)
    proj_pos = shift_project(scene, apply_transform_and_model(plot, pos))
    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        position2string(pos)
    else
        plot[:inspector_label][](plot, idx, pos)
    end
    update_tooltip_alignment!(inspector, proj_pos; text)

    return true
end


function show_data(inspector::DataInspector, plot::Union{Lines, LineSegments}, idx)
    a = inspector.attributes
    scene = parent_scene(plot)

    # cast ray from cursor into screen, find closest point to line
    pos = position_on_plot(plot, idx, apply_transform = false)
    proj_pos = shift_project(scene, apply_transform_and_model(plot, pos))

    offset = ifelse(
        a.apply_tooltip_offset[],
        sv_getindex(plot.linewidth[], idx) + 2,
        a.offset[]
    )
    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        position2string(eltype(plot[1][])(pos))
    else
        plot[:inspector_label][](plot, idx, eltype(plot[1][])(pos))
    end
    update_tooltip_alignment!(inspector, proj_pos; text, offset)
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end


function show_data(inspector::DataInspector, plot::Mesh, idx)
    a = inspector.attributes
    scene = parent_scene(plot)

    bbox = boundingbox(plot)
    proj_pos = Point2f(mouseposition_px(inspector.root))

    if a.enable_indicators[]
        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
        end
        a.indicator_visible[] = true

        # Cached
        indicator = get_indicator_plot(inspector, scene, LineSegments)
        update!(indicator, arg1 = convert_arguments(LineSegments, bbox)[1], visible = true)
    end

    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        bbox2string(bbox)
    else
        plot[:inspector_label][](plot, idx, bbox)
    end
    update_tooltip_alignment!(inspector, proj_pos; text)

    return true
end


function show_data(inspector::DataInspector, plot::Surface, idx)
    a = inspector.attributes
    tt = inspector.plot

    proj_pos = Point2f(mouseposition_px(inspector.root))

    pos = position_on_plot(plot, idx, apply_transform = false)

    if !isnan(pos)
        text = if to_value(get(plot, :inspector_label, automatic)) == automatic
            position2string(pos)
        else
            plot[:inspector_label][](plot, idx, pos)
        end
        update_tooltip_alignment!(inspector, proj_pos; text, offset = 0)
    else
        update!(tt, visible = false)
    end
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end

function show_data(inspector::DataInspector, plot::Heatmap, idx)
    return show_imagelike(inspector, plot, "H", idx, true)
end

function show_data(inspector::DataInspector, plot::Image, idx)
    return show_imagelike(inspector, plot, "img", idx, false)
end

_to_array(x::AbstractArray) = x
_to_array(x::Resampler) = x.data


function show_imagelike(inspector, plot, name, idx, edge_based, interpolate = plot.interpolate[], zrange = _to_array(plot[3][]))
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    pos = position_on_plot(plot, -1, apply_transform = false)[Vec(1, 2)] # index irrelevant
    xrange = plot[1][]
    yrange = plot[2][]

    # Not on image/heatmap
    if isnan(pos)
        a.indicator_visible[] = false
        update!(tt, visible = false)
        return true
    end

    if interpolate || isnothing(idx)
        i, j, z = _interpolated_getindex(xrange, yrange, zrange, pos)
        x, y = pos
    else
        Nx = size(zrange, 1)
        y, x = j, i = fldmod1(idx, Nx)
        z = zrange[i, j]
    end

    # in case we hover over NaN values
    if isnan(z) && alpha(to_color(to_value(plot.nan_color))) <= 0.0
        a.indicator_visible[] = false
        update!(tt, visible = false)
        return true
    end

    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        color2text(name, x, y, z)
    else
        ins_p = z isa Colorant ? (pos[1], pos[2], z) : Point3f(pos[1], pos[2], z)
        plot[:inspector_label][](plot, (i, j), ins_p)
    end

    proj_pos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos; text)

    if a.enable_indicators[]
        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
        end
        a.indicator_visible[] = true

        if interpolate
            # Cached
            indicator = get_indicator_plot(inspector, scene, Scatter)
            color = if z isa Real
                if haskey(plot, :alpha_colormap)
                    sample_color(
                        plot.alpha_colormap[], z, plot.scaled_colorrange[],
                        plot.lowclip_color[], plot.highclip_color[],
                        plot.nan_color[]
                    )
                else
                    to_color(:transparent)
                end
            else
                to_color(z)
            end::RGBAf
            update!(indicator; arg1 = apply_transform_and_model(plot, pos), color, visible = true)
        else
            bbox = _pixelated_image_bbox(xrange, yrange, zrange, round(Int, i), round(Int, j), edge_based)
            ps = apply_transform_and_model(plot, convert_arguments(Lines, bbox)[1])

            # Cached
            indicator = get_indicator_plot(inspector, scene, Lines)
            update!(indicator, arg1 = ps, visible = true)
        end
    end

    return true
end


function _interpolated_getindex(xs, ys, img, mpos)
    x0, x1 = extrema(xs)
    y0, y1 = extrema(ys)
    x, y = clamp.(mpos, (x0, y0), (x1, y1))

    i = clamp((x - x0) / (x1 - x0) * size(img, 1) + 0.5, 1, size(img, 1))
    j = clamp((y - y0) / (y1 - y0) * size(img, 2) + 0.5, 1, size(img, 2))
    l = clamp(floor(Int, i), 1, size(img, 1) - 1)
    r = clamp(l + 1, 2, size(img, 1))
    b = clamp(floor(Int, j), 1, size(img, 2) - 1)
    t = clamp(b + 1, 2, size(img, 2))
    z = ((r - i) * img[l, b] + (i - l) * img[r, b]) * (t - j) +
        ((r - i) * img[l, t] + (i - l) * img[r, t]) * (j - b)

    # float, float, value (i, j are no longer used)
    return i, j, z
end
function _pixelated_getindex(xs, ys, img, mpos, edge_based)
    x0, x1 = extrema(xs)
    y0, y1 = extrema(ys)
    x, y = clamp.(mpos, (x0, y0), (x1, y1))

    i = clamp(round(Int, (x - x0) / (x1 - x0) * size(img, 1) + 0.5), 1, size(img, 1))
    j = clamp(round(Int, (y - y0) / (y1 - y0) * size(img, 2) + 0.5), 1, size(img, 2))

    # int, int, value
    return i, j, img[i, j]
end

function _interpolated_getindex(xs::Vector, ys::Vector, img, mpos)
    # x, y = mpos
    # i, j, _ = _pixelated_getindex(xs, ys, img, mpos, false)
    # w = (xs[i+1] - xs[i]); h = (ys[j+1] - ys[j])
    # z = ((xs[i+1] - x) / w * img[i, j]   + (x - xs[i]) / w * img[i+1, j])   * (ys[j+1] - y) / h +
    #     ((xs[i+1] - x) / w * img[i, j+1] + (x - xs[i]) / w * img[i+1, j+1]) * (y - ys[j]) / h
    # return i, j, z
    return _interpolated_getindex(minimum(xs) .. maximum(xs), minimum(ys) .. maximum(ys), img, mpos)
end
function _pixelated_getindex(xs::Vector, ys::Vector, img, mpos, edge_based)
    if edge_based
        x, y = mpos
        i = max(1, something(findfirst(v -> v >= x, xs), length(xs)) - 1)
        j = max(1, something(findfirst(v -> v >= y, ys), length(ys)) - 1)
        return i, j, img[i, j]
    else
        _pixelated_getindex(minimum(xs) .. maximum(xs), minimum(ys) .. maximum(ys), img, mpos, edge_based)
    end
end

function _pixelated_image_bbox(xs, ys, img, i::Integer, j::Integer, edge_based)
    x0, x1 = extrema(xs)
    y0, y1 = extrema(ys)
    nw, nh = ((x1 - x0), (y1 - y0)) ./ size(img)
    return Rect2d(x0 + nw * (i - 1), y0 + nh * (j - 1), nw, nh)
end
function _pixelated_image_bbox(xs::Vector, ys::Vector, img, i::Integer, j::Integer, edge_based)
    return if edge_based
        Rect2d(xs[i], ys[j], xs[i + 1] - xs[i], ys[j + 1] - ys[j])
    else
        _pixelated_image_bbox(
            minimum(xs) .. maximum(xs), minimum(ys) .. maximum(ys),
            img, i, j, edge_based
        )
    end
end

function show_data(inspector::DataInspector, plot, idx, source = nothing)
    return false
end


################################################################################
### show_data for Plot/recipe plots
################################################################################


function show_data(inspector::DataInspector, plot::BarPlot, idx, ::Lines)
    return show_data(inspector, plot, div(idx - 1, 6) + 1)
end

function show_data(inspector::DataInspector, plot::BarPlot, idx, ::Mesh)
    return show_data(inspector, plot, div(idx - 1, 4) + 1)
end


function show_data(inspector::DataInspector, plot::BarPlot, idx)
    a = inspector.attributes
    scene = parent_scene(plot)

    proj_pos = Point2f(mouseposition_px(inspector.root))

    if a.enable_indicators[]
        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
        end
        a.indicator_visible[] = true

        bbox = plot.plots[1][1][][idx]
        ps = apply_transform_and_model(plot, convert_arguments(Lines, bbox)[1])

        indicator = get_indicator_plot(inspector, scene, Lines)
        update!(indicator, arg1 = ps, visible = true)
    end

    # We pass the input space position to user defined
    # functions to keep the user from dealing with
    # log space scaling in their function.
    pos = plot[1][][idx] # input space position/data
    if plot.direction[] === :x
        pos = reverse(pos)
    end
    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        position2string(pos)
    else
        plot[:inspector_label][](plot, idx, pos)
    end
    update_tooltip_alignment!(inspector, proj_pos; text)

    return true
end

function show_data(inspector::DataInspector, plot::Arrows3D, idx, source)
    a = inspector.attributes
    pos = plot[1][][idx]

    mpos = Point2f(mouseposition_px(inspector.root))

    p = vec2string(pos)
    v = vec2string(plot[2][][idx])

    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        second = plot.argmode[] in (:direction, :directions) ? "Direction" : "Endpoint"
        "Position:\n  $p\n$second:\n  $v"
    else
        plot[:inspector_label][](plot, idx, pos)
    end
    update_tooltip_alignment!(inspector, mpos; text)
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end

function show_data(inspector::DataInspector, plot::Arrows2D, _idx, source)
    a = inspector.attributes

    # number of vertices per arrow
    N = plot.taillength[] > 0 && plot.tailwidth[] > 0 ? length(coordinates(plot.tail[])) : 0
    N += plot.shaftwidth[] > 0 ? length(coordinates(plot.shaft[])) : 0
    N += plot.tiplength[] > 0 && plot.tipwidth[] > 0 ? length(coordinates(plot.tip[])) : 0
    @assert N != 0

    # arrow index
    idx = fld1(_idx, N)

    pos = plot[1][][idx]

    mpos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, mpos)

    p = vec2string(pos)
    v = vec2string(plot[2][][idx])

    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        second = plot.argmode[] in (:direction, :directions) ? "Direction" : "Endpoint"
        "Position:\n  $p\n$second:\n  $v"
    else
        plot[:inspector_label][](plot, idx, pos)
    end
    update_tooltip_alignment!(inspector, mpos; text)
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end

# This should work if contourf would place computed levels in colors and let the
# backend handle picking colors from a colormap
function show_data(inspector::DataInspector, plot::Contourf, idx, source::Mesh)
    idx = show_poly(inspector, plot, plot.plots[1], idx, source)
    level = plot.plots[1].color[][idx]

    mpos = Point2f(mouseposition_px(inspector.root))
    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        @sprintf("level = %0.3f", level)
    else
        plot[:inspector_label][](plot, idx, mpos)
    end
    update_tooltip_alignment!(inspector, mpos; text)

    return true
end

# What should this display?
# function show_data(
#         inspector::DataInspector, plot::Poly{<: Tuple{<: AbstractVector}},
#         idx, source::Mesh
#     )
#     @info "PolyMesh"
#     idx, ext = show_poly(inspectable, plot, idx, source)
#     return true
# end

function show_poly(inspector, plot, poly, idx, source)
    a = inspector.attributes
    idx = vertexindex2poly(poly[1][], idx)

    if a.enable_indicators[]
        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
        end
        a.indicator_visible[] = true

        line_collection = copy(convert_arguments(PointBased(), poly[1][][idx].exterior)[1])
        for int in poly[1][][idx].interiors
            push!(line_collection, Point2f(NaN))
            append!(line_collection, convert_arguments(PointBased(), int)[1])
        end

        scene = parent_scene(plot)
        ps = apply_transform_and_model(source, line_collection)

        # Cached
        indicator = get_indicator_plot(inspector, scene, Lines)
        update!(indicator, arg1 = ps, visible = true)
    end

    return idx
end

function show_data(inspector::DataInspector, plot::VolumeSlices, idx, child::Heatmap)
    a = inspector.attributes
    tt = inspector.plot

    pos = position_on_plot(child, -1, apply_transform = false)[Vec(1, 2)] # index irrelevant

    # Not on heatmap
    if isnan(pos)
        a.indicator_visible[] && (a.indicator_visible[] = false)
        update!(tt, visible = false)
        return true
    end

    zrange = child[3][]
    Nx = size(zrange, 1)
    j, i = fldmod1(idx, Nx)
    val = zrange[i, j]

    proj_pos = Point2f(mouseposition_px(inspector.root))
    world_pos = apply_transform_and_model(child, pos)

    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        @sprintf(
            "x: %0.6f\ny: %0.6f\nz: %0.6f\n%0.6f0",
            world_pos[1], world_pos[2], world_pos[3], val
        )
    else
        plot[:inspector_label][](plot, (i, j), world_pos)
    end

    update_tooltip_alignment!(inspector, proj_pos; text)
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end


function show_data(inspector::DataInspector, plot::Band, idx::Integer, mesh::Mesh)
    scene = parent_scene(plot)
    tt = inspector.plot
    a = inspector.attributes

    pos = Point2f(position_on_plot(mesh, idx, apply_transform = false)) #Point2f(mouseposition(scene))
    ps1 = plot.converted[][1]
    ps2 = plot.converted[][2]

    # find first triangle containing the cursor position
    idx = findfirst(1:(length(ps1) - 1)) do i
        point_in_triangle(ps1[i], ps1[i + 1], ps2[i + 1], pos) ||
            point_in_triangle(ps1[i], ps2[i + 1], ps2[i], pos)
    end

    if idx !== nothing
        # (idx, idx+1) picks the quad that contains the cursor position
        # Within the quad we can draw a line from ps1[idx] + f * (ps1[idx+1] - ps1[idx])
        # to ps2[idx] + f * (ps2[idx+1] - ps2[idx]) which crosses through the
        # cursor position. Find the parameter f that describes this line
        f = point_in_quad_parameter(ps1[idx], ps1[idx + 1], ps2[idx + 1], ps2[idx], pos)
        P1 = ps1[idx] + f * (ps1[idx + 1] - ps1[idx])
        P2 = ps2[idx] + f * (ps2[idx + 1] - ps2[idx])

        # Draw the line
        if a.enable_indicators[]
            a.indicator_visible[] = true
            if inspector.selection != plot
                clear_temporary_plots!(inspector, plot)
            end

            # Cached
            indicator = get_indicator_plot(inspector, scene, LineSegments)
            update!(indicator, arg1 = apply_transform_and_model(plot, [P1, P2]), visible = true)
        end

        # Update tooltip

        text = if to_value(get(plot, :inspector_label, automatic)) == automatic
            P1 = apply_transform_and_model(mesh, P1, Point2f)
            P2 = apply_transform_and_model(mesh, P2, Point2f)
            @sprintf("(%0.3f, %0.3f) .. (%0.3f, %0.3f)", P1[1], P1[2], P2[1], P2[2])
        else
            plot[:inspector_label][](plot, right, (P1, P2))
        end
        update_tooltip_alignment!(inspector, mouseposition_px(inspector.root); text)
    else
        # to simplify things we discard any positions outside the band
        # (likely doesn't work with parameter search)
        update!(tt, visible = false)
        a.indicator_visible[] = false
    end

    return true
end

function show_data(inspector::DataInspector, spy::Spy, idx, picked_plot)
    scatter = spy.plots[1]
    if picked_plot != scatter
        # we only pick the scatter subplot
        return false
    end
    a = inspector.attributes
    proj_pos = Point2f(mouseposition_px(inspector.root))
    idx2d = spy.index_map[][idx]
    text = if to_value(get(scatter, :inspector_label, automatic)) == automatic
        z = spy.z[][idx2d...]
        color2text("S", idx2d..., z)
    else
        scatter.inspector_label[](spy, idx2d, spy.z[][idx2d...])
    end
    offset = ifelse(
        a.apply_tooltip_offset[],
        0.5 * maximum(sv_getindex(scatter.markersize[], idx)) + 2,
        a.offset[]
    )
    update_tooltip_alignment!(inspector, proj_pos; text, offset)
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end


function show_data(inspector::DataInspector, hs::HeatmapShader, idx, pp::Image)
    # Simply force the hs recipe to be treated like a heatmap plot
    # Indices get ignored anyways, since they're calculated from the mouse position + xrange/yrange of the heatmap
    # If we don't overwrite this here, show_data will get called on `pp`, which will use the small resampled version
    return show_data(inspector, hs, nothing)
end


function show_data(inspector::DataInspector, hs::DataShader, idx, pp::Image)
    data = reshape(hs.canvas[].pixelbuffer, hs.canvas[].resolution)
    return show_imagelike(inspector, pp, "C", idx, false, false, data)
end
