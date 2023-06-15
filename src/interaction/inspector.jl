### indicator data -> string
########################################

vec2string(p::StaticVector{2}) = @sprintf("(%0.3f, %0.3f)", p[1], p[2])
vec2string(p::StaticVector{3}) = @sprintf("(%0.3f, %0.3f, %0.3f)", p[1], p[2], p[3])

position2string(p::StaticVector{2}) = @sprintf("x: %0.6f\ny: %0.6f", p[1], p[2])
position2string(p::StaticVector{3}) = @sprintf("x: %0.6f\ny: %0.6f\nz: %0.6f", p[1], p[2], p[3])

function bbox2string(bbox::Rect3)
    p0 = origin(bbox)
    p1 = p0 .+ widths(bbox)
    @sprintf(
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
    @sprintf(
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
    if c.alpha == 1.0
        @sprintf("RGB(%0.2f, %0.2f, %0.2f)", c.r, c.g, c.b)
    else
        @sprintf("RGBA(%0.2f, %0.2f, %0.2f, %0.2f)", c.r, c.g, c.b, c.alpha)
    end
end

color2text(name, i::Integer, j::Integer, c) = "$name[$i, $j] = $(color2text(c))"
function color2text(name, i, j, c)
    idxs = @sprintf("%0.2f, %0.2f", i, j)
    "$name[$idxs] = $(color2text(c))"
end


### dealing with markersize and rotations
########################################

_to_scale(f::AbstractFloat, idx) = Vec3f(f)
_to_scale(v::Vec2f, idx) = Vec3f(v[1], v[2], 1)
_to_scale(v::Vec3f, idx) = v
_to_scale(v::Vector, idx) = _to_scale(v[idx], idx)

_to_rotation(x, idx) = to_rotation(x)
_to_rotation(x::Vector, idx) = to_rotation(x[idx])


### Selecting a point on a nearby line
########################################

function closest_point_on_line(A::Point2f, B::Point2f, P::Point2f)
    # This only works in 2D
    AP = P .- A; AB = B .- A
    A .+ AB * dot(AP, AB) / dot(AB, AB)
end

function point_in_triangle(A::Point2, B::Point2, C::Point2, P::Point2, ϵ = 1e-6)
    # adjusted from ray_triangle_intersection
    AO = A .- P
    BO = B .- P
    CO = C .- P
    A1 = 0.5 * (BO[1] * CO[2] - BO[2] * CO[1])
    A2 = 0.5 * (CO[1] * AO[2] - CO[2] * AO[1])
    A3 = 0.5 * (AO[1] * BO[2] - AO[2] * BO[1])

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
    N
end

## Band Sections
########################################

"""
    point_in_quad_parameter(A, B, C, D, P[; iterations = 20, epsilon = 1e-6])

Given a quad

A --- B
|     |
D --- C

this computes parameter `f` such that the line from `A + f * (B - A)` to 
`D + f * (C - D)` crosses through the given point `P`. This assumes that `P` is 
inside the quad and that none of the edges cross.
"""
function point_in_quad_parameter(
        A::Point2, B::Point2, C::Point2, D::Point2, P::Point2; 
        iterations = 50, epsilon = 1e-6
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
    project(
        camera(scene).projectionview[],
        Vec2f(widths(pixelarea(scene)[])),
        pos
    ) .+ Vec2f(origin(pixelarea(scene)[]))
end



################################################################################
### Interactive selection via DataInspector
################################################################################



# TODO destructor?
mutable struct DataInspector
    root::Scene
    attributes::Attributes

    temp_plots::Vector{AbstractPlot}
    plot::Tooltip
    selection::AbstractPlot

    obsfuncs::Vector{Any}
end


function DataInspector(scene::Scene, plot::AbstractPlot, attributes)
    x = DataInspector(scene, attributes, AbstractPlot[], plot, plot, Any[])
    # finalizer(cleanup, x) # doesn't get triggered when this is dereferenced
    x
end

function cleanup(inspector::DataInspector)
    off.(inspector.obsfuncs)
    empty!(inspector.obsfuncs)
    delete!(inspector.root, inspector.plot)
    clear_temporary_plots!(inspector, inspector.slection)
    inspector
end

function Base.delete!(::Union{Scene, Figure}, inspector::DataInspector)
    cleanup(inspector)
end

enable!(inspector::DataInspector) = inspector.attributes.enabled[] = true
disable!(inspector::DataInspector) = inspector.attributes.enabled[] = false

"""
    DataInspector(figure_axis_or_scene = current_figure(); kwargs...)

Creates a data inspector which will show relevant information in a tooltip
when you hover over a plot.

This functionality can eb disabled on a per-plot basis by setting
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
- `enable_indicators = true)`: Enables or disables indicators
- `depth = 9e3`: Depth value of the tooltip. This should be high so that the
    tooltip is always in front.
- `apply_tooltip_offset = true`: Enables or disables offsetting tooltips based 
    on, for example, markersize.
- and all attributes from `Tooltip`
"""
function DataInspector(fig_or_block; kwargs...)
    DataInspector(get_scene(fig_or_block); kwargs...)
end

function DataInspector(scene::Scene; priority = 100, kwargs...)
    parent = root(scene)
    @assert origin(pixelarea(parent)[]) == Vec2f(0)

    attrib_dict = Dict(kwargs)
    base_attrib = Attributes(
        # General DataInspector settings
        range = pop!(attrib_dict, :range, 10),
        enabled = pop!(attrib_dict, :enabled, true),
        depth = pop!(attrib_dict, :depth, 9e3),
        enable_indicators = pop!(attrib_dict, :show_bbox_indicators, true),
        offset = get(attrib_dict, :offset, 10f0),
        apply_tooltip_offset = pop!(attrib_dict, :apply_tooltip_offset, true),

        # Settings for indicators (plots that highlight the current selection)
        indicator_color = pop!(attrib_dict, :indicator_color, :red),
        indicator_linewidth = pop!(attrib_dict, :indicator_linewidth, 2),
        indicator_linestyle = pop!(attrib_dict, :indicator_linestyle, nothing),

        # Reusable values for creating indicators
        indicator_visible = false,

        # General reusable
        _color = RGBAf(0,0,0,0),
    )

    plot = tooltip!(parent, Observable(Point2f(0)), text = Observable(""); visible=false, attrib_dict...)
    on(z -> translate!(plot, 0, 0, z), base_attrib.depth)
    notify(base_attrib.depth)

    inspector = DataInspector(parent, plot, base_attrib)

    e = events(parent)
    f1 = on(_ -> on_hover(inspector), e.mouseposition, priority = priority)
    f2 = on(_ -> on_hover(inspector), e.scroll, priority = priority)

    push!(inspector.obsfuncs, f1, f2)

    on(base_attrib.enable_indicators) do enabled
        if !enabled
            yield()
            clear_temporary_plots!(inspector, inspector.selection)
        end
        return
    end

    inspector
end

DataInspector(; kwargs...) = DataInspector(current_figure(); kwargs...)

function on_hover(inspector)
    parent = inspector.root
    (inspector.attributes.enabled[] && is_mouseinside(parent)) || return Consume(false)

    mp = mouseposition_px(parent)
    should_clear = true
    for (plt, idx) in pick_sorted(parent, mp, inspector.attributes.range[])
        if to_value(get(plt.attributes, :inspectable, true))
            # show_data should return true if it created a tooltip
            if show_data_recursion(inspector, plt, idx)
                should_clear = false
                break
            end
        end
    end

    if should_clear
        plot = inspector.selection
        if haskey(plot, :inspector_clear)
            plot[:inspector_clear][](inspector, plot)
        end
        inspector.plot.visible[] = false
        inspector.attributes.indicator_visible[] = false
        inspector.plot.offset.val = inspector.attributes.offset[]
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
        processed = if haskey(plot, :inspector_hover)
            plot[:inspector_hover][](inspector, plot, idx)
        else
            show_data(inspector, plot, idx)
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
        processed = if haskey(plot, :inspector_hover)
            plot[:inspector_hover][](inspector, plot, idx, source)
        else
            show_data(inspector, plot, idx, source)
        end

        if processed && inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
        end

        return processed
    end
end

# clears temporary plots (i.e. bboxes) and update selection
function clear_temporary_plots!(inspector::DataInspector, plot)
    inspector.selection = plot

    for i in length(inspector.obsfuncs):-1:3
        off(pop!(inspector.obsfuncs))
    end

    for p in inspector.temp_plots
        delete!(parent_scene(p), p)
    end

    # clear attributes which are reused for indicator plots
    for key in (
            :indicator_color, :indicator_linestyle,
            :indicator_linewidth, :indicator_visible
        )
        empty!(inspector.attributes[key].listeners)
    end

    empty!(inspector.temp_plots)
    return
end

# update alignment direction
function update_tooltip_alignment!(inspector, proj_pos)
    inspector.plot[1][] = proj_pos

    wx, wy = widths(pixelarea(inspector.root)[])
    px, py = proj_pos

    placement = py < 0.75wy ? (:above) : (:below)
    px < 0.25wx && (placement = :right)
    px > 0.75wx && (placement = :left)
    inspector.plot.placement[] = placement

    return
end



################################################################################
### show_data for primitive plots
################################################################################



# TODO: better 3D scaling
function show_data(inspector::DataInspector, plot::Scatter, idx)
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    pos = position_on_plot(plot, idx)
    proj_pos = shift_project(scene, pos)
    update_tooltip_alignment!(inspector, proj_pos)

    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, idx, pos)
    else
        tt.text[] = position2string(pos)
    end
    tt.offset[] = ifelse(
        a.apply_tooltip_offset[],
        0.5 * maximum(sv_getindex(plot.markersize[], idx)) + 2,
        a.offset[]
    )
    tt.visible[] = true
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end


function show_data(inspector::DataInspector, plot::MeshScatter, idx)
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    if a.enable_indicators[]
        translation = apply_transform_and_model(plot, plot[1][][idx])
        rotation = _to_rotation(plot.rotations[], idx)
        scale = _to_scale(plot.markersize[], idx)

        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)

            cc = cameracontrols(scene)
            if cc isa Camera3D
                eyeposition = cc.eyeposition[]
                lookat = cc.lookat[]
                upvector = cc.upvector[]
            end

            bbox = Rect{3, Float32}(convert_attribute(
                plot.marker[], Key{:marker}(), Key{Makie.plotkey(plot)}()
            ))
            T = Transformation(
                identity; translation = translation, rotation = rotation, scale = scale
            )

            p = wireframe!(
                scene, bbox, transformation = T, color = a.indicator_color,
                linewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                visible = a.indicator_visible, inspectable = false
            )
            push!(inspector.temp_plots, p)

            # Restore camera
            cc isa Camera3D && update_cam!(scene, eyeposition, lookat, upvector)

        elseif !isempty(inspector.temp_plots)
            p = inspector.temp_plots[1]
            transform!(p, translation = translation, scale = scale, rotation = rotation)
        end


        a.indicator_visible[] = true
    end

    pos = position_on_plot(plot, idx)
    proj_pos = shift_project(scene, pos)
    update_tooltip_alignment!(inspector, proj_pos)

    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, idx, pos)
    else
        tt.text[] = position2string(pos)
    end
    tt.visible[] = true

    return true
