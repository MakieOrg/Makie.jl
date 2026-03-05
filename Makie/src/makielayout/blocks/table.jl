# ===== TABLE PLOT RECIPE =====
# A recipe that renders tabular data efficiently with one poly, one text, and one linesegments plot

# Convert any tabular data to Dict{Symbol, Any} for type stability
function convert_arguments(::Type{<:TablePlot}, data::NamedTuple)
    return (Dict{Symbol, Any}(pairs(data)),)
end

function convert_arguments(::Type{<:TablePlot}, data::Dict{Symbol})
    return (Dict{Symbol, Any}(data),)
end

@recipe TablePlot (data::Dict{Symbol, Any},) begin
    # Data
    column_names = automatic
    column_widths = :auto  # :auto (equal), :fit (auto-size), or Vector of widths
    row_heights = automatic  # automatic (uniform) or Vector of heights

    # Selection & sorting (inputs that can change)
    i_selected = 0           # Selected row (0 = none)
    i_selected_cell = (0, 0) # Selected cell as (row, col), (0,0) = none
    hovered_row = 0
    hovered_cell = (0, 0)    # Hovered cell as (row, col)
    sort_column = 0
    sort_direction = :ascending
    scroll_offset = 0

    # Geometry
    bbox = Rect2d(0, 0, 200, 200)
    header_height = 30.0
    row_height = 25.0
    cell_padding = Vec4f(8, 8, 4, 4)  # left, right, top, bottom
    max_visible_rows = nothing

    # Header styling
    header_color = RGBf(0.2, 0.2, 0.2)
    header_textcolor = :white
    header_fontsize = 14.0f0
    show_sort_indicator = true

    # Cell styling - can be single color, or matrix for per-cell colors
    cell_color = automatic  # automatic uses even/odd, or Matrix{<:Colorant} for per-cell
    cell_color_even = RGBf(0.98, 0.98, 0.98)
    cell_color_odd = RGBf(0.94, 0.94, 0.94)
    cell_color_hover = COLOR_ACCENT_DIMMED[]
    cell_color_selected = COLOR_ACCENT[]
    cell_textcolor = :black  # single color or Matrix for per-cell
    cell_fontsize = 12.0f0

    # Grid
    show_grid = true
    grid_color = RGBf(0.8, 0.8, 0.8)
    grid_linewidth = 1.0
    show_vertical_lines = true
    show_horizontal_lines = true

    mixin_generic_plot_attributes()...
end

