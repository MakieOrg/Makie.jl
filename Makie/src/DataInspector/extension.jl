################################################################################
### BarPlot, Hist
################################################################################

function get_accessor(plot::BarPlot, idx, plot_stack)
    idx, N = fast_submesh_index(first(plot_stack), idx, Base.tail(plot_stack))
    return IndexedAccessor(idx, N)
end

function get_accessor(plot::BarPlot, idx, plot_stack::Tuple{<:Text, Vararg{Plot}})
    a = get_accessor(first(plot_stack), idx, Base.tail(plot_stack))
    return PlotElement((plot, plot.plots[1]), a)
end

# TODO:
# Once barplot is refactored to use the compute graph, grab positions after
# stack & dodge here and add a label_data method using these positions instead
function get_tooltip_position(element::PlotElement{<:BarPlot})
    x, y = element.positions
    y += element.offset
    return ifelse(element.direction == :x, Point(y, x), Point(x, y))
end

get_default_tooltip_label(element::PlotElement{<:BarPlot}, pos) = element.positions

function get_default_tooltip_label(element::PlotElement{<:Hist}, pos)
    # Undo flips (+ -> - bin height)
    # TODO: Should we undo more here? E.g. normalization, weights, ...?
    bin_pos, bin_height = child(element).positions
    return Point(bin_pos, abs(bin_height))
end

function update_indicator!(di::DataInspector2, element::PlotElement{<:BarPlot}, pos)
    poly_element = child(element)
    rect = poly_element.arg1
    ps = to_ndim.(Point3d, convert_arguments(Lines, rect)[1], 0)

    indicator = get_indicator_plot(di, Lines)
    update!(indicator, arg1 = ps, visible = true)

    return
end

################################################################################
### Arrows
################################################################################

function get_accessor(plot::Arrows2D, idx, plot_stack)
    idx, N = fast_submesh_index(first(plot_stack), idx, Base.tail(plot_stack))
    N_components = sum(plot.should_component_render[])
    idx = fld1(idx, N_components)
    N = fld1(N, N_components)
    return IndexedAccessor(idx, N)
end

function get_tooltip_position(element::PlotElement{<:Union{Arrows2D, Arrows3D}})
    return 0.5 * (element.startpoints + element.endpoints)
end

function get_default_tooltip_label(element::PlotElement{<:Union{Arrows2D, Arrows3D}}, pos)
    return pos, element.endpoints - element.startpoints
end

################################################################################
### Contour, Contour4d, Contourf, Tricontourf
################################################################################

function get_default_tooltip_label(element::PlotElement{<:Union{Contourf, Tricontourf}}, pos)
    return child(element).color
end

function get_default_tooltip_label(element::PlotElement{<:Union{Contour, Contour3d}}, pos)
    rgba_color = child(element).color
    selected = Vec4f(red(rgba_color), green(rgba_color), blue(rgba_color), alpha(rgba_color))
    _, idx = findmin(get_plot(element).level_colors[]) do c
        v = Vec4f(red(c), green(c), blue(c), alpha(c))
        return norm(v - selected)
    end
    return get_plot(element).zlevels[][idx]
end

function update_indicator!(di::DataInspector2, element::PlotElement{<:Contourf}, pos)
    poly_element = child(element)
    polygon = poly_element.arg1
    # Careful, convert_arguments() may return just return exterior (===)
    line_collection = copy(convert_arguments(Lines, polygon.exterior)[1])
    for int in polygon.interiors
        push!(line_collection, Point2f(NaN))
        append!(line_collection, convert_arguments(PointBased(), int)[1])
    end
    ps = to_ndim.(Point3d, line_collection, 0)

    indicator = get_indicator_plot(di, Lines)
    update!(indicator, arg1 = ps, visible = true)

    return
end


################################################################################
### Error & Rangebars
################################################################################

function get_accessor(plot::Union{Errorbars, Rangebars}, idx, plot_stack)
    return IndexedAccessor(fld1(idx, 2), length(plot.val_low_high[]))
end

function get_tooltip_position(element::PlotElement{<:Errorbars})
    x, y, low, high = element.val_low_high
    return Point(x, y)
