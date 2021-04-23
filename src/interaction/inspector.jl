### indicator data -> string
########################################

vec2string(p::StaticVector{2}) = @sprintf("(%0.3f, %0.3f)", p[1], p[2])
vec2string(p::StaticVector{3}) = @sprintf("(%0.3f, %0.3f, %0.3f)", p[1], p[2], p[3])

position2string(p::StaticVector{2}) = @sprintf(" x: %0.6f\n y: %0.6f", p[1], p[2])
position2string(p::StaticVector{3}) = @sprintf(" x: %0.6f\n y: %0.6f\n z: %0.6f", p[1], p[2], p[3])

function bbox2string(bbox::Rect3D)
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

function bbox2string(bbox::Rect2D)
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
function color2text(c::RGBAf0)
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

to_scale(f::AbstractFloat, idx) = Vec3f0(f)
to_scale(v::Vec2f0, idx) = Vec3f0(v[1], v[2], 1)
to_scale(v::Vec3f0, idx) = v
to_scale(v::Vector, idx) = to_scale(v[idx], idx)

to_rotation(x, idx) = x
to_rotation(x::Vector, idx) = x[idx]


### Selecting a point on a nearby line
########################################

function closest_point_on_line(p0::Point2f0, p1::Point2f0, r::Point2f0)
    # This only works in 2D
    AP = P .- A; AB = B .- A
    A .+ AB * dot(AP, AB) / dot(AB, AB)
end

function view_ray(scene)
    inv_projview = inv(camera(scene).projectionview[])
    view_ray(inv_projview, events(scene).mouseposition[], pixelarea(scene)[])
end
function view_ray(inv_view_proj, mpos, area::Rect2D)
    # This figures out the camera view direction from the projectionview matrix (?)
    # and computes a ray from a near and a far point.
    # Based on ComputeCameraRay from ImGuizmo
    mp = 2f0 .* (mpos .- minimum(area)) ./ widths(area) .- 1f0
    v = inv_view_proj * Vec4f0(0, 0, -10, 1)
    reversed = v[3] < v[4]
    near = reversed ? 1f0 - 1e-6 : 0f0
    far = reversed ? 0f0 : 1f0 - 1e-6

    origin = inv_view_proj * Vec4f0(mp[1], mp[2], near, 1f0)
    origin = origin[SOneTo(3)] ./ origin[4]

    p = inv_view_proj * Vec4f0(mp[1], mp[2], far, 1f0)
    p = p[SOneTo(3)] ./ p[4]

    dir = normalize(p - origin)
    return origin, dir
end


# These work in 2D and 3D
function closest_point_on_line(A, B, origin, dir)
    closest_point_on_line(
        to_ndim(Point3f0, A, 0),
        to_ndim(Point3f0, B, 0),
        to_ndim(Point3f0, origin, 0),
        to_ndim(Vec3f0, dir, 0)
    )
end
function closest_point_on_line(A::Point3f0, B::Point3f0, origin::Point3f0, dir::Vec3f0)
    # See:
    # https://en.wikipedia.org/wiki/Line%E2%80%93plane_intersection
    u_AB = normalize(B .- A)
    u_dir = normalize(dir)
    u_perp = normalize(cross(u_dir, u_AB))
    # e_RD, e_perp defines a plane with normal n
    n = normalize(cross(u_dir, u_perp))
    t = dot(origin .- A, n) / dot(u_AB, n)
    A .+ t * u_AB
end

function ray_triangle_intersection(A, B, C, origin, dir)
    # See: https://www.iue.tuwien.ac.at/phd/ertl/node114.html
    AO = A .- origin
    BO = B .- origin
    CO = C .- origin
    A1 = 0.5 * dot(cross(BO, CO), dir)
    A2 = 0.5 * dot(cross(CO, AO), dir)
    A3 = 0.5 * dot(cross(AO, BO), dir)
    if (A1 > 0 && A2 > 0 && A3 > 0) || (A1 < 0 && A2 < 0 && A3 < 0)
        Point3f0((A1 * A .+ A2 * B .+ A3 * C) / (A1 + A2 + A3))
    else
        Point3f0(NaN)
    end