end


function show_data(inspector::DataInspector, plot::Union{Lines, LineSegments}, idx)
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    # cast ray from cursor into screen, find closest point to line
    pos = position_on_plot(plot, idx)

    proj_pos = shift_project(scene, pos)
    update_tooltip_alignment!(inspector, proj_pos)

    tt.offset[] = ifelse(
        a.apply_tooltip_offset[], 
        sv_getindex(plot.linewidth[], idx) + 2, 
        a.offset[]
    )

    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, idx, eltype(plot[1][])(pos))
    else
        tt.text[] = position2string(eltype(plot[1][])(pos))
    end
    tt.visible[] = true
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end


function show_data(inspector::DataInspector, plot::Mesh, idx)
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    # Manual boundingbox including transfunc
    bbox = let
        points = point_iterator(plot)
        trans_func = transform_func(plot)
        model = plot.model[]
        iter = iterate_transformed(points, model, to_value(get(plot, :space, :data)), trans_func)
        limits_from_transformed_points(iter)
    end
    proj_pos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos)

    if a.enable_indicators[]
        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)

            cc = cameracontrols(scene)
            if cc isa Camera3D
                eyeposition = cc.eyeposition[]
                lookat = cc.lookat[]
                upvector = cc.upvector[]
            end

            p = wireframe!(
                scene, bbox, color = a.indicator_color, 
                transformation = Transformation(),
                linewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                visible = a.indicator_visible, inspectable = false
            )
            push!(inspector.temp_plots, p)

            # Restore camera
            cc isa Camera3D && update_cam!(scene, eyeposition, lookat, upvector)
        elseif !isempty(inspector.temp_plots)
            p = inspector.temp_plots[1]
            p[1][] = bbox
        end

        a.indicator_visible[] = true
    end

    tt[1][] = proj_pos
    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, idx, bbox)
    else
        tt.text[] = bbox2string(bbox)
    end
    tt.visible[] = true

    return true
