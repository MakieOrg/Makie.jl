export zoom_inset!, ZoomInset

"""
    ZoomInset

A struct containing all components of an interactive zoom inset.

# Fields
- `ax_main::Axis`: The main axis
- `ax_inset::Axis`: The inset axis showing the zoomed view
- `zoom_rect::Observable{Rect2f}`: Observable for the zoom region rectangle
- `inset_halign::Observable{Float64}`: Horizontal alignment of the inset
- `inset_valign::Observable{Float64}`: Vertical alignment of the inset
- `rect_plot::Poly`: The rectangle plot on the main axis
- `lines_plot::LineSegments`: The connecting lines
"""
struct ZoomInset
    ax_main::Axis
    ax_inset::Axis
    zoom_rect::Observable{Rect2f}
    inset_halign::Observable{Float64}
    inset_valign::Observable{Float64}
    rect_plot::Poly
    lines_plot::LineSegments
end

function _copy_plot_to_inset!(ax, plot::P) where {P<:Plot}
    scene = get_scene(ax)
    plot_attr = keys(plot_attributes(scene, P))
    kw = Dict{Symbol,Any}([name => plot[name] for name in plot_attr if !(name in (:model, :transformation))])
    names = argument_names(P, length(plot.converted[]))
    args = map(name -> plot[name], names)
    func = plotfunc(P)
    _create_plot!(func, kw, ax, args...)
end

