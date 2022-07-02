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

function closest_point_on_line(p0::Point2f, p1::Point2f, r::Point2f)
    # This only works in 2D
    AP = P .- A; AB = B .- A
    A .+ AB * dot(AP, AB) / dot(AB, AB)
end

function view_ray(scene)
    inv_projview = inv(camera(scene).projectionview[])
    view_ray(inv_projview, events(scene).mouseposition[], pixelarea(scene)[])
end
function view_ray(inv_view_proj, mpos, area::Rect2)
    # This figures out the camera view direction from the projectionview matrix (?)
    # and computes a ray from a near and a far point.
    # Based on ComputeCameraRay from ImGuizmo
    mp = 2f0 .* (mpos .- minimum(area)) ./ widths(area) .- 1f0
    v = inv_view_proj * Vec4f(0, 0, -10, 1)
    reversed = v[3] < v[4]
    near = reversed ? 1f0 - 1e-6 : 0f0
    far = reversed ? 0f0 : 1f0 - 1e-6

    origin = inv_view_proj * Vec4f(mp[1], mp[2], near, 1f0)
    origin = origin[Vec(1, 2, 3)] ./ origin[4]

    p = inv_view_proj * Vec4f(mp[1], mp[2], far, 1f0)
    p = p[Vec(1, 2, 3)] ./ p[4]

    dir = normalize(p .- origin)
    return origin, dir
end


# These work in 2D and 3D
function closest_point_on_line(A, B, origin, dir)
    closest_point_on_line(
        to_ndim(Point3f, A, 0),
        to_ndim(Point3f, B, 0),
        to_ndim(Point3f, origin, 0),
        to_ndim(Vec3f, dir, 0)
    )
end
function closest_point_on_line(A::Point3f, B::Point3f, origin::Point3f, dir::Vec3f)
    # See:
    # https://en.wikipedia.org/wiki/Line%E2%80%93plane_intersection
    AB_norm = norm(B .- A)
    u_AB = (B .- A) / AB_norm
    u_dir = normalize(dir)
    u_perp = normalize(cross(u_dir, u_AB))
    # e_RD, e_perp defines a plane with normal n
    n = normalize(cross(u_dir, u_perp))
    t = dot(origin .- A, n) / dot(u_AB, n)
    A .+ clamp(t, 0.0, AB_norm) * u_AB
end

function ray_triangle_intersection(A, B, C, origin, dir)
    # See: https://www.iue.tuwien.ac.at/phd/ertl/node114.html
    AO = A .- origin
    BO = B .- origin
    CO = C .- origin
    A1 = 0.5 * dot(cross(BO, CO), dir)
    A2 = 0.5 * dot(cross(CO, AO), dir)
    A3 = 0.5 * dot(cross(AO, BO), dir)

    e = 1e-3
    if (A1 > -e && A2 > -e && A3 > -e) || (A1 < e && A2 < e && A3 < e)
        Point3f((A1 * A .+ A2 * B .+ A3 * C) / (A1 + A2 + A3))
    else
        Point3f(NaN)
    end
end


### Surface positions
########################################

surface_x(xs::ClosedInterval, i, j, N) = minimum(xs) + (maximum(xs) - minimum(xs)) * (i-1) / (N-1)
surface_x(xs, i, j, N) = xs[i]
surface_x(xs::AbstractMatrix, i, j, N) = xs[i, j]

surface_y(ys::ClosedInterval, i, j, N) = minimum(ys) + (maximum(ys) - minimum(ys)) * (j-1) / (N-1)
surface_y(ys, i, j, N) = ys[j]
surface_y(ys::AbstractMatrix, i, j, N) = ys[i, j]

function surface_pos(xs, ys, zs, i, j)
    N, M = size(zs)
    Point3f(surface_x(xs, i, j, N), surface_y(ys, i, j, M), zs[i, j])
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

## Shifted projection
########################################