end


function show_data(inspector::DataInspector, plot::Surface, idx)
    a = inspector.attributes
    tt = inspector.plot

    proj_pos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos)

    pos = position_on_plot(plot, idx)

    if !isnan(pos)
        tt[1][] = proj_pos
        if haskey(plot, :inspector_label)
            tt.text[] = plot[:inspector_label][](plot, idx, pos)
        else
            tt.text[] = position2string(pos)
        end
        tt.visible[] = true
        tt.offset[] = 0f0
    else
        tt.visible[] = false
    end
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end

function show_data(inspector::DataInspector, plot::Heatmap, idx)
    show_imagelike(inspector, plot, "H", true)
end

function show_data(inspector::DataInspector, plot::Image, idx)
    show_imagelike(inspector, plot, "img", false)
end

function show_imagelike(inspector, plot, name, edge_based)
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    pos = position_on_plot(plot, -1, apply_transform = false)[Vec(1, 2)] # index irrelevant

    # Not on image/heatmap
    if isnan(pos)
        a.indicator_visible[] = false
        tt.visible[] = false
        return true
    end

    if plot.interpolate[]
        i, j, z = _interpolated_getindex(plot[1][], plot[2][], plot[3][], pos)
        x, y = pos
    else
        i, j, z = _pixelated_getindex(plot[1][], plot[2][], plot[3][], pos, edge_based)
        x = i; y = j
    end

    # in case we hover over NaN values
    if isnan(z)
        a.indicator_visible[] = false
        tt.visible[] = false
        return true
    end

    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, (i, j), Point3f(pos[1], pos[2], z))
    else
        tt.text[] = color2text(name, x, y, z)
    end

    a._color[] = if z isa AbstractFloat
        interpolated_getindex(
            to_colormap(plot.colormap[]), z,
            to_value(get(plot.attributes, :colorrange, (0, 1)))
        )
    else
        z
    end

    proj_pos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos)

    if a.enable_indicators[]
        if plot.interpolate[]
            if inspector.selection != plot || (length(inspector.temp_plots) != 1) || 
                    !(inspector.temp_plots[1] isa Scatter)
                clear_temporary_plots!(inspector, plot)
                p = scatter!(
                    scene, pos, color = a._color,
                    visible = a.indicator_visible,
                    inspectable = false, model = plot.model,
                    # TODO switch to Rect with 2r-1 or 2r-2 markersize to have 
                    # just enough space to always detect the underlying image
                    marker=:rect, markersize = map(r -> 2r, a.range), 
                    strokecolor = a.indicator_color,
                    strokewidth = a.indicator_linewidth,
                    depth_shift = -1f-3
                )
                push!(inspector.temp_plots, p)
            else
                p = inspector.temp_plots[1]
                p[1].val[1] = pos
                notify(p[1])
            end
        else
            bbox = _pixelated_image_bbox(plot[1][], plot[2][], plot[3][], i, j, edge_based)
            if inspector.selection != plot || (length(inspector.temp_plots) != 1) || 
                    !(inspector.temp_plots[1] isa Wireframe)
                clear_temporary_plots!(inspector, plot)
                p = wireframe!(
                    scene, bbox, color = a.indicator_color, model = plot.model,
                    strokewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                    visible = a.indicator_visible, inspectable = false,
                    depth_shift = -1f-3
                )
                push!(inspector.temp_plots, p)
            else
                p = inspector.temp_plots[1]
                p[1][] = bbox
            end
        end

        a.indicator_visible[] = true
    end

    tt.visible[] = true
    return true