"""
    zoom_inset!(ax, rect; kwargs...)

Create an interactive zoom inset for an axis.

The zoom region is shown as a rectangle on the main axis, and the zoomed view
is displayed in an inset axis. The inset can be dragged to reposition it,
and the zoom rectangle edges can be dragged to resize the zoomed region.

# Arguments
- `ax::Axis`: The main axis to add the zoom inset to
- `rect::Rect2`: The initial rectangular region to zoom (in data coordinates).
                 Format: `Rect2f(x_origin, y_origin, width, height)`

# Keyword Arguments
- `inset_width::Real=0.3`: Width of the inset as a fraction of the parent
- `inset_height::Real=0.3`: Height of the inset as a fraction of the parent
- `halign::Real=0.9`: Horizontal alignment of the inset (0=left, 1=right)
- `valign::Real=0.9`: Vertical alignment of the inset (0=bottom, 1=top)
- `strokewidth::Real=1.5`: Width of the zoom rectangle stroke
- `strokecolor=:black`: Color of the zoom rectangle stroke
- `rectcolor=(:black, 0)`: Fill color of the zoom rectangle
- `linecolor=:black`: Color of connecting lines
- `linestyle=:dot`: Style of connecting lines
- `edge_threshold::Real=10`: Pixel threshold for edge detection when resizing

# Returns
A `ZoomInset` struct containing references to the created elements.

# Interactions
- **Drag the inset**: Click and drag inside the inset axis to reposition it
- **Resize zoom region**: Click and drag the edges or corners of the zoom rectangle
  to resize the zoomed region
- **Resize inset**: Click and drag the edges or corners of the inset axis to resize it

# Example
```julia
fig = Figure()
ax = Axis(fig[1, 1])
x = 1:100
y = sin.(x .* 0.1)
lines!(ax, x, y)

# Create zoom inset showing region from x=30 to x=50, y=-0.5 to y=1.0
zi = zoom_inset!(ax, Rect2f(30, -0.5, 20, 1.5))

display(fig)
```
"""
function zoom_inset!(ax::Axis, rect::Rect2;
        inset_width::Real=0.3,
        inset_height::Real=0.3,
        halign::Real=0.9,
        valign::Real=0.9,
        strokewidth::Real=1.5,
        strokecolor=:black,
        rectcolor=(:black, 0),
        linecolor=:black,
        linestyle=:dot,
        edge_threshold::Real=10)

    fig = ax.parent
    # Create observables for the zoom rectangle and inset position/size
    zoom_rect = Observable(Rect2f(rect))
    inset_halign = Observable(Float64(halign))
    inset_valign = Observable(Float64(valign))
    inset_width_obs = Observable(Float32(inset_width))
    inset_height_obs = Observable(Float32(inset_height))

    # Create the inset axis
    ax_inset = Axis(fig[1, 1],
        width=map(Relative, inset_width_obs),
        height=map(Relative, inset_height_obs),
        halign=inset_halign,
        valign=inset_valign,
        backgroundcolor=:white,
        xticklabelsize=10,
        yticklabelsize=10,
        xlabelsize=10,
        ylabelsize=10,
        leftspinevisible=true,
        rightspinevisible=true,
        topspinevisible=true,
        bottomspinevisible=true,
    )
    translate!(ax_inset.scene, 0, 0, 1000)  # Ensure inset is on top
    translate!(ax_inset.blockscene, 0, 0, 1000)  # Ensure inset is on top

    for plot in ax.scene.plots
        _copy_plot_to_inset!(ax_inset, plot)
    end

    # Disable all interactions on the inset axis
    for (name, _) in collect(interactions(ax_inset))
        deregister_interaction!(ax_inset, name)
    end

    # Set inset limits based on zoom rect
    on(zoom_rect; update=true) do r
        limits!(ax_inset, r)
    end

    rect_plot = poly!(ax, zoom_rect;
        strokewidth=strokewidth,
        strokecolor=strokecolor,
        color=rectcolor,
        xautolimits=false,
        yautolimits=false
    )

    # Get the root scene for drawing connecting lines
    pscene = root(get_scene(ax))
    # Create connecting lines between zoom rect and inset
    line_points = Observable(Point2f[])

    function update_lines()
        zr = zoom_rect[]
        zr_min = minimum(zr)
        zr_max = maximum(zr)

        inset_vp = ax_inset.scene.viewport[]
        main_vp = ax.scene.viewport[]
        vp_offset = Point2f(minimum(main_vp))

        # Zoom rect corners in absolute screen space (project returns relative to viewport)
        zr_bl = Point2f(project(ax.scene, Point2f(zr_min[1], zr_min[2]))) .+ vp_offset
        zr_br = Point2f(project(ax.scene, Point2f(zr_max[1], zr_min[2]))) .+ vp_offset
        zr_tl = Point2f(project(ax.scene, Point2f(zr_min[1], zr_max[2]))) .+ vp_offset
        zr_tr = Point2f(project(ax.scene, Point2f(zr_max[1], zr_max[2]))) .+ vp_offset

        # Inset corners in screen space (viewport coords are already absolute)
        in_bl = Point2f(minimum(inset_vp))
        in_br = Point2f(minimum(inset_vp)[1] + widths(inset_vp)[1], minimum(inset_vp)[2])
        in_tl = Point2f(minimum(inset_vp)[1], minimum(inset_vp)[2] + widths(inset_vp)[2])
        in_tr = Point2f(maximum(inset_vp))

        # Determine which corners to connect based on relative position
        # We connect the two closest corners of the zoom rect to the two closest corners of the inset
        zr_center = (zr_bl + zr_tr) / 2
        in_center = (in_bl + in_tr) / 2

        pts = Point2f[]
        if in_center[1] > zr_center[1]  # Inset is to the right
            if in_center[2] > zr_center[2]  # Inset is above-right
                # Connect right side of rect to left side of inset
                push!(pts, zr_tr, in_tl)
                push!(pts, zr_br, in_bl)
            else  # Inset is below-right
                # Connect right side of rect to left side of inset
                push!(pts, zr_tr, in_tl)
                push!(pts, zr_br, in_bl)
            end
        else  # Inset is to the left
            if in_center[2] > zr_center[2]  # Inset is above-left
                # Connect left side of rect to right side of inset
                push!(pts, zr_tl, in_tr)
                push!(pts, zr_bl, in_br)
            else  # Inset is below-left
                # Connect left side of rect to right side of inset
                push!(pts, zr_tl, in_tr)
                push!(pts, zr_bl, in_br)
            end
        end

        line_points[] = pts
        return nothing
    end

    onany(zoom_rect, ax.scene.viewport, ax_inset.scene.viewport,
          ax.scene.camera.projectionview; update=true) do args...
        update_lines()
        return nothing
    end

    lines_plot = linesegments!(pscene, line_points;
        color=linecolor,
        linewidth=strokewidth,
        linestyle=linestyle
    )
    translate!(lines_plot, 0, 0, 9999)

    # === INTERACTIONS ===

    dragging_inset = Ref(false)
    dragging_edge = Ref{Symbol}(:none)  # For zoom rect edges
    dragging_inset_edge = Ref{Symbol}(:none)  # For inset edges
    drag_start_pos = Ref(Point2f(0, 0))
    drag_start_rect = Ref(Rect2f(0, 0, 1, 1))
    drag_start_halign = Ref(0.0)
    drag_start_valign = Ref(0.0)
    drag_start_inset_width = Ref(Float32(0))
    drag_start_inset_height = Ref(Float32(0))

    function detect_edge(mouse_px::Point2f, rect_obs::Observable{Rect2f}, scene::Scene, threshold::Real)
        r = rect_obs[]
        mi = minimum(r)
        ma = maximum(r)

        # Project returns coords relative to viewport, mouse_px is absolute screen coords
        # So we need to subtract the viewport offset from mouse_px for comparison
        vp_offset = Point2f(minimum(scene.viewport[]))
        mouse_rel = mouse_px .- vp_offset

        bl = Point2f(project(scene, Point2f(mi[1], mi[2])))
        br = Point2f(project(scene, Point2f(ma[1], mi[2])))
        tl = Point2f(project(scene, Point2f(mi[1], ma[2])))
        tr = Point2f(project(scene, Point2f(ma[1], ma[2])))

        near_left = abs(mouse_rel[1] - bl[1]) < threshold
        near_right = abs(mouse_rel[1] - br[1]) < threshold
        near_bottom = abs(mouse_rel[2] - bl[2]) < threshold
        near_top = abs(mouse_rel[2] - tl[2]) < threshold

        in_x_range = bl[1] - threshold < mouse_rel[1] < br[1] + threshold
        in_y_range = bl[2] - threshold < mouse_rel[2] < tl[2] + threshold
        strictly_inside = bl[1] + threshold < mouse_rel[1] < br[1] - threshold &&
                          bl[2] + threshold < mouse_rel[2] < tl[2] - threshold

        if near_left && near_top && in_x_range && in_y_range
            return :topleft
        elseif near_right && near_top && in_x_range && in_y_range
            return :topright
        elseif near_left && near_bottom && in_x_range && in_y_range
            return :bottomleft
        elseif near_right && near_bottom && in_x_range && in_y_range
            return :bottomright
        elseif near_left && in_y_range
            return :left
        elseif near_right && in_y_range
            return :right
        elseif near_top && in_x_range
            return :top
        elseif near_bottom && in_x_range
            return :bottom
        elseif strictly_inside
            return :inside
        else
            return :none
        end
    end

    function detect_inset_edge(mouse_px::Point2f, threshold::Real)
        vp = ax_inset.scene.viewport[]
        mi = minimum(vp)
        ma = maximum(vp)

        near_left = abs(mouse_px[1] - mi[1]) < threshold
        near_right = abs(mouse_px[1] - ma[1]) < threshold
        near_bottom = abs(mouse_px[2] - mi[2]) < threshold
        near_top = abs(mouse_px[2] - ma[2]) < threshold

        in_x_range = mi[1] - threshold < mouse_px[1] < ma[1] + threshold
        in_y_range = mi[2] - threshold < mouse_px[2] < ma[2] + threshold
        strictly_inside = mi[1] + threshold < mouse_px[1] < ma[1] - threshold &&
                          mi[2] + threshold < mouse_px[2] < ma[2] - threshold

        if near_left && near_top && in_x_range && in_y_range
            return :inset_topleft
        elseif near_right && near_top && in_x_range && in_y_range
            return :inset_topright
        elseif near_left && near_bottom && in_x_range && in_y_range
            return :inset_bottomleft
        elseif near_right && near_bottom && in_x_range && in_y_range
            return :inset_bottomright
        elseif near_left && in_y_range
            return :inset_left
        elseif near_right && in_y_range
            return :inset_right
        elseif near_top && in_x_range
            return :inset_top
        elseif near_bottom && in_x_range
            return :inset_bottom
        elseif strictly_inside
            return :inset_inside
        else
            return :none
        end
    end

    function mouse_in_inset(mouse_px)
        vp = ax_inset.scene.viewport[]
        return mouse_px[1] >= minimum(vp)[1] && mouse_px[1] <= maximum(vp)[1] &&
               mouse_px[2] >= minimum(vp)[2] && mouse_px[2] <= maximum(vp)[2]
    end

    scene = ax.scene

    on(events(scene).mousebutton, priority=100) do event
        mouse_px = Point2f(events(scene).mouseposition[])

        if event.action == Mouse.press && event.button == Mouse.left
            # Check inset edge first (for resizing)
            inset_edge = detect_inset_edge(mouse_px, edge_threshold)
            if inset_edge != :none && inset_edge != :inset_inside
                dragging_inset_edge[] = inset_edge
                drag_start_pos[] = mouse_px
                drag_start_halign[] = inset_halign[]
                drag_start_valign[] = inset_valign[]
                drag_start_inset_width[] = inset_width_obs[]
                drag_start_inset_height[] = inset_height_obs[]
                return Consume(true)
            end

            # Check if clicking inside inset (for moving)
            if inset_edge == :inset_inside
                dragging_inset[] = true
                drag_start_pos[] = mouse_px
                drag_start_halign[] = inset_halign[]
                drag_start_valign[] = inset_valign[]
                return Consume(true)
            end

            # Check zoom rect edges
            edge = detect_edge(mouse_px, zoom_rect, scene, edge_threshold)
            if edge != :none
                dragging_edge[] = edge
                drag_start_pos[] = mouse_px
                drag_start_rect[] = zoom_rect[]
                return Consume(true)
            end
        elseif event.action == Mouse.release && event.button == Mouse.left
            if dragging_inset[] || dragging_edge[] != :none || dragging_inset_edge[] != :none
                dragging_inset[] = false
                dragging_edge[] = :none
                dragging_inset_edge[] = :none
                return Consume(true)
            end
        end

        return Consume(false)
    end

    on(events(scene).mouseposition, priority=100) do mouse_pos
        mouse_px = Point2f(mouse_pos)

        if dragging_inset[]
            delta = mouse_px - drag_start_pos[]

            parent_bbox = ax.layoutobservables.computedbbox[]
            parent_w = widths(parent_bbox)[1]
            parent_h = widths(parent_bbox)[2]

            curr_inset_w = parent_w * inset_width_obs[]
            curr_inset_h = parent_h * inset_height_obs[]

            available_w = parent_w - curr_inset_w
            available_h = parent_h - curr_inset_h

            if available_w > 0
                new_halign = clamp(drag_start_halign[] + delta[1] / available_w, 0, 1)
                inset_halign[] = new_halign
            end
            if available_h > 0
                new_valign = clamp(drag_start_valign[] + delta[2] / available_h, 0, 1)
                inset_valign[] = new_valign
            end

            return Consume(true)
        elseif dragging_inset_edge[] != :none
            # Resize the inset axis
            delta = mouse_px - drag_start_pos[]

            parent_bbox = ax.layoutobservables.computedbbox[]
            parent_w = widths(parent_bbox)[1]
            parent_h = widths(parent_bbox)[2]

            edge = dragging_inset_edge[]
            min_frac = 0.1  # Minimum size as fraction of parent

            new_width = drag_start_inset_width[]
            new_height = drag_start_inset_height[]
            new_halign = drag_start_halign[]
            new_valign = drag_start_valign[]

            # Handle width changes
            if edge in (:inset_left, :inset_topleft, :inset_bottomleft)
                # Dragging left edge: decrease width, adjust halign
                width_delta = -delta[1] / parent_w
                new_width = clamp(drag_start_inset_width[] + width_delta, min_frac, 1.0)
                # Adjust halign to keep right edge fixed
                old_right = drag_start_halign[] + drag_start_inset_width[] * (1 - drag_start_halign[])
                new_halign = (old_right - new_width) / (1 - new_width)
                new_halign = clamp(new_halign, 0, 1)
            elseif edge in (:inset_right, :inset_topright, :inset_bottomright)
                # Dragging right edge: increase width, adjust halign
                width_delta = delta[1] / parent_w
                new_width = clamp(drag_start_inset_width[] + width_delta, min_frac, 1.0)
                # Adjust halign to keep left edge fixed
                old_left = drag_start_halign[] * (1 - drag_start_inset_width[])
                new_halign = old_left / (1 - new_width)
                new_halign = clamp(new_halign, 0, 1)
            end

            # Handle height changes
            if edge in (:inset_bottom, :inset_bottomleft, :inset_bottomright)
                # Dragging bottom edge: decrease height, adjust valign
                height_delta = -delta[2] / parent_h
                new_height = clamp(drag_start_inset_height[] + height_delta, min_frac, 1.0)
                # Adjust valign to keep top edge fixed
                old_top = drag_start_valign[] + drag_start_inset_height[] * (1 - drag_start_valign[])
                new_valign = (old_top - new_height) / (1 - new_height)
                new_valign = clamp(new_valign, 0, 1)
            elseif edge in (:inset_top, :inset_topleft, :inset_topright)
                # Dragging top edge: increase height, adjust valign
                height_delta = delta[2] / parent_h
                new_height = clamp(drag_start_inset_height[] + height_delta, min_frac, 1.0)
                # Adjust valign to keep bottom edge fixed
                old_bottom = drag_start_valign[] * (1 - drag_start_inset_height[])
                new_valign = old_bottom / (1 - new_height)
                new_valign = clamp(new_valign, 0, 1)
            end

            inset_width_obs[] = new_width
            inset_height_obs[] = new_height
            inset_halign[] = new_halign
            inset_valign[] = new_valign

            return Consume(true)
        elseif dragging_edge[] != :none
            # Convert pixel delta to data delta using viewport-relative coords
            vp_offset = Point2f(minimum(scene.viewport[]))
            current_rel = mouse_px .- vp_offset
            start_rel = drag_start_pos[] .- vp_offset

            current_data = Point2f(project(scene, :pixel, :data, current_rel)[1:2])
            start_data = Point2f(project(scene, :pixel, :data, start_rel)[1:2])
            delta_data = current_data - start_data

            r = drag_start_rect[]
            mi = collect(minimum(r))
            ma = collect(maximum(r))

            edge = dragging_edge[]
            min_size = 0.01 * max(ma[1] - mi[1], ma[2] - mi[2])

            if edge == :inside
                # Move the whole rectangle
                mi[1] += delta_data[1]
                mi[2] += delta_data[2]
                ma[1] += delta_data[1]
                ma[2] += delta_data[2]
            else
                if edge == :left || edge == :topleft || edge == :bottomleft
                    mi[1] = min(mi[1] + delta_data[1], ma[1] - min_size)
                end
                if edge == :right || edge == :topright || edge == :bottomright
                    ma[1] = max(ma[1] + delta_data[1], mi[1] + min_size)
                end
                if edge == :bottom || edge == :bottomleft || edge == :bottomright
                    mi[2] = min(mi[2] + delta_data[2], ma[2] - min_size)
                end
                if edge == :top || edge == :topleft || edge == :topright
                    ma[2] = max(ma[2] + delta_data[2], mi[2] + min_size)
                end
            end

            zoom_rect[] = Rect2f(Point2f(mi...), Vec2f(ma[1] - mi[1], ma[2] - mi[2]))

            return Consume(true)
        end

        # Hover feedback - update rect appearance based on mouse position
        edge = detect_edge(mouse_px, zoom_rect, scene, edge_threshold)
        if edge != :none
            rect_plot.strokewidth = strokewidth * 1.5
        else
            rect_plot.strokewidth = strokewidth
        end

        return Consume(false)
    end

    return ZoomInset(ax, ax_inset, zoom_rect, inset_halign, inset_valign, rect_plot, lines_plot)
end