function plot!(p::TablePlot)
    # The recipe's attributes IS a ComputeGraph, so we use it directly
    attr = p.attributes

    # ===== COMPUTED NODES =====
    # All computations use map! on the attribute graph

    # Basic dimensions from data
    map!(attr, :data, :n_cols) do data
        length(keys(data))
    end

    map!(attr, :data, :n_rows) do data
        cols = values(data)
        isempty(cols) ? 0 : length(first(cols))
    end

    # Column keys (for consistent ordering with Dict)
    map!(attr, [:data, :column_names], :col_keys) do data, names
        names === automatic ? collect(keys(data)) : collect(Symbol.(names))
    end

    # Column names for display
    map!(attr, :col_keys, :col_names) do col_keys
        String.(col_keys)
    end

    # Sort permutation - recomputed when sort settings or data change
    map!(attr, [:sort_column, :sort_direction, :data, :n_rows, :col_keys], :sort_perm) do col, dir, data, nr, col_keys
        if col == 0 || nr == 0 || col > length(col_keys)
            collect(1:nr)
        else
            col_data = data[col_keys[col]]
            sortperm(col_data; rev = (dir == :descending))
        end
    end

    # Visible rows based on max setting
    map!(attr, [:n_rows, :max_visible_rows], :visible_rows) do nr, mvr
        mvr === nothing ? nr : min(nr, mvr)
    end

    # Column widths - computed from bbox and settings
    # Note: :fit mode requires calling auto_fit_columns! after first render
    map!(attr, [:bbox, :n_cols, :column_widths], :col_widths) do bbox, nc, cw
        w = width(bbox)
        if nc == 0
            Float32[]
        elseif cw === :auto || cw === :fit
            # :auto and :fit both start with equal widths
            # :fit is updated by auto_fit_columns! after text is rendered
            fill(Float32(w / nc), nc)
        elseif cw isa Number
            fill(Float32(cw), nc)
        else
            Float32.(cw)
        end
    end

    # Row heights - can be uniform or per-row
    map!(attr, [:visible_rows, :row_height, :row_heights], :row_height_vec) do vr, default_rh, rh
        if rh === automatic
            fill(Float32(default_rh), vr)
        elseif rh isa Number
            fill(Float32(rh), vr)
        else
            # Vector provided - pad or truncate to visible rows
            n = length(rh)
            if n >= vr
                Float32.(rh[1:vr])
            else
                vcat(Float32.(rh), fill(Float32(default_rh), vr - n))
            end
        end
    end

    # Table dimensions (for layout feedback)
    map!(attr, [:visible_rows, :header_height, :col_widths, :row_height_vec], [:table_width, :table_height]) do vr, hh, cw, rhv
        w = isempty(cw) ? 200.0f0 : sum(cw)
        h = Float32(hh + (isempty(rhv) ? 0.0f0 : sum(rhv)))
        (w, h)
    end

    # ===== GEOMETRY - single computation for all positions =====
    # Using scatter with BezierPath rectangle marker is more efficient than poly for many rects
    map!(attr, [
        :bbox, :data, :col_widths, :col_names, :col_keys, :sort_perm,
        :n_cols, :n_rows, :visible_rows, :scroll_offset,
        :row_height_vec, :header_height, :cell_padding,
        :show_grid, :show_horizontal_lines, :show_vertical_lines,
        :sort_column, :sort_direction, :show_sort_indicator
    ], [:cell_positions, :cell_sizes, :text_positions, :text_strings, :line_points]) do bbox, data, cw, col_names, col_keys, perm, nc, nr, vr, offset, rhv, hh, pad, show_grid, show_h, show_v, sort_col, sort_dir, show_indicator

        # Empty table
        (nc == 0 || isempty(cw)) && return (Point2f[], Vec2f[], Point2f[], String[], Point2f[])

        n_rects = nc + nc * vr
        cell_pos = Vector{Point2f}(undef, n_rects)  # top-left corner positions
        cell_sz = Vector{Vec2f}(undef, n_rects)     # (width, height) for markersize
        text_pos = Vector{Point2f}(undef, n_rects)
        text_str = Vector{String}(undef, n_rects)

        x0, y_top = left(bbox), top(bbox)

        # Column x positions (cumulative)
        col_x = zeros(Float32, nc)
        nc > 1 && cumsum!(@view(col_x[2:end]), @view(cw[1:end-1]))

        # Row y positions (cumulative from top, going down)
        row_y = zeros(Float32, vr + 1)
        row_y[1] = y_top - hh
        for i in 1:vr
            row_y[i + 1] = row_y[i] - rhv[i]
        end

        # Header - position at top-left of each header cell
        for col in 1:nc
            x, w = x0 + col_x[col], cw[col]
            cell_pos[col] = Point2f(x, y_top)  # top-left
            cell_sz[col] = Vec2f(w, hh)
            text_pos[col] = Point2f(x + pad[1], y_top - hh/2)
            hdr = col_names[col]
            show_indicator && sort_col == col && (hdr *= sort_dir == :ascending ? " ↑" : " ↓")
            text_str[col] = hdr
        end

        # Cells - use col_keys to access data consistently
        for row in 1:vr
            actual_row = row + offset <= length(perm) ? perm[row + offset] : row + offset
            rh = rhv[row]
            y_cell_top = row_y[row]  # top of this row
            for col in 1:nc
                idx = nc + (row - 1) * nc + col
                x, w = x0 + col_x[col], cw[col]
                cell_pos[idx] = Point2f(x, y_cell_top)  # top-left
                cell_sz[idx] = Vec2f(w, rh)
                text_pos[idx] = Point2f(x + pad[1], y_cell_top - rh/2)
                text_str[idx] = actual_row <= nr ? string(data[col_keys[col]][actual_row]) : ""
            end
        end

        # Grid lines
        lines = Point2f[]
        if show_grid
            total_w = sum(cw)
            total_h = hh + sum(rhv)
            if show_h
                # Header bottom line
                push!(lines, Point2f(x0, y_top - hh), Point2f(x0 + total_w, y_top - hh))
                # Row bottom lines
                for row in 1:vr
                    y = row_y[row + 1]
                    push!(lines, Point2f(x0, y), Point2f(x0 + total_w, y))
                end
            end
            if show_v
                for col in 1:nc+1
                    x = x0 + (col <= nc ? col_x[col] : total_w)
                    push!(lines, Point2f(x, y_top), Point2f(x, y_top - total_h))
                end
            end
        end

        (cell_pos, cell_sz, text_pos, text_str, lines)
    end

    # ===== COLORS - separate from geometry for efficient hover/selection updates =====
    # Supports both row-level and cell-level selection/hover
    map!(attr, [
        :n_cols, :visible_rows, :scroll_offset, :sort_perm,
        :i_selected, :i_selected_cell, :hovered_row, :hovered_cell,
        :header_color, :cell_color, :cell_color_even, :cell_color_odd, :cell_color_hover, :cell_color_selected
    ], :rect_colors) do nc, vr, offset, perm, selected_row, selected_cell, hovered_row, hovered_cell, hdr_c, cell_c, even_c, odd_c, hover_c, sel_c

        n_rects = nc + nc * vr
        colors = Vector{RGBAf}(undef, n_rects)
        nc == 0 && return colors

        hdr_color = to_color(hdr_c)
        for i in 1:nc
            colors[i] = hdr_color
        end

        # Check if cell_color is a matrix (per-cell coloring)
        use_matrix = cell_c isa AbstractMatrix
        sel_cell_row, sel_cell_col = selected_cell
        hov_cell_row, hov_cell_col = hovered_cell

        for row in 1:vr
            actual_row = row + offset <= length(perm) ? perm[row + offset] : row + offset
            for col in 1:nc
                idx = nc + (row - 1) * nc + col
                # Priority: cell selection > row selection > cell hover > row hover > matrix color > alternating
                colors[idx] = if sel_cell_row == actual_row && sel_cell_col == col
                    # Cell-level selection (highest priority)
                    to_color(sel_c)
                elseif actual_row == selected_row
                    # Row-level selection
                    to_color(sel_c)
                elseif hov_cell_row == row && hov_cell_col == col
                    # Cell-level hover
                    to_color(hover_c)
                elseif row == hovered_row
                    # Row-level hover
                    to_color(hover_c)
                elseif use_matrix && actual_row <= size(cell_c, 1) && col <= size(cell_c, 2)
                    to_color(cell_c[actual_row, col])
                elseif iseven(row)
                    to_color(even_c)
                else
                    to_color(odd_c)
                end
            end
        end
        colors
    end

    # Text styling - supports per-cell text colors via matrix
    map!(attr, [:n_cols, :visible_rows, :scroll_offset, :sort_perm,
                :header_textcolor, :cell_textcolor, :header_fontsize, :cell_fontsize],
         [:text_colors, :text_fontsizes]) do nc, vr, offset, perm, hdr_tc, cell_tc, hdr_fs, cell_fs

        n = nc + nc * vr
        colors = Vector{RGBAf}(undef, n)
        sizes = Vector{Float32}(undef, n)

        hdr_c = to_color(hdr_tc)
        for i in 1:nc
            colors[i], sizes[i] = hdr_c, hdr_fs
        end

        # Check if cell_textcolor is a matrix
        use_matrix = cell_tc isa AbstractMatrix
        default_cell_c = use_matrix ? to_color(:black) : to_color(cell_tc)

        for row in 1:vr
            actual_row = row + offset <= length(perm) ? perm[row + offset] : row + offset
            for col in 1:nc
                idx = nc + (row - 1) * nc + col
                sizes[idx] = cell_fs
                if use_matrix && actual_row <= size(cell_tc, 1) && col <= size(cell_tc, 2)
                    colors[idx] = to_color(cell_tc[actual_row, col])
                else
                    colors[idx] = default_cell_c
                end
            end
        end
        (colors, sizes)
    end

    # ===== CHILD PLOTS - pass computed nodes directly =====

    # Rectangle marker: draws from (0,0) going right and down
    # Position is top-left, markersize is (width, height)
    rect_marker = BezierPath([
        MoveTo(0, 0),
        LineTo(1, 0),
        LineTo(1, -1),
        LineTo(0, -1),
        ClosePath()
    ])

    # Single scatter for all cell rectangles (more efficient than poly for many rects)
    scatter!(p, attr[:cell_positions];
        marker = rect_marker,
        markersize = attr[:cell_sizes],
        color = attr[:rect_colors],
        markerspace = :data,
        inspectable = false
    )

    # Single text for all labels
    tp = text!(p, attr[:text_positions];
        text = attr[:text_strings],
        color = attr[:text_colors],
        fontsize = attr[:text_fontsizes],
        align = (:left, :center),
        inspectable = false
    )
    translate!(tp, 0, 0, 1)

    # Single linesegments for grid
    lp = linesegments!(p, attr[:line_points];
        color = attr[:grid_color],
        linewidth = attr[:grid_linewidth],
        inspectable = false
    )
    translate!(lp, 0, 0, 0.5)

    return p