end


### Heatmap positions/indices
########################################

pos2index(x, r, N) = clamp(ceil(Int, N * (x - minimum(r)) / (maximum(r) - minimum(r))), 1, N)
index2pos(i, r, N) = minimum(r) + (maximum(r) - minimum(r)) * (i) / (N)


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
    Point3f0(surface_x(xs, i, j, N), surface_y(ys, i, j, M), zs[i, j])
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


### Text bounding box
########################################

function Bbox_from_glyphlayout(gl)
    bbox = FRect3D(
        gl.origins[1] .+ Vec3f0(origin(gl.bboxes[1])..., 0), 
        Vec3f0(widths(gl.bboxes[1])..., 0)
    )
    for (o, bb) in zip(gl.origins[2:end], gl.bboxes[2:end])
        bbox2 = FRect3D(o .+ Vec3f0(origin(bb)..., 0), Vec3f0(widths(bb)..., 0))
        bbox = union(bbox, bbox2)
    end
    bbox
end


## Shifted projection
########################################

function shift_project(scene, pos)
    project(
        camera(scene).projectionview[],
        Vec2f0(widths(pixelarea(scene)[])),
        pos
    ) .+ Vec2f0(origin(pixelarea(scene)[]))
end



################################################################################
### Base pixel-space plot for Indicator
################################################################################


@recipe(_Inspector, x) do scene
    # Attributes starting with _ are modified internally
    Attributes(
        # Text
        text_padding = Vec4f0(0, 0, 4, 4), # LRBT
        text_align = (:left, :bottom),
        textcolor = :black, 
        textsize = 20, 
        font = "Dejavu Sans",
        _display_text = " ",
        _text_position = Point2f0(0),
        _text_padding = Vec4f0(0),

        # Background
        background_color = :white,
        outline_color = :grey,
        outline_linestyle = nothing,
        outline_linewidth = 2,

        # pixel BBox/indicator
        color = :red,
        bbox_linewidth = 2,
        bbox_linestyle = nothing,
        _bbox2D = FRect2D(Vec2f0(0), Vec2f0(0)),
        _px_bbox_visible = true,
        
        # general
        tooltip_align = (:center, :top), # default tooltip position relative to cursor
        tooltip_offset = Vec2f0(20), # default offset in alignment direction
        depth = 9e3,
        enabled = true,
        range = 10,

        _root_px_projection = Mat4f0(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1),
        _model = Mat4f0(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1),
        _visible = true,
        _tooltip_align = (:center, :top),
        _tooltip_offset = Vec2f0(20),
        _bbox3D = FRect3D(Vec3f0(0), Vec3f0(0)),
        _bbox_visible = true,
        _position = Point3f0(0),
        _color = RGBAf0(0,0,0,0)
    )
end

