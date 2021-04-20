# checklist:
#=
- scatter 2D :) (ignores zoom scaling)
- scatter 3D :) (ignores zoom scaling)
- LScene Axis :(
- lines 2D :)
- lines 3D :)
- meshscatter 2D :) 
- meshscatter 3D :) (bad text position - maybe static?)
- linesegments 3D :) 
- linesegments 2D :)
- heatmap :)
- barplot :)
- mesh :) (bad text position - maybe static?)
=#


### indicator data -> string
########################################

position2string(p::Point2f0) = @sprintf(" x: %0.6f\n y: %0.6f", p[1], p[2])
position2string(p::Point3f0) = @sprintf(" x: %0.6f\n y: %0.6f\n z: %0.6f", p[1], p[2], p[3])

function bbox2string(bbox::Rect3D)
    p = origin(bbox)
    w = widths(bbox)
    @sprintf(
        " Bounding Box:\n x: (%0.3f, %0.3f)\n y: (%0.3f, %0.3f)\n z: (%0.3f, %0.3f)",
        p[1], w[1], p[2], w[2], p[3], w[3]
    )
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


### Heatmap positions/indices
########################################

pos2index(x, r, N) = clamp(ceil(Int, N * (x - minimum(r)) / (maximum(r) - minimum(r))), 1, N)
index2pos(i, r, N) = minimum(r) + (maximum(r) - minimum(r)) * (i) / (N)


### Getting text bounding boxes to draw backgrounds
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


# TODO
# Could probably use some more attributes
@recipe(_Inspector, x) do scene
    Attributes(
        # Text
        display_text = " ",
        text_align = (:left, :bottom),
        textcolor = :black, 
        textsize = 20, 
        font = "Dejavu Sans",

        # Background
        background_color = :white,
        outline_color = :grey,
        outline_linestyle = nothing,
        outline_linewidth = 2,

        # pixel BBox/indicator
        color = :red,
        bbox_linewidth = 2,
        bbox_linestyle = nothing,
        bbox2D = FRect2D(Vec2f0(0), Vec2f0(0)),
        px_bbox_visible = true,
        
        # general
        root_px_projection = Mat4f0(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1),
        model = Mat4f0(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1),
        depth = 9e3,
        visible = true,
        tooltip_align = (:center, :top),
        tooltip_offset = Vec2f0(20), # this adjusts to tooltip_align
        proj_position = Point2f0(0),
        
        # For other purposes/unused
        bbox3D = FRect3D(Vec3f0(0), Vec3f0(0)),
        bbox_visible = true,
        position = Point3f0(0),
    )
end

function plot!(plot::_Inspector)
    @extract plot (
        display_text, text_align, textcolor, textsize, font,
        background_color, outline_color, outline_linestyle, outline_linewidth,
        bbox2D, px_bbox_visible, bbox_linestyle, bbox_linewidth, color,
        tooltip_align, tooltip_offset, proj_position,
        root_px_projection, model, depth, visible
    )

    id = Mat4f0(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1)
    bbox = Node(FRect2D(Vec2f0(0), Vec2f0(0)))
    text_position = map(proj_position, tooltip_align, tooltip_offset, bbox) do pos, align, offset, bbox
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
        pos .+ Point2f0(dx, dy)
    end

    _text = text!(plot, display_text, 
        position = text_position, visible = visible, align = text_align,
        color = textcolor, font = font, textsize = textsize,
        show_axis = false
    )

    onany(_text._glyphlayout, _text.position) do gl, pos
        r = FRect2D(Bbox_from_glyphlayout(gl))
        bb = FRect2D(origin(r) .+ Vec2f0(pos[1], pos[2]-2), widths(r) .+ Vec2f0(0, 4))
        if bbox[] != bb
            bbox[] = bb
        end
    end

    background = mesh!(
        plot, bbox, color = background_color, shading = false, 
        visible = visible, show_axis = false,
        projection = root_px_projection, view = id, projectionview = root_px_projection
    )
    outline = wireframe!(
        plot, bbox,
        color = outline_color, visible = visible, show_axis = false,
        linestyle = outline_linestyle, linewidth = outline_linewidth, 
        projection = root_px_projection, view = id, projectionview = root_px_projection
    )
    
    px_bbox = wireframe!(
        plot, bbox2D,
        color = color, linewidth = bbox_linewidth, linestyle = bbox_linestyle, # model = model,
        visible = px_bbox_visible, show_axis = false,
        projection = root_px_projection, view = id, projectionview = root_px_projection
    )

    # To make sure inspector plots end up in front
    on(depth) do d
        # This is a translate to, not translate by
        translate!(background, Vec3f0(0,0,d+1))
        translate!(outline,    Vec3f0(0,0,d+2))
        translate!(_text,      Vec3f0(0,0,d+3))
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
    
    enabled::Bool

    whitelist::Vector{AbstractPlot}
    blacklist::Vector{AbstractPlot}
end

enable!(inspector::DataInspector) = inspector.enabled = true
disable!(inspector::DataInspector) = inspector.enabled = false