end

# ===== HELPER FUNCTIONS FOR INTERACTION =====
# These work with the plot's ComputeGraph

function table_row_at_position(p::TablePlot, mp::Point2f)
    attr = p.attributes
    bbox = attr[:bbox][]
    hh = attr[:header_height][]
    rh = attr[:row_height][]
    y_top = top(bbox)

    mp[2] > y_top - hh && return :header

    y_offset = y_top - hh - mp[2]
    row = floor(Int, y_offset / rh) + 1
    vr = attr[:visible_rows][]
    (row >= 1 && row <= vr) ? row : 0
end

function table_col_at_position(p::TablePlot, mp::Point2f)
    attr = p.attributes
    cw = attr[:col_widths][]
    isempty(cw) && return 0

    x_offset = mp[1] - left(attr[:bbox][])
    cumw = cumsum(cw)
    for (i, cx) in enumerate(cumw)
        x_offset <= cx && return i
    end
    0
end

function is_inside_table(p::TablePlot, mp::Point2f)
    attr = p.attributes
    bbox = attr[:bbox][]
    th = attr[:table_height][]
    mp[1] >= left(bbox) && mp[1] <= right(bbox) && mp[2] <= top(bbox) && mp[2] >= top(bbox) - th
end

# Get actual data row from visual row (accounting for sort and scroll)
function get_actual_row(p::TablePlot, visual_row::Int)
    attr = p.attributes
    perm = attr[:sort_perm][]
    offset = attr[:scroll_offset][]
    idx = visual_row + offset
    idx <= length(perm) ? perm[idx] : 0