function plot!(plot::_Inspector)
    @extract plot (
        _display_text, _text_position, _text_padding, text_align, textcolor, 
        textsize, font,
        background_color, outline_color, outline_linestyle, outline_linewidth,
        _bbox2D, _px_bbox_visible, bbox_linestyle, bbox_linewidth, color,
        _tooltip_align, _tooltip_offset,
        _root_px_projection, depth, _visible
    )

    # tooltip text
    _aligned_text_position = Node(Point2f0(0))
    text_plot = text!(plot, _display_text, 
        position = _aligned_text_position, visible = _visible, align = text_align,
        color = textcolor, font = font, textsize = textsize, show_axis = false,
        inspectable = false
    )

    # compute text boundingbox and adjust _aligned_text_position
    bbox = map(text_plot._glyphlayout, text_plot.position, _text_padding) do gl, pos, pad
        rect = FRect2D(Bbox_from_glyphlayout(gl))
        l, r, b, t = pad
        FRect2D(
            origin(rect) .+ Vec2f0(pos[1] - l, pos[2] - b), 
            widths(rect) .+ Vec2f0(l + r, b + t)
        )
    end
    onany(_text_position, _tooltip_align, _tooltip_offset, bbox) do pos, align, offset, bbox
        halign, valign = align
        ox, oy = offset
        wx, wy = widths(bbox)
        if halign == :left
            dx = -wx - ox
        elseif halign == :center
            dx = -0.5wx
        elseif halign == :right
            dx = + ox
        end
        if valign == :top
            dy = oy
        elseif valign == :center
            dy = -0.5wy
        elseif valign == :bottom
            dy = -wy - oy
        end
        new_pos = pos .+ Point2f0(dx, dy)
        if new_pos != _aligned_text_position[]
            _aligned_text_position[] = new_pos
        end
    end


    # tooltip background and frame 
    id = Mat4f0(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1)
    background = mesh!(
        plot, bbox, color = background_color, shading = false, 
        visible = _visible, show_axis = false, inspectable = false,
        projection = _root_px_projection, view = id, projectionview = _root_px_projection
    )
    outline = wireframe!(
        plot, bbox,
        color = outline_color, visible = _visible, show_axis = false, inspectable = false,
        linestyle = outline_linestyle, linewidth = outline_linewidth, 
        projection = _root_px_projection, view = id, projectionview = _root_px_projection
    )
    
    # pixel-space marker for selected element (not always used)
    px_bbox = wireframe!(
        plot, _bbox2D,
        color = color, linewidth = bbox_linewidth, linestyle = bbox_linestyle, 
        visible = _px_bbox_visible, show_axis = false, inspectable = false,
        projection = _root_px_projection, view = id, projectionview = _root_px_projection
    )

    # To make sure inspector plots end up in front
    on(depth) do d
        translate!(background, Vec3f0(0,0,d+1))
        translate!(outline,    Vec3f0(0,0,d+2))
        translate!(text_plot,  Vec3f0(0,0,d+3))
        translate!(px_bbox,    Vec3f0(0,0,d))
    end
    depth[] = depth[]
    nothing
end


################################################################################
### Interactive selection via DataInspector
################################################################################



# TODO destructor?
mutable struct DataInspector
    # need some static reference
    root::Scene

    # Adjust to hover
    hovered_scene::Union{Nothing, Scene}
    temp_plots::Vector{AbstractPlot}

    # plot to attach to hovered scene
    plot::_Inspector
end

enable!(inspector::DataInspector) = inspector.plot.enabled[] = true
disable!(inspector::DataInspector) = inspector.plot.enabled[] = false

"""
    DataInspector(figure; kwargs...)

Creates a data inspector which will show relevant information in a tooltip 
when you hover over a plot. If you wish to exclude a plot you may set 
`plot.inspectable[] = false`. 

### Keyword Arguments:
- `range = 10`: Snapping range for selecting a point on a plot to inspect.
- `enabled = true`: Disables inspection of plots when set to false. Can also be
    adjusted with `enable!(inspector)` and `disable!(inspector)`.
- `text_padding = Vec4f0(0, 0, 4, 4)`: Padding for the box drawn around the 
    tooltip text. (left, right, bottom, top)
- `text_align = (:left, :bottom)`: Alignment of text within the tooltip.
- `textcolor = :black`: Tooltip text color.
- `textsize = 20`: Tooltip text size.
- `font = "Dejavu Sans"`: Tooltip font.
- `background_color = :white`: Color of the tooltip background.
- `outline_color = :grey`: Color of the tooltip outline.
- `outline_linestyle = nothing`: Color of the tooltip outline.
- `outline_linewidth = 2`: Linewidth of the tooltip outline.
- `color = :red`: Color of the selection indicator.
- `bbox_linewidth = 2`: Linewidth of the selection indicator.
- `bbox_linestyle = nothing`: Linestyle of the selection indicator  
- `tooltip_align = (:center, :top)`: Default position of the tooltip relative to
    the current selection.
- `tooltip_offset = Vec2f0(20)`: Offset between the indicator position and the 
    tooltip position. 
- `depth = 9e3`: Depth value of the tooltip. This should be high so that the 
    tooltip is always in front.
"""
function DataInspector(fig::Figure; kwargs...)
    DataInspector(fig.scene; kwargs...)