"""
    DataInspector(figure; blacklist = fig.scene.plots, kwargs...)
    DataInspector(axis; whitelist = axis.scene.plots, kwargs...)
    DataInspector(scene; kwargs...)

...
"""
function DataInspector(fig::Figure; blacklist = fig.scene.plots, kwargs...)
    DataInspector(fig.scene; blacklist = blacklist, kwargs...)
end

function DataInspector(ax; whitelist = ax.scene.plots, kwargs...)
    DataInspector(ax.scene; whitelist = whitelist, kwargs...)
end

# TODO
# - It would be good if we didn't need to flatten. Maybe recursively go up all
#   the way, then check if a plot is rejected and move down a level if it is or
#   attempt to show if not. If show fails also move down a level, else break.
# ^ That makes it hard to work with picked indices...
function DataInspector(
        scene::Scene; 
        whitelist = AbstractPlot[], blacklist = AbstractPlot[], range = 10,
        kwargs...
    )
    parent = root(scene)
    @assert origin(pixelarea(parent)[]) == Vec2f0(0)

    plot = _inspector!(parent, 1, show_axis=false; kwargs...)
    plot.root_px_projection[] = camera(parent).pixel_space[]
    push!(blacklist, plot)
    blacklist = flatten_plots(blacklist)
    
    inspector = DataInspector(parent, scene, AbstractPlot[], plot, true, whitelist, blacklist)

    e = events(parent)
    onany(e.mouseposition, e.scroll) do mp, _
        (inspector.enabled && is_mouseinside(parent)) || return false

        picks = pick_sorted(parent, mp, range)
        should_clear = true
        for (plt, idx) in picks
            @info idx, typeof(plt)
            if (plt !== nothing) && !(plt in inspector.blacklist) && 
                # to_value(get(plt.attributes, :inspectable, true)) &&
                (isempty(inspector.whitelist) || (plt in inspector.whitelist))

                should_clear = !show_data(inspector, plt, idx)
                break
            end
        end

        if should_clear
            plot.visible[] = false
            plot.bbox_visible[] = false
            plot.px_bbox_visible[] = false
        end
    end

    inspector
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
        flattened = flatten_plots(p)
        filter!(p -> !(p in flattened), inspector.blacklist)
    end
    empty!(inspector.temp_plots)
end

# computes a projected position relative to the root scene
function update_positions!(inspector, scene, pos)
    a = inspector.plot.attributes
    proj_pos = shift_project(scene, to_ndim(Point3f0, pos, 0))
    a.position[] = pos
    a.proj_position[] = proj_pos
    return proj_pos
end

# update alignment direction
function update_tooltip_alignment!(inspector)
    a = inspector.plot.attributes
    wx, wy = widths(pixelarea(inspector.root)[])
    px, py = a.proj_position[]
    halign, valign = a.tooltip_align[]
    px < wx/3  && (halign = :right)
    px > 2wx/3 && (halign = :left)
    py < wy/3  && (valign = :top)
    py > 2wy/3 && (valign = :bottom)
    a.tooltip_align[] = (halign, valign)
end
    

# TODO: better 3D scaling
function show_data(inspector::DataInspector, plot::Scatter, idx)
    @info "Scatter"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)

    proj_pos = update_positions!(inspector, scene, plot[1][][idx])
    update_tooltip_alignment!(inspector)
    ms = plot.markersize[]

    a.display_text[] = position2string(plot[1][][idx])
    a.bbox2D[] = FRect2D(proj_pos .- 0.5 .* ms .- Vec2f0(5), Vec2f0(ms) .+ Vec2f0(10))
    a.px_bbox_visible[] = true
    a.bbox_visible[] = false
    a.visible[] = true

    return true
end

    
function show_data(inspector::DataInspector, plot::MeshScatter, idx)
    @info "MeshScatter"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)
        
    proj_pos = update_positions!(inspector, scene, plot[1][][idx])
    update_tooltip_alignment!(inspector)
    bbox = Rect{3, Float32}(plot.marker[])

    a.model[] = transformationmatrix(
        plot[1][][idx],
        to_scale(plot.markersize[], idx), 
        to_rotation(plot.rotations[], idx)
    )

    if isempty(inspector.temp_plots) || !(inspector.temp_plots[1][1][] isa Rect3D)
        clear_temporary_plots!(inspector)
        p = wireframe!(
            scene, a.bbox3D, model = a.model, 
            color = a.color, visible = a.bbox_visible, show_axis = false,
        )
        push!(inspector.temp_plots, p)
        append!(inspector.blacklist, flatten_plots(p))
    end

    a.display_text[] = position2string(plot[1][][idx])
    a.bbox3D[] = bbox
    a.px_bbox_visible[] = false
    a.bbox_visible[] = true
    a.visible[] = true
    
    return true
end