end

# Get row data as NamedTuple
function get_row_data(p::TablePlot, row_idx::Int)
    attr = p.attributes
    data = attr[:data][]
    nr = attr[:n_rows][]
    col_keys = attr[:col_keys][]
    row_idx <= nr ? NamedTuple{Tuple(col_keys)}(Tuple(data[k][row_idx] for k in col_keys)) : nothing
end

# Get cell data at (row, col)
function get_cell_data(p::TablePlot, row_idx::Int, col_idx::Int)
    attr = p.attributes
    data = attr[:data][]
    nr = attr[:n_rows][]
    col_keys = attr[:col_keys][]
    (row_idx <= nr && col_idx <= length(col_keys)) ? data[col_keys[col_idx]][row_idx] : nothing
end

"""
    auto_fit_columns!(p::TablePlot)

Automatically resize columns to fit their content based on text bounding boxes.
Call this after the table has been rendered at least once.
"""
function auto_fit_columns!(p::TablePlot)
    # Get the text plot (third child: poly, lines, text)
    text_plot = p.plots[2]::Text

    attr = p.attributes
    nc = attr[:n_cols][]
    vr = attr[:visible_rows][]
    pad = attr[:cell_padding][]

    nc == 0 && return p

    # Get bounding boxes of all text elements
    bbs = string_boundingboxes(text_plot)

    # Compute max width per column (including header)
    max_widths = zeros(Float32, nc)

    # Header widths (first nc entries)
    for col in 1:nc
        if col <= length(bbs)
            max_widths[col] = max(max_widths[col], bbs[col].widths[1])
        end
    end

    # Cell widths
    for row in 1:vr
        for col in 1:nc
            idx = nc + (row - 1) * nc + col
            if idx <= length(bbs)
                max_widths[col] = max(max_widths[col], bbs[idx].widths[1])
            end
        end
    end

    # Add padding
    max_widths .+= pad[1] + pad[2]

    # Update column widths
    update!(attr; column_widths = max_widths)

    return p