end

function DataInspector(ax; kwargs...)
    DataInspector(ax.scene; kwargs...)
end


function DataInspector(scene::Scene; kwargs...)
    parent = root(scene)
    @assert origin(pixelarea(parent)[]) == Vec2f0(0)

    plot = _inspector!(parent, 1, show_axis=false; kwargs...)
    plot._root_px_projection[] = camera(parent).pixel_space[]
    inspector = DataInspector(parent, scene, AbstractPlot[], plot)

    e = events(parent)
    onany(e.mouseposition, e.scroll) do mp, _
        (inspector.plot.enabled[] && is_mouseinside(parent)) || return false

        picks = pick_sorted(parent, mp, inspector.plot.range[])
        should_clear = true
        for (plt, idx) in picks
            @info to_value(get(plt.attributes, :inspectable, nothing)), idx, typeof(plt)
            if to_value(get(plt.attributes, :inspectable, true)) &&
                # show_data should return true if it created a tooltip
                if show_data_recursion(inspector, plt, idx)
                    should_clear = false
                    break
                end
            end
        end

        if should_clear
            @info "Clearing"
            plot._visible[] = false
            plot._bbox_visible[] = false
            plot._px_bbox_visible[] = false
        end
    end

    inspector
end


function show_data_recursion(inspector, plot, idx,)
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
    


# updates hovered_scene and clears any temp plots
function update_hovered!(inspector::DataInspector, scene)
    if scene != inspector.hovered_scene
        if !isempty(inspector.temp_plots) && (inspector.hovered_scene !== nothing)
            clear_temporary_plots!(inspector)
        end
        inspector.hovered_scene = scene
    end
end

# clears temporary plots (i.e. bboxes)
function clear_temporary_plots!(inspector::DataInspector)
    for p in inspector.temp_plots
        delete!(inspector.hovered_scene, p)
    end
    empty!(inspector.temp_plots)
end

# update alignment direction
function update_tooltip_alignment!(inspector, proj_pos)
    a = inspector.plot.attributes
    a._text_position[] = proj_pos

    wx, wy = widths(pixelarea(inspector.root)[])
    px, py = proj_pos
    halign, valign = a.tooltip_align[]
    px < wx/4  && (halign = :right)
    px > 3wx/4 && (halign = :left)
    py < wy/4  && (valign = :top)
    py > 3wy/4 && (valign = :bottom)
    a._tooltip_align[] = (halign, valign)
end



################################################################################
### show_data for primitive plots
################################################################################



# TODO: better 3D scaling
function show_data(inspector::DataInspector, plot::Scatter, idx)
    @info "Scatter"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)

    proj_pos = shift_project(scene, to_ndim(Point3f0, plot[1][][idx], 0))
    update_tooltip_alignment!(inspector, proj_pos)
    ms = plot.markersize[]

    a._display_text[] = position2string(plot[1][][idx])
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* ms .- Vec2f0(5), Vec2f0(ms) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true
    a._text_padding[] = a.text_padding[]
    a._tooltip_offset[] = a.tooltip_offset[]

    return true
end