end


function _interpolated_getindex(xs, ys, img, mpos)
    x0, x1 = extrema(xs)
    y0, y1 = extrema(ys)
    x, y = clamp.(mpos, (x0, y0), (x1, y1))

    i = clamp((x - x0) / (x1 - x0) * size(img, 1) + 0.5, 1, size(img, 1))
    j = clamp((y - y0) / (y1 - y0) * size(img, 2) + 0.5, 1, size(img, 2))
    l = clamp(floor(Int, i), 1, size(img, 1)-1);
    r = clamp(l+1, 2, size(img, 1))
    b = clamp(floor(Int, j), 1, size(img, 2)-1);
    t = clamp(b+1, 2, size(img, 2))
    z = ((r-i) * img[l, b] + (i-l) * img[r, b]) * (t-j) +
        ((r-i) * img[l, t] + (i-l) * img[r, t]) * (j-b)

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
    return i, j, img[i,j]
end

function _interpolated_getindex(xs::Vector, ys::Vector, img, mpos)
    # x, y = mpos
    # i, j, _ = _pixelated_getindex(xs, ys, img, mpos, false)
    # w = (xs[i+1] - xs[i]); h = (ys[j+1] - ys[j])
    # z = ((xs[i+1] - x) / w * img[i, j]   + (x - xs[i]) / w * img[i+1, j])   * (ys[j+1] - y) / h +
    #     ((xs[i+1] - x) / w * img[i, j+1] + (x - xs[i]) / w * img[i+1, j+1]) * (y - ys[j]) / h
    # return i, j, z
    _interpolated_getindex(minimum(xs)..maximum(xs), minimum(ys)..maximum(ys), img, mpos)