end

"""
    auto_fit_rows!(p::TablePlot)

Automatically resize rows to fit their content based on text bounding boxes.
Call this after the table has been rendered at least once.
"""
function auto_fit_rows!(p::TablePlot)
    text_plot = p.plots[2]::Text

    attr = p.attributes
    nc = attr[:n_cols][]
    vr = attr[:visible_rows][]
    pad = attr[:cell_padding][]

    vr == 0 && return p

    # Get bounding boxes
    bbs = string_boundingboxes(text_plot)

    # Compute max height per row
    max_heights = zeros(Float32, vr)

    for row in 1:vr
        for col in 1:nc
            idx = nc + (row - 1) * nc + col
            if idx <= length(bbs)
                max_heights[row] = max(max_heights[row], bbs[idx].widths[2])
            end
        end
    end

    # Add padding
    max_heights .+= pad[3] + pad[4]

    # Update row heights
    update!(attr; row_heights = max_heights)

    return p
end


# ===== TABLE BLOCK INITIALIZATION =====

function initialize_block!(t::Table)
    scene = t.blockscene

    # Create the TablePlot recipe - its attributes form a ComputeGraph
    plot = tableplot!(
        scene,
        t.data;
        column_names = t.column_names,
        column_widths = t.column_widths,
        row_heights = t.row_heights,
        i_selected = t.i_selected,
        i_selected_cell = t.i_selected_cell,
        sort_column = t.sort_column,
        sort_direction = t.sort_direction,
        scroll_offset = t.scroll_offset,
        max_visible_rows = t.max_visible_rows,
        header_color = t.header_color,
        header_textcolor = t.header_textcolor,
        header_fontsize = t.header_fontsize,
        header_height = t.header_height,
        show_sort_indicator = t.show_sort_indicator,
        cell_color = t.cell_color,
        cell_color_even = t.cell_color_even,
        cell_color_odd = t.cell_color_odd,
        cell_color_hover = t.cell_color_hover,
        cell_color_selected = t.cell_color_selected,
        cell_textcolor = t.cell_textcolor,
        cell_fontsize = t.cell_fontsize,
        row_height = t.row_height,
        cell_padding = t.cell_padding,
        show_grid = t.show_grid,
        grid_color = t.grid_color,
        grid_linewidth = t.grid_linewidth,
        show_vertical_lines = t.show_vertical_lines,
        show_horizontal_lines = t.show_horizontal_lines,
        inspectable = false
    )

    attr = plot.attributes
    last_autosize = Ref((0.0f0, 0.0f0))

    # Sync bbox from layout → plot's ComputeGraph (update existing input)
    on(scene, t.layoutobservables.computedbbox) do cbb
        update!(attr; bbox = Rect2d(origin(cbb), widths(cbb)))
        # Sync autosize back to layout, but only if changed (prevents infinite loop)
        w = attr[:table_width][]
        h = attr[:table_height][]
        new_size = (w, h)
        if new_size != last_autosize[]
            last_autosize[] = new_size
            t.layoutobservables.autosize[] = new_size
        end
    end

    # ===== EVENT HANDLING =====
    e = scene.events
    last_click_time = Ref(0.0)
    last_click_cell = Ref((0, 0))
    was_inside = Ref(false)

    # Mouse position + button handler (priority to consume events)
    onany(scene, e.mouseposition, e.mousebutton; priority = 63) do position, butt
        mp = screen_relative(scene, position)

        if !is_inside_table(plot, mp)
            if was_inside[]
                was_inside[] = false
                update!(attr; hovered_row = 0, hovered_cell = (0, 0))
            end
            return Consume(false)
        end

        was_inside[] = true
        row = table_row_at_position(plot, mp)
        col = table_col_at_position(plot, mp)

        # Update hover state (both row and cell level)
        if row isa Int && row > 0 && col > 0
            update!(attr; hovered_row = row, hovered_cell = (row, col))
        else
            update!(attr; hovered_row = row isa Int ? row : 0, hovered_cell = (0, 0))
        end

        # Handle left clicks
        if butt.button == Mouse.left && butt.action == Mouse.press
            if row == :header && col > 0 && t.sortable[]
                # Sort by column
                current_col = attr[:sort_column][]
                if current_col == col
                    new_dir = attr[:sort_direction][] == :ascending ? :descending : :ascending
                    update!(attr; sort_direction = new_dir)
                else
                    update!(attr; sort_column = col, sort_direction = :ascending)
                end

                cb = t.on_sort_change[]
                cb !== nothing && cb(t, col, attr[:sort_direction][])
                return Consume(true)

            elseif row isa Int && row > 0 && col > 0
                actual_row = get_actual_row(plot, row)
                current_time = time()

                # Double click check (same cell)
                if current_time - last_click_time[] < 0.3 && last_click_cell[] == (actual_row, col)
                    cb = t.on_row_doubleclick[]
                    cb !== nothing && cb(t, actual_row, get_row_data(plot, actual_row))
                else
                    # Single click - select row and cell
                    update!(attr; i_selected = actual_row, i_selected_cell = (actual_row, col))
                    t.selection[] = get_row_data(plot, actual_row)
                    t.cell_selection[] = get_cell_data(plot, actual_row, col)

                    # Row click callback
                    cb = t.on_row_click[]
                    cb !== nothing && cb(t, actual_row, t.selection[])

                    # Cell click callback
                    cb_cell = t.on_cell_click[]
                    cb_cell !== nothing && cb_cell(t, actual_row, col, t.cell_selection[])
                end

                last_click_time[] = current_time
                last_click_cell[] = (actual_row, col)
                return Consume(true)
            end

        # Handle right clicks
        elseif butt.button == Mouse.right && butt.action == Mouse.press
            if row isa Int && row > 0 && col > 0
                actual_row = get_actual_row(plot, row)
                cell_data = get_cell_data(plot, actual_row, col)

                cb = t.on_cell_rightclick[]
                cb !== nothing && cb(t, actual_row, col, cell_data)
                return Consume(true)
            end
        end

        return Consume(false)
    end

    # Scroll handling
    on(scene, e.scroll; priority = 62) do (x, y)
        mp = screen_relative(scene, e.mouseposition[])

        if is_inside_table(plot, mp)
            nr = attr[:n_rows][]
            vr = attr[:visible_rows][]
            max_offset = max(0, nr - vr)

            step = round(Int, t.scroll_speed[] * sign(y))
            current = attr[:scroll_offset][]
            new_offset = clamp(current - step, 0, max_offset)

            if new_offset != current
                update!(attr; scroll_offset = new_offset)
                return Consume(true)
            end
        end
        return Consume(false)
    end

    return nothing
end