function show_data(inspector::DataInspector, plot::MeshScatter, idx)
    @info "MeshScatter"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)
        
    proj_pos = shift_project(scene, to_ndim(Point3f0, plot[1][][idx], 0))
    update_tooltip_alignment!(inspector, proj_pos)
    bbox = Rect{3, Float32}(plot.marker[])

    a._model[] = transformationmatrix(
        plot[1][][idx],
        to_scale(plot.markersize[], idx), 
        to_rotation(plot.rotations[], idx)
    )

    if isempty(inspector.temp_plots) || !(inspector.temp_plots[1][1][] isa Rect3D)
        clear_temporary_plots!(inspector)
        p = wireframe!(
            scene, a._bbox3D, model = a._model, color = a.color, 
            visible = a._bbox_visible, show_axis = false, inspectable = false
        )
        push!(inspector.temp_plots, p)
    end

    a._display_text[] = position2string(plot[1][][idx])
    a._bbox3D[] = bbox
    a._px_bbox_visible[] = false
    a._bbox_visible[] = true
    a._visible[] = true
    a._text_padding[] = a.text_padding[]
    a._tooltip_offset[] = a.tooltip_offset[]

    return true
end


function show_data(inspector::DataInspector, plot::Union{Lines, LineSegments}, idx)
    @info "Lines, LineSegments"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)

    # cast ray from cursor into screen, find closest point to line
    p0, p1 = plot[1][][idx-1:idx]
    origin, dir = view_ray(scene)
    pos = closest_point_on_line(p0, p1, origin, dir)
    lw = plot.linewidth[] isa Vector ? plot.linewidth[][idx] : plot.linewidth[]
    
    proj_pos = shift_project(scene, to_ndim(Point3f0, pos, 0))
    update_tooltip_alignment!(inspector, proj_pos)

    a._display_text[] = position2string(pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* lw .- Vec2f0(5), Vec2f0(lw) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true
    a._text_padding[] = a.text_padding[]
    a._tooltip_offset[] = a.tooltip_offset[]

    return true
end


function show_data(inspector::DataInspector, plot::Mesh, idx)
    @info "Mesh"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)
        
    bbox = boundingbox(plot)
    min, max = extrema(bbox)
    proj_pos = shift_project(scene, to_ndim(Point3f0, 0.5(max .+ min), 0))

    a._model[] = plot.model[]

    if isempty(inspector.temp_plots) || !(inspector.temp_plots[1][1][] isa Rect3D)
        clear_temporary_plots!(inspector)
        p = wireframe!(
            scene, a._bbox3D, model = a._model, color = a.color, 
            visible = a._bbox_visible, show_axis = false, inspectable = false
        )
        push!(inspector.temp_plots, p)
    end

    a._text_position[] = Point2f0(maximum(pixelarea(scene)[]))
    a._tooltip_align[] = (:left, :bottom)
    a._display_text[] = bbox2string(bbox)
    a._bbox3D[] = bbox
    a._px_bbox_visible[] = false
    a._bbox_visible[] = true
    a._visible[] = true
    a._text_padding[] = Vec4f0(0, 0, 6, 4)
    a._tooltip_offset[] = Vec2f0(5)

    return true
end


function show_data(inspector::DataInspector, plot::Surface, idx)
    @info "Surface"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)
            
    proj_pos = Point2f0(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos)

    xs = plot[1][]
    ys = plot[2][]
    zs = plot[3][]
    w, h = size(zs)
    i = mod1(idx, w); j = div(idx-1, w)

    origin, dir = view_ray(scene)
    pos = Point3f0(NaN)

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

    if !isnan(pos)
        a._display_text[] = position2string(pos)
        a._text_position[] = proj_pos
        a._bbox2D[] = FRect2D(proj_pos .- Vec2f0(5), Vec2f0(10))
        a._bbox_visible[] = false
        a._px_bbox_visible[] = true
        a._visible[] = true
        a._text_padding[] = Vec4f0(5, 5, 4, 4)
        a._tooltip_offset[] = a.tooltip_offset[]
    end

    return true
end

function show_data(inspector::DataInspector, plot::Heatmap, idx)
    @info "Heatmap"
    show_imagelike(inspector, plot, "H")
end

function show_data(inspector::DataInspector, plot::Image, idx)
    @info "Image"
    show_imagelike(inspector, plot, "img")
end