end
function _pixelated_getindex(xs::Vector, ys::Vector, img, mpos, edge_based)
    if edge_based
        x, y = mpos
        i = max(1, something(findfirst(v -> v >= x, xs), length(xs))-1)
        j = max(1, something(findfirst(v -> v >= y, ys), length(ys))-1)
        return i, j, img[i, j]
    else
        _pixelated_getindex(minimum(xs)..maximum(xs), minimum(ys)..maximum(ys), img, mpos, edge_based)
    end
end

function _pixelated_image_bbox(xs, ys, img, i::Integer, j::Integer, edge_based)
    x0, x1 = extrema(xs)
    y0, y1 = extrema(ys)
    nw, nh = ((x1 - x0), (y1 - y0)) ./ size(img)
    Rect2f(x0 + nw * (i-1), y0 + nh * (j-1), nw, nh)
end
function _pixelated_image_bbox(xs::Vector, ys::Vector, img, i::Integer, j::Integer, edge_based)
    if edge_based
        Rect2f(xs[i], ys[j], xs[i+1] - xs[i], ys[j+1] - ys[j])
    else
        _pixelated_image_bbox(
            minimum(xs)..maximum(xs), minimum(ys)..maximum(ys),
            img, i, j, edge_based
        )
    end
end

function show_data(inspector::DataInspector, plot, idx, source=nothing)
    return false
end


################################################################################
### show_data for Combined/recipe plots
################################################################################



function show_data(inspector::DataInspector, plot::BarPlot, idx, ::Lines)
    return show_data(inspector, plot, div(idx-1, 6)+1)
end

function show_data(inspector::DataInspector, plot::BarPlot, idx, ::Mesh)
    return show_data(inspector, plot, div(idx-1, 4)+1)
end



function show_data(inspector::DataInspector, plot::BarPlot, idx)
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    pos = apply_transform_and_model(plot, plot[1][][idx])
    proj_pos = shift_project(scene, to_ndim(Point3f, pos, 0))
    update_tooltip_alignment!(inspector, proj_pos)

    if a.enable_indicators[]
        model = plot.model[]
        bbox = plot.plots[1][1][][idx]

        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
            p = wireframe!(
                scene, bbox, model = model, color = a.indicator_color,
                strokewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                visible = a.indicator_visible, inspectable = false
            )
            translate!(p, Vec3f(0, 0, a.depth[]))
            push!(inspector.temp_plots, p)
        elseif !isempty(inspector.temp_plots)
            p = inspector.temp_plots[1]
            p[1][] = bbox
            p.model[] = model
        end

        a.indicator_visible[] = true
    end

    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, idx, pos)
    else
        tt.text[] = position2string(pos)
    end
    tt.visible[] = true

    return true
end

function show_data(inspector::DataInspector, plot::Arrows, idx, ::LineSegments)
    return show_data(inspector, plot, div(idx+1, 2), nothing)
end
function show_data(inspector::DataInspector, plot::Arrows, idx, source)
    a = inspector.attributes
    tt = inspector.plot
    pos = apply_transform_and_model(plot, plot[1][][idx])

    mpos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, mpos)

    p = vec2string(pos)
    v = vec2string(plot[2][][idx])

    tt[1][] = mpos
    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, idx, pos)
    else
        tt.text[] = "Position:\n  $p\nDirection:\n  $v"
    end
    tt.visible[] = true
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end