end

function get_tooltip_position(element::PlotElement{<:Rangebars})
    plot = get_plot(element)
    i = 2 * accessor(element).index[1]
    linepoints = plot.linesegpairs[]
    center = 0.5 * (linepoints[i - 1] .+ linepoints[i])
    return center
end

function get_default_tooltip_label(formatter, element::PlotElement{<:Errorbars}, pos)
    x, y, low, high = element.val_low_high
    if low ≈ high
        return "±" * apply_tooltip_format(formatter, low)
    else
        return "+" * apply_tooltip_format(formatter, (high, -low))
    end
end

function get_default_tooltip_label(formatter, element::PlotElement{<:Rangebars}, pos)
    plot = get_plot(element)
    i = 2 * accessor(element).index[1]
    linepoints = plot.linesegpairs[]
    dim = 1 + plot.is_in_y_direction[]
    low = apply_tooltip_format(formatter, linepoints[i - 1][dim])
    high = apply_tooltip_format(formatter, linepoints[i][dim])
    return low * " .. " * high
end

################################################################################
### Band & Density
################################################################################

function get_accessor(plot::Band, idx, plot_stack)
    meshplot = first(plot_stack)

    # find selected triangle
    ray = transform(inv(meshplot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    ps = meshplot.positions_transformed_f32c[]
    face, face_index, pos = find_picked_triangle(ps, meshplot.faces[], ray, idx)

    N = div(length(ps), 2)

    if isnan(pos)
        # if triangles get very thin the triangle intersection may not find an
        # intersection. In this case interpolation doesn't matter.
        return InterpolatedAccessor(mod1(idx, N), mod1(idx, N), 0.0, N)
    end

    # Get index of of the quad/first point in ps1/ps2
    idx = mod1(face_index, N - 1)

    if eltype(plot[1][]) <: VecTypes{3}
        # TODO: 3D case
        # This needs an algorithm that can find an interpolation parameter f
        # such that pos is on the line
        #   (ps[idx] + f * ps[idx+1]) .. (ps[idx + N + 1] + f * ps[idx + N])
        return InterpolatedAccessor(idx, idx + 1, 0.5, N)
    else
        # interpolate to quad paramater
        f = point_in_quad_parameter(ps[idx], ps[idx + 1], ps[idx + N + 1], ps[idx + N], to_ndim(Point2d, pos, 0))

        return InterpolatedAccessor(idx, idx + 1, f, N)
    end
end

function get_accessor(plot::Density, idx, plot_stack::Tuple{<:Lines, Vararg{Plot}})
    a = get_accessor(first(plot_stack), idx, Base.tail(plot_stack))
    upper = plot.upper[]
    N = length(upper)
    # The outline can be closed, which adds [lower[end], lower[1], upper[1]] to
    # close the loop. To get back to indices of upper (which contains density
    # information) we need to figure out related indices in the 1 .. N range
    if a.index1[1] > N
        if a.index1[1] == N + 3
            return InterpolatedAccessor(1, 2, 0.0, N)
        elseif  a.index1[1] == N + 1
            return InterpolatedAccessor(N-1, N, 1.0, N)
        else
            picked_pos = element_getindex(plot.linepoints[], a)
            dim = 1 + (plot.direction[] == :y)
            i = findfirst(p -> p[dim] > picked_pos[dim], upper)
            if i == 1
                return InterpolatedAccessor(1, 2, 0.0, N)
            end
            f = (picked_pos[dim] - upper[i - 1][dim]) / (upper[i][dim] - upper[i - 1][dim])
            return InterpolatedAccessor(i-1, i, f, N)
        end
    end
    return a
end

function get_tooltip_position(element::PlotElement{<:Band})
    return 0.5(element.lowerpoints + element.upperpoints)
end

function get_tooltip_position(element::PlotElement{<:Density})
    return element.upper
end

function get_default_tooltip_label(element::PlotElement{<:Band}, pos)
    return element.upperpoints, element.lowerpoints
end

function get_default_tooltip_label(element::PlotElement{<:Density}, pos)
    if element.direction == :y
        return Vec(pos[2], pos[1])
    else
        return pos
    end
end

function update_indicator!(di::DataInspector2, element::PlotElement{<:Band}, pos)
    p1 = to_ndim(Point3d, element.lowerpoints, 0)
    p2 = to_ndim(Point3d, element.upperpoints, 0)

    indicator = get_indicator_plot(di, LineSegments)
    update!(indicator, arg1 = [p1, p2], visible = true)

    return
end

################################################################################
### Violin
################################################################################

get_accessor(plot::Violin, idx, plot_stack::Tuple{<:LineSegments, Vararg{Plot}}) = nothing

function get_accessor(plot::Violin, idx, plot_stack::Tuple{<:Poly, Vararg{Plot}})
    # Each violin/density becomes one submesh
    violin_idx, N_violins = fast_submesh_index(first(plot_stack), idx, Base.tail(plot_stack))

    # Within a violin/density we have (value, density) pairs either as (x, y) or
    # (y, x) depending on orientation. Find the closest two values to the current
    # mouseposition to derive another index + interpolation factor. These can
    # then be used to sample values & densities later
    meshplot = plot.plots[1].plots[1]
    mpos = (inv(meshplot.model_f32c[]) * to_ndim(Point4d, mouseposition(plot), 1))[Vec(1, 2)]
    dim = 1 + (plot.orientation[] !== :horizontal)

    # range of vertices relevant to the picked violin/density
    violin_start = mapreduce(i -> length(plot.vertices[][i]), +, 1 : (violin_idx - 1), init = 1)
    N = length(plot.vertices[][violin_idx])
    violin_range = violin_start : (violin_start + N - 1)

    # Relevant vertex positions after transform_func f32c, pre model_f32c application
    verts = view(meshplot.positions_transformed_f32c[], violin_range)

    # Find two closest indices & interpolation factor between them
    _, point_idx = findmin(p -> abs(p[dim] - mpos[dim]), verts)
    if point_idx == 1
        f = (mpos[dim] - verts[1][dim]) / (verts[2][dim] - verts[1][dim])
        return ViolinAccessor(violin_idx, N_violins, 1, 2, f, N)

    elseif point_idx == N
        f = (mpos[dim] - verts[end - 1][dim]) / (verts[end][dim] - verts[end - 1][dim])
        return ViolinAccessor(violin_idx, N_violins, N - 1, N, f, N)

    elseif abs(verts[point_idx - 1][dim] - mpos[dim]) < abs(verts[point_idx + 1][dim] - mpos[dim])
        f = (mpos[dim] - verts[point_idx - 1][dim]) / (verts[point_idx][dim] - verts[point_idx - 1][dim])
        return ViolinAccessor(violin_idx, N_violins, point_idx - 1, point_idx, f, N)

    else
        f = (mpos[dim] - verts[point_idx][dim]) / (verts[point_idx + 1][dim] - verts[point_idx][dim])
        return ViolinAccessor(violin_idx, N_violins, point_idx, point_idx + 1, f, N)
    end
end

function get_tooltip_position(element::PlotElement{<:Violin})
    return element.vertices
end

function get_default_tooltip_label(element::PlotElement{<:Violin}, pos)
    spec = element.specs # applies group index
    density = element_getindex(spec.kde.density, element) # applies interpolation
    return density
end

################################################################################
### Spy, Hexbin, Pie, VolumeSlices, datashader
################################################################################

get_accessor(plot::Spy, idx, plot_stack::Tuple{<:Lines}) = nothing

get_default_tooltip_label(element::PlotElement{<:Spy}, pos) = child(element).color

get_default_tooltip_label(element::PlotElement{<:Hexbin}, pos) = element.count_hex

function get_default_tooltip_label(element::PlotElement{<:Pie}, pos)
    return element.values
end

function get_default_tooltip_label(element::PlotElement{<:DataShader}, pos)
    p = get_plot(element)
    data = reshape(p.canvas[].pixelbuffer, p.canvas[].resolution)
    return element_getindex(data, element)
end