function show_imagelike(inspector, plot, name)
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    mpos = mouseposition(scene)

    i, j, z = if plot.interpolate[]
        _interpolated_getindex(plot[1][], plot[2][], plot[3][], mpos)
    else
        _pixelated_getindex(plot[1][], plot[2][], plot[3][], mpos)
    end

    a._color[] = if z isa AbstractFloat
        interpolated_getindex(
            to_colormap(plot.colormap[]), z, 
            to_value(get(plot.attributes, :colorrange, (0, 1)))
        )
    else
        z
    end

    a._position[] = to_ndim(Point3f0, mpos, 0)
    proj_pos = Point2f0(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos)

    if plot.interpolate[]
        if isempty(inspector.temp_plots) || !(inspector.temp_plots[1] isa Scatter)
            clear_temporary_plots!(inspector)
            p = scatter!(
                scene, map(p -> [p], a._position), color = a._color, 
                visible = a._bbox_visible,
                show_axis = false, inspectable = false, 
                marker=:rect, markersize = min(2a.range[]-2, 20),
                strokecolor = a.color, strokewidth = 1
            )
            translate!(p, Vec3f0(0, 0, a.depth[]))
            push!(inspector.temp_plots, p)
        end
    else
        a._bbox2D[] = _pixelated_image_bbox(plot[1][], plot[2][], plot[3][], i, j)
        if isempty(inspector.temp_plots) || 
            !(inspector.temp_plots[1] isa Wireframe) ||
            !(inspector.temp_plots[1][1][] isa Rect2D)

            clear_temporary_plots!(inspector)
            p = wireframe!(
                scene, a._bbox2D, model = a._model, color = a.color, 
                visible = a._bbox_visible, show_axis = false, inspectable = false
            )
            translate!(p, Vec3f0(0, 0, a.depth[]))
            push!(inspector.temp_plots, p)
        end
    end

    a._display_text[] = color2text(name, i, j, z)
    a._bbox_visible[] = true
    a._px_bbox_visible[] = false
    a._visible[] = true
    a._text_padding[] = Vec4f0(5, 5, 4, 4)
    a._tooltip_offset[] = a.tooltip_offset[]
    return true
end


function _interpolated_getindex(xs, ys, img, mpos)
    x0, x1 = extrema(xs)
    y0, y1 = extrema(ys)
    x, y = clamp.(mpos, (x0, y0), (x1, y1))

    i = clamp((x - x0) / (x1 - x0) * size(img, 1) + 0.5, 1, size(img, 1))
    j = clamp((y - y0) / (y1 - y0) * size(img, 2) + 0.5, 1, size(img, 2))
    l = clamp(floor(Int, i), 1, size(img, 1)-1); 
    r = clamp(ceil(Int, i), 2, size(img, 1))
    b = clamp(floor(Int, j), 1, size(img, 2)-1); 
    t = clamp(ceil(Int, j), 2, size(img, 2))
    z = ((r-i) * img[l, b] + (i-l) * img[r, b]) * (t-j) +
        ((r-i) * img[l, t] + (i-l) * img[r, t]) * (j-b)

    # float, float, value
    return i, j, z
end
function _pixelated_getindex(xs, ys, img, mpos)
    x0, x1 = extrema(xs)
    y0, y1 = extrema(ys)
    x, y = clamp.(mpos, (x0, y0), (x1, y1))

    i = clamp(round(Int, (x - x0) / (x1 - x0) * size(img, 1) + 0.5), 1, size(img, 1))
    j = clamp(round(Int, (y - y0) / (y1 - y0) * size(img, 2) + 0.5), 1, size(img, 2))

    # int, int, value
    return i, j, img[i,j]
end
function _pixelated_image_bbox(xs, ys, img, i::Integer, j::Integer)
    x0, x1 = extrema(xs)
    y0, y1 = extrema(ys)
    nw, nh = ((x1 - x0), (y1 - y0)) ./ size(img)
    FRect2D(nw * (i-1), nh * (j-1), nw, nh)
end

function show_data(inspector::DataInspector, plot, idx, source = nothing)
    @info "else"
    return false
end



################################################################################
### show_data for Combined/recipe plots
################################################################################