# TODO
# this needs some clamping?
function show_data(inspector::DataInspector, plot::Union{Lines, LineSegments}, idx)
    @info "Lines, LineSegments"
    a = inspector.plot.attributes
    if plot.parent.parent isa BarPlot
        return show_data(inspector, plot.parent.parent, div(idx-1, 6)+1)
    end
        
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)

    # cast ray from cursor into screen, find closest point to line
    p0, p1 = plot[1][][idx-1:idx]
    origin, dir = view_ray(scene)
    pos = closest_point_on_line(p0, p1, origin, dir)
    lw = plot.linewidth[]
    
    proj_pos = update_positions!(inspector, scene, pos)
    update_tooltip_alignment!(inspector)

    a.display_text[] = position2string(pos)
    a.bbox2D[] = FRect2D(proj_pos .- 0.5 .* lw .- Vec2f0(5), Vec2f0(lw) .+ Vec2f0(10))
    a.px_bbox_visible[] = true
    a.bbox_visible[] = false
    a.visible[] = true

    return true
end

# TODO position indicator better
function show_data(inspector::DataInspector, plot::Mesh, idx)
    @info "Mesh"
    a = inspector.plot.attributes
    if plot.parent.parent.parent isa BarPlot
        return show_data(inspector, plot.parent.parent.parent, div(idx-1, 4)+1)
    end

    scene = parent_scene(plot)
    update_hovered!(inspector, scene)
        
    bbox = boundingbox(plot)
    min, max = extrema(bbox)
    proj_pos = update_positions!(inspector, scene, 0.5 * (max .+ min))
    update_tooltip_alignment!(inspector)

    a.model[] = plot.model[]

    if isempty(inspector.temp_plots) || !(inspector.temp_plots[1][1][] isa Rect3D)
        clear_temporary_plots!(inspector)
        p = wireframe!(
            scene, a.bbox3D, model = a.model, 
            color = a.color, visible = a.bbox_visible, show_axis = false,
        )
        push!(inspector.temp_plots, p)
        append!(inspector.blacklist, flatten_plots(p))
    end

    a.display_text[] = bbox2string(bbox)
    a.bbox3D[] = bbox
    a.px_bbox_visible[] = false
    a.bbox_visible[] = true
    a.visible[] = true

    return true
end

# TODO breaks with ax as root
function show_data(inspector::DataInspector, plot::BarPlot, idx)
    @info "BarPlot"
    a = inspector.plot.attributes
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)
        
    proj_pos = update_positions!(inspector, scene, plot[1][][idx])
    update_tooltip_alignment!(inspector)
    a.model[] = plot.model[]
    a.bbox2D[] = plot.plots[1][1][][idx]

    if isempty(inspector.temp_plots) || !(inspector.temp_plots[1][1][] isa Rect2D)
        clear_temporary_plots!(inspector)
        p = wireframe!(
            scene, a.bbox2D, model = a.model, 
            color = a.color, visible = a.bbox_visible, show_axis = false,
        )
        translate!(p, Vec3f0(0, 0, a.depth[]))
        push!(inspector.temp_plots, p)
        append!(inspector.blacklist, flatten_plots(p))
    end

    a.display_text[] = position2string(pos)
    a.bbox_visible[] = true
    a.px_bbox_visible[] = false
    a.visible[] = true

    return true
end

function show_data(inspector::DataInspector, plot::Heatmap, idx)
    # This needs to be updated once Heatmaps are centered 
    # Alternatively, could this get a useful index?
    @info "Heatmap"
    a = inspector.plot.attributes
    # idx == 0 :(
    scene = parent_scene(plot)
    update_hovered!(inspector, scene)
            
    mpos = mouseposition(scene)
    i = pos2index(mpos[1], plot[1][], size(plot[3][], 1))
    j = pos2index(mpos[2], plot[2][], size(plot[3][], 2))
    x0 = index2pos(i-1, plot[1][], size(plot[3][], 1))
    y0 = index2pos(j-1, plot[2][], size(plot[3][], 2))
    x1 = index2pos(i, plot[1][], size(plot[3][], 1))
    y1 = index2pos(j, plot[2][], size(plot[3][], 2))
    x = 0.5(x0 + x1); y = 0.5(y0 + y1)
    z = plot[3][][i, j]

    proj_pos = update_positions!(inspector, scene, Point3f0(x, y, 0))
    update_tooltip_alignment!(inspector)
    a.bbox2D[] = FRect2D(Vec2f0(x0, y0), Vec2f0(x1-x0, y1-y0))
    
    if isempty(inspector.temp_plots) || !(inspector.temp_plots[1][1][] isa Rect2D)
        clear_temporary_plots!(inspector)
        p = wireframe!(
            scene, a.bbox2D, model = a.model, 
            color = a.color, visible = a.bbox_visible, show_axis = false,
        )
        translate!(p, Vec3f0(0, 0, a.depth[]))
        push!(inspector.temp_plots, p)
        append!(inspector.blacklist, flatten_plots(p))
    end
    
    a.display_text[] = @sprintf(" %0.3f @ (%i, %i) ", z, i, j)
    a.bbox_visible[] = true
    a.px_bbox_visible[] = false
    a.visible[] = true

    return true
end


function show_data(inspector::DataInspector, plot, idx)
    @info "else"
    return false
end