function shift_project(scene, plot, pos)
    project(
        camera(scene).projectionview[],
        Vec2f(widths(pixelarea(scene)[])),
        apply_transform(transform_func_obs(plot)[], pos)
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
    DataInspector(figure; kwargs...)
    DataInspector()

Creates a data inspector which will show relevant information in a tooltip
when you hover over a plot. If you wish to exclude a plot you may set
`plot.inspectable[] = false`.
Defaults to the current axis when called without arguments.

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
- and all attributes from `Tooltip`
"""
function DataInspector(fig_or_block; kwargs...)
    DataInspector(fig_or_block.scene; kwargs...)
end

function DataInspector(scene::Scene; priority = 100, kwargs...)
    parent = root(scene)
    @assert origin(pixelarea(parent)[]) == Vec2f(0)

    attrib_dict = Dict(kwargs)
    base_attrib = Attributes(
        range = pop!(attrib_dict, :range, 10),
        enabled = pop!(attrib_dict, :enabled, true),
        position = Point3f(0),
        color = RGBAf(0,0,0,0),
        bbox2D = Rect2f(),
        bbox3D = Rect3f(),
        model = Mat4f(I),
        indicator_color = pop!(attrib_dict, :indicator_color, :red),
        indicator_linewidth = pop!(attrib_dict, :indicator_linewidth, 2),
        indicator_linestyle = pop!(attrib_dict, :indicator_linestyle, nothing),
        depth = pop!(attrib_dict, :depth, 9e3),
        indicator_visible = false,
        enable_indicators = pop!(attrib_dict, :show_bbox_indicators, true),
        default_offset = get(attrib_dict, :offset, 10f0),
    )

    plot = tooltip!(parent, Observable(Point2f(0)), text = Observable(""); attrib_dict...)
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
        inspector.plot.visible[] = false
        inspector.attributes.indicator_visible[] = false
        inspector.plot.offset.val = inspector.attributes.default_offset[]
    end

    return Consume(false)
end


function show_data_recursion(inspector, plot, idx)
    processed = show_data_recursion(inspector, plot.parent, idx, plot)
    if processed
        return true
    else
        return show_data(inspector, plot, idx)
    end
end
show_data_recursion(inspector, plot, idx, source) = false
function show_data_recursion(inspector, plot::AbstractPlot, idx, source)
    processed = show_data_recursion(inspector, plot.parent, idx, source)
    if processed
        return true
    else
        return show_data(inspector, plot, idx, source)
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
            :bbox2D, :bbox3D, :color, :indicator_color, :indicator_linestyle,
            :indicator_linewidth, :indicator_visible, :model, :position
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
    tt = inspector.plot
    scene = parent_scene(plot)

    proj_pos = shift_project(scene, plot, to_ndim(Point3f, plot[1][][idx], 0))
    update_tooltip_alignment!(inspector, proj_pos)
    ms = plot.markersize[]

    tt.offset[] = 0.5ms + 2
    tt.text[] = position2string(plot[1][][idx])
    tt.visible[] = true

    return true
end


function show_data(inspector::DataInspector, plot::MeshScatter, idx)
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    if a.enable_indicators[]
        a.model[] = transformationmatrix(
            plot[1][][idx],
            _to_scale(plot.markersize[], idx),
            _to_rotation(plot.rotations[], idx)
        )

        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)

            cc = cameracontrols(scene)
            if cc isa Camera3D
                eyeposition = cc.eyeposition[]
                lookat = cc.lookat[]
                upvector = cc.upvector[]
            end

            a.bbox3D[] = Rect{3, Float32}(convert_attribute(
                plot.marker[], Key{:marker}(), Key{Makie.plotkey(plot)}()
            ))
        
            p = wireframe!(
                scene, a.bbox3D, model = a.model, color = a.indicator_color,
                linewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                visible = a.indicator_visible, inspectable = false
            )
            push!(inspector.temp_plots, p)

            # Restore camera
            cc isa Camera3D && update_cam!(scene, eyeposition, lookat, upvector)
        end

        a.indicator_visible[] = true
    end

    proj_pos = shift_project(scene, plot, to_ndim(Point3f, plot[1][][idx], 0))
    update_tooltip_alignment!(inspector, proj_pos)

    tt.text[] = position2string(plot[1][][idx])
    tt.visible[] = true

    return true
end


function show_data(inspector::DataInspector, plot::Union{Lines, LineSegments}, idx)
    # a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    # cast ray from cursor into screen, find closest point to line
    p0, p1 = plot[1][][idx-1:idx]
    origin, dir = view_ray(scene)
    pos = closest_point_on_line(p0, p1, origin, dir)
    lw = plot.linewidth[] isa Vector ? plot.linewidth[][idx] : plot.linewidth[]

    proj_pos = shift_project(scene, plot, to_ndim(Point3f, pos, 0))
    update_tooltip_alignment!(inspector, proj_pos)

    tt.offset[] = lw + 2
    tt.text[] = position2string(typeof(p0)(pos))
    tt.visible[] = true

    return true
end


function show_data(inspector::DataInspector, plot::Mesh, idx)
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    bbox = boundingbox(plot)
    proj_pos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos)

    if a.enable_indicators[]
        a.bbox3D[] = bbox

        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)

            cc = cameracontrols(scene)
            if cc isa Camera3D
                eyeposition = cc.eyeposition[]
                lookat = cc.lookat[]
                upvector = cc.upvector[]
            end

            p = wireframe!(
                scene, a.bbox3D, color = a.indicator_color,
                linewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                visible = a.indicator_visible, inspectable = false
            )
            push!(inspector.temp_plots, p)

            # Restore camera
            cc isa Camera3D && update_cam!(scene, eyeposition, lookat, upvector)
        end

        a.indicator_visible[] = true
    end
    
    tt[1][] = proj_pos
    tt.text[] = bbox2string(bbox)
    tt.visible[] = true

    return true
end


function show_data(inspector::DataInspector, plot::Surface, idx)
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    proj_pos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos)

    xs = plot[1][]
    ys = plot[2][]
    zs = plot[3][]
    w, h = size(zs)
    _i = mod1(idx, w); _j = div(idx-1, w)

    # This isn't the most accurate so we include some neighboring faces
    origin, dir = view_ray(scene)
    pos = Point3f(NaN)
    for i in _i-1:_i+1, j in _j-1:_j+1
        (1 <= i <= w) && (1 <= j < h) || continue

        if i - 1 > 0
            pos = ray_triangle_intersection(
                surface_pos(xs, ys, zs, i, j),
                surface_pos(xs, ys, zs, i-1, j),
                surface_pos(xs, ys, zs, i, j+1),
                origin, dir
            )
        end

        if i + 1 <= w && isnan(pos)
            pos = ray_triangle_intersection(
                surface_pos(xs, ys, zs, i, j),
                surface_pos(xs, ys, zs, i, j+1),
                surface_pos(xs, ys, zs, i+1, j+1),
                origin, dir
            )
        end

        isnan(pos) || break
    end

    if !isnan(pos)
        tt[1][] = proj_pos
        tt.text[] = position2string(pos)
        a.indicator_visible[] = true
        tt.visible[] = true
        tt.offset[] = 0f0
    else
        a.indicator_visible[] = false
        tt.visible[] = false
    end

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
    mpos = mouseposition(scene)

    i, j, z = if plot.interpolate[]
        _interpolated_getindex(plot[1][], plot[2][], plot[3][], mpos)
    else
        _pixelated_getindex(plot[1][], plot[2][], plot[3][], mpos, edge_based)
    end

    a.color[] = if z isa AbstractFloat
        interpolated_getindex(
            to_colormap(plot.colormap[]), z,
            to_value(get(plot.attributes, :colorrange, (0, 1)))
        )
    else
        z
    end

    a.position[] = to_ndim(Point3f, mpos, 0)
    proj_pos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos)

    if a.enable_indicators[]
        if plot.interpolate[]
            if inspector.selection != plot
                clear_temporary_plots!(inspector, plot)
                p = scatter!(
                    scene, a.position, color = a.color,
                    visible = a.indicator_visible,
                    inspectable = false,
                    marker=:rect, markersize = map(r -> 3r, a.range),
                    strokecolor = a.indicator_color,
                    strokewidth = a.indicator_linewidth
                )
                translate!(p, Vec3f(0, 0, a.depth[]-1))
                push!(inspector.temp_plots, p)
            end
            tt.text[] = color2text(name, mpos[1], mpos[2], z)
        else
            a.bbox2D[] = _pixelated_image_bbox(plot[1][], plot[2][], plot[3][], i, j, edge_based)
            if inspector.selection != plot
                clear_temporary_plots!(inspector, plot)
                p = wireframe!(
                    scene, a.bbox2D, model = a.model, color = a.indicator_color,
                    strokewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                    visible = a.indicator_visible, inspectable = false
                )
                translate!(p, Vec3f(0, 0, a.depth[]-1))
                push!(inspector.temp_plots, p)
            end
            tt.text[] = color2text(name, i, j, z)
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

    pos = plot[1][][idx]
    proj_pos = shift_project(scene, plot, to_ndim(Point3f, pos, 0))
    update_tooltip_alignment!(inspector, proj_pos)

    if a.enable_indicators[]
        a.model[] = plot.model[]
        a.bbox2D[] = plot.plots[1][1][][idx]

        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
            p = wireframe!(
                scene, a.bbox2D, model = a.model, color = a.indicator_color,
                strokewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                visible = a.indicator_visible, inspectable = false
            )
            translate!(p, Vec3f(0, 0, a.depth[]))
            push!(inspector.temp_plots, p)
        end

        a.indicator_visible[] = true
    end

    tt.text[] = position2string(pos)
    tt.visible[] = true

    return true
end

function show_data(inspector::DataInspector, plot::Arrows, idx, ::LineSegments)
    return show_data(inspector, plot, div(idx+1, 2), nothing)
end
function show_data(inspector::DataInspector, plot::Arrows, idx, source)
    # a = inspector.plot.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    pos = plot[1][][idx]
    proj_pos = shift_project(scene, plot, to_ndim(Point3f, pos, 0))

    mpos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, mpos)

    p = vec2string(pos)
    v = vec2string(plot[2][][idx])

    tt[1][] = mpos
    tt.text[] = "Position:\n  $p\nDirection:\n  $v"
    tt.visible[] = true

    return true
end

# This should work if contourf would place computed levels in colors and let the
# backend handle picking colors from a colormap
function show_data(inspector::DataInspector, plot::Contourf, idx, source::Mesh)
    # a = inspector.plot.attributes
    tt = inspector.plot
    scene = parent_scene(plot)
    idx = show_poly(inspector, plot.plots[1], idx, source)
    level = plot.plots[1].color[][idx]

    mpos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, mpos)
    tt[1][] = mpos
    tt.text[] = @sprintf("level = %0.3f", level)
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

function show_poly(inspector, plot, idx, source)
    a = inspector.attributes
    idx = vertexindex2poly(plot[1][], idx)

    if a.enable_indicators[]
        scene = parent_scene(plot)
        ext = convert_arguments(PointBased(), plot[1][][idx].exterior)[1]
        
        # TODO: This leaves behind extra indicators if the mouse is moved quickly
        if !a.indicator_visible[] || isempty(inspector.temp_plots) || (ext != inspector.temp_plots[1][1][])
            clear_temporary_plots!(inspector, plot)

            p = lines!(
                scene, ext, color = a.indicator_color,
                strokewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                visible = a.indicator_visible, inspectable = false
            )
            translate!(p, Vec3f(0, 0, a.depth[]-1))
            push!(inspector.temp_plots, p)

            for int in plot[1][][idx].interiors
                p = lines!(
                    scene, int, color = a.indicator_color,
                    strokewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                    visible = a.indicator_visible, inspectable = false
                )
                translate!(p, Vec3f(0,0,a.depth[]-1))
                push!(inspector.temp_plots, p)
            end
        end

        a.indicator_visible[] = true
    end

    return idx
end

function show_data(inspector::DataInspector, plot::VolumeSlices, idx, child::Heatmap)
    # a = inspector.plot.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    proj_pos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos)

    qs = extrema(child[1][])
    ps = extrema(child[2][])
    data = child[3][]
    T = child.transformation.model[]
    
    vs = [ # clockwise
        Point3f(T * Point4f(qs[1], ps[1], 0, 1)),
        Point3f(T * Point4f(qs[1], ps[2], 0, 1)),
        Point3f(T * Point4f(qs[2], ps[2], 0, 1)),
        Point3f(T * Point4f(qs[2], ps[1], 0, 1))
    ]

    origin, dir = view_ray(scene)
    pos = Point3f(NaN)
    pos = ray_triangle_intersection(vs[1], vs[2], vs[3], origin, dir)
    if isnan(pos)
        pos = ray_triangle_intersection(vs[3], vs[4], vs[1], origin, dir)
    end

    if !isnan(pos)
        child_idx = findfirst(isequal(child), plot.plots)
        if child_idx == 2
            x = pos[2]; y = pos[3]
        elseif child_idx == 3
            x = pos[1]; y = pos[3]
        else
            x = pos[1]; y = pos[2]
        end
        i = clamp(round(Int, (x - qs[1]) / (qs[2] - qs[1]) * size(data, 1) + 0.5), 1, size(data, 1))
        j = clamp(round(Int, (y - ps[1]) / (ps[2] - ps[1]) * size(data, 2) + 0.5), 1, size(data, 2))
        val = data[i, j]

        tt[1][] = proj_pos
        tt.text[] = @sprintf(
            "x: %0.6f\ny: %0.6f\nz: %0.6f\n%0.6f0",
            pos[1], pos[2], pos[3], val
        )
        tt.visible[] = true
    else
        tt.visible[] = false
    end

    return true
end