function show_data(inspector::DataInspector, plot::BarPlot, idx, ::LineSegments)
    return show_data(inspector, plot, div(idx-1, 6)+1)
end

function show_data(inspector::DataInspector, plot::BarPlot, idx, ::Mesh)
    return show_data(inspector, plot, div(idx-1, 4)+1)
end

function show_data(inspector::DataInspector, plot::BarPlot, idx)
    @info "BarPlot"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)
        
    pos = plot[1][][idx]
    proj_pos = shift_project(scene, to_ndim(Point3f0, pos, 0))
    update_tooltip_alignment!(inspector, proj_pos)
    a._model[] = plot.model[]
    a._bbox2D[] = plot.plots[1][1][][idx]

    if isempty(inspector.temp_plots) || !(inspector.temp_plots[1][1][] isa Rect2D)
        clear_temporary_plots!(inspector)
        p = wireframe!(
            scene, a._bbox2D, model = a._model, color = a.color, 
            visible = a._bbox_visible, show_axis = false, inspectable = false
        )
        translate!(p, Vec3f0(0, 0, a.depth[]))
        push!(inspector.temp_plots, p)
    end

    a._display_text[] = position2string(pos)
    a._bbox_visible[] = true
    a._px_bbox_visible[] = false
    a._visible[] = true
    a._text_padding[] = a.text_padding[]
    a._tooltip_offset[] = a.tooltip_offset[]

    return true
end

function show_data(inspector::DataInspector, plot::Arrows, idx, ::LineSegments)
    return show_data(inspector, plot, div(idx+1, 2), nothing)
end
function show_data(inspector::DataInspector, plot::Arrows, idx, source)
    @info "Arrows"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)
        
    pos = plot[1][][idx]
    proj_pos = shift_project(scene, to_ndim(Point3f0, pos, 0))
    update_tooltip_alignment!(inspector, proj_pos)
    
    p = vec2string(pos)
    v = vec2string(plot[2][][idx])

    a._text_position[] = Point2f0(maximum(pixelarea(scene)[]))
    a._tooltip_align[] = (:left, :bottom)
    a._display_text[] = " Position:\n  $p\n Direction\n  $v"
    a._bbox2D[] = FRect2D(proj_pos .- Vec2f0(5), Vec2f0(10))
    a._bbox_visible[] = false
    a._px_bbox_visible[] = true
    a._visible[] = true
    a._text_padding[] = a.text_padding[]
    a._tooltip_offset[] = Vec2f0(5)

    return true
end

# This should work if contourf would place computed levels in colors and let the
# backend handle picking colors from a colormap
function show_data(inspector::DataInspector, plot::Contourf, idx, source::Mesh)
    @info "Contourf"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    idx, ext = show_poly(inspector, plot.plots[1], idx, source)
    level = plot.plots[1].color[][idx]

    a._text_position[] = Point2f0(mouseposition_px(inspector.root))
    a._display_text[] = @sprintf("level = %0.3f", level)
    a._text_padding[] = Vec4f0(5, 5, 4, 4)
    a._tooltip_offset[] = a.tooltip_offset[]
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
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)
        
    idx = vertexindex2poly(plot[1][], idx)
    m = GeometryBasics.mesh(plot[1][][idx])
    
    clear_temporary_plots!(inspector)
    ext = plot[1][][idx].exterior
    p = lines!(
        scene, ext, color = a.color, 
        visible = a._visible, show_axis = false, inspectable = false
    )
    translate!(p, Vec3f0(0,0,a.depth[]))
    push!(inspector.temp_plots, p)
    
    for int in plot[1][][idx].interiors
        p = lines!(
            scene, int, color = a.color, 
            visible = a._visible, show_axis = false, inspectable = false
        )
        translate!(p, Vec3f0(0,0,a.depth[]))
        push!(inspector.temp_plots, p)
    end

    a._px_bbox_visible[] = false
    a._bbox_visible[] = true
    a._visible[] = true

    return idx, ext
end