# This should work if contourf would place computed levels in colors and let the
# backend handle picking colors from a colormap
function show_data(inspector::DataInspector, plot::Contourf, idx, source::Mesh)
    tt = inspector.plot
    idx = show_poly(inspector, plot, plot.plots[1], idx, source)
    level = plot.plots[1].color[][idx]

    mpos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, mpos)
    tt[1][] = mpos
    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, idx, mpos)
    else
        tt.text[] = @sprintf("level = %0.3f", level)
    end
    tt.visible[] = true

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
        line_collection = copy(convert_arguments(PointBased(), poly[1][][idx].exterior)[1])
        for int in poly[1][][idx].interiors
            push!(line_collection, Point2f(NaN))
            append!(line_collection, convert_arguments(PointBased(), int)[1])
        end

        if inspector.selection != plot
            scene = parent_scene(plot)
            clear_temporary_plots!(inspector, plot)

            p = lines!(
                scene, line_collection, color = a.indicator_color, 
                transformation = Transformation(source),
                strokewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                visible = a.indicator_visible, inspectable = false, depth_shift = -1f-3
            )
            push!(inspector.temp_plots, p)

        elseif !isempty(inspector.temp_plots)
            inspector.temp_plots[1][1][] = line_collection
        end

        a.indicator_visible[] = true
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
        tt.visible[] = false
        return true
    end

    i, j, val = _pixelated_getindex(child[1][], child[2][], child[3][], pos, true)

    proj_pos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos)
    tt[1][] = proj_pos
    
    world_pos = apply_transform_and_model(child, pos)

    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, (i, j), world_pos)
    else
        tt.text[] = @sprintf(
            "x: %0.6f\ny: %0.6f\nz: %0.6f\n%0.6f0",
            world_pos[1], world_pos[2], world_pos[3], val
        )
    end

    tt.visible[] = true
    a.indicator_visible[] && (a.indicator_visible[] = false)

    return true
end


function show_data(inspector::DataInspector, plot::Band, idx::Integer, mesh::Mesh)
    scene = parent_scene(plot)
    tt = inspector.plot
    a = inspector.attributes

    pos = Point2f(position_on_plot(mesh, idx, apply_transform = false)) #Point2f(mouseposition(scene))
    ps1 = plot.converted[1][]
    ps2 = plot.converted[2][]

    # find first triangle containing the cursor position
    idx = findfirst(1:length(ps1)-1) do i
        point_in_triangle(ps1[i], ps1[i+1], ps2[i+1], pos) ||
        point_in_triangle(ps1[i], ps2[i+1], ps2[i], pos)
    end

    if idx !== nothing
        # (idx, idx+1) picks the quad that contains the cursor position
        # Within the quad we can draw a line from ps1[idx] + f * (ps1[idx+1] - ps1[idx])
        # to ps2[idx] + f * (ps2[idx+1] - ps2[idx]) which crosses through the
        # cursor position. Find the parameter f that describes this line
        f = point_in_quad_parameter(ps1[idx], ps1[idx+1], ps2[idx+1], ps2[idx], pos)
        P1 = ps1[idx] + f * (ps1[idx+1] - ps1[idx])
        P2 = ps2[idx] + f * (ps2[idx+1] - ps2[idx])

        # Draw the line
        if a.enable_indicators[]
            # Why does this sometimes create 2+ plots
            if inspector.selection != plot || (length(inspector.temp_plots) != 1)
                clear_temporary_plots!(inspector, plot)
                p = lines!(
                    scene, [P1, P2], transformation = Transformation(plot.transformation),
                    color = a.indicator_color, strokewidth = a.indicator_linewidth, 
                    linestyle = a.indicator_linestyle,
                    visible = a.indicator_visible, inspectable = false,
                    depth_shift = -1f-3
                )
                push!(inspector.temp_plots, p)
            elseif !isempty(inspector.temp_plots)
                p = inspector.temp_plots[1]
                p[1][] = [P1, P2]
            end

            a.indicator_visible[] = true
        end

        # Update tooltip
        update_tooltip_alignment!(inspector, mouseposition_px(inspector.root))

        if haskey(plot, :inspector_label)
            tt.text[] = plot[:inspector_label][](plot, right, (P1, P2))
        else
            P1 = apply_transform_and_model(mesh, P1, Point2f)
            P2 = apply_transform_and_model(mesh, P2, Point2f)
            tt.text[] = @sprintf("(%0.3f, %0.3f) .. (%0.3f, %0.3f)", P1[1], P1[2], P2[1], P2[2])
        end
        tt.visible[] = true
    else
        # to simplify things we discard any positions outside the band
        # (likely doesn't work with parameter search)
        tt.visible[] = false
        a.indicator_visible[] = false
    end

    return true
end