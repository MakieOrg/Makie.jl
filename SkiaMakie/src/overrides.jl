################################################################################
#                    Poly - the not so primitive, primitive                    #
################################################################################

deref(x) = x
deref(x::Base.RefValue) = x[]

function draw_plot(scene::Scene, screen::Screen, poly::Poly)
    if Base.hasmethod(draw_poly, Tuple{Scene, Screen, typeof(poly), typeof.(deref(poly.args[]))...})
        return draw_poly(scene, screen, poly, deref(poly.args[])...)
    elseif Base.hasmethod(draw_poly, Tuple{Scene, Screen, typeof(poly), typeof.(deref(poly.converted[]))...})
        return draw_poly(scene, screen, poly, deref(poly.converted[])...)
    else
        return draw_poly_as_mesh(scene, screen, poly)
    end
end

is_skiamakie_atomic_plot(plot::Poly) = true

function draw_poly_as_mesh(scene, screen, poly)
    for i in eachindex(poly.plots)
        draw_plot(scene, screen, poly.plots[i])
    end
    return
end

########################################
### outline methods (::Vector{<:VecTypes{2}})
########################################

function draw_poly(scene::Scene, screen::Screen, poly, points::Vector{<:Point2})
    color = to_skia_plotcolor(poly.color[], poly)
    strokecolor = to_skia_plotcolor(poly.strokecolor[], poly)
    strokestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())
    miter_limit = to_skia_miter_limit(poly.miter_limit[])
    joinstyle = to_skia_joinstyle(poly.joinstyle[])
    linecap = to_skia_linecap(poly.linecap[])

    draw_poly(
        scene, screen, poly, points, color,
        poly.model[], strokecolor, strokestyle, poly.strokewidth[], miter_limit, joinstyle, linecap
    )
    return
end

function draw_poly(scene::Scene, screen::Screen, poly, points_list::Vector{<:Vector{<:Point2}})
    color = to_skia_plotcolor(poly.color[], poly)
    strokecolor = to_skia_plotcolor(poly.strokecolor[], poly)
    strokestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())
    miter_limit = to_skia_miter_limit(poly.miter_limit[])
    joinstyle = to_skia_joinstyle(poly.joinstyle[])
    linecap = to_skia_linecap(poly.linecap[])

    broadcast_foreach(
        points_list, color,
        strokecolor, strokestyle, poly.strokewidth[], Ref(poly.model[])
    ) do points, color, strokecolor, strokestyle, strokewidth, model
        draw_poly(scene, screen, poly, points, color, model, strokecolor, strokestyle, strokewidth, miter_limit, joinstyle, linecap)
    end
    return
end

draw_poly(scene::Scene, screen::Screen, poly, circle::Circle) = draw_poly(scene, screen, poly, decompose(Point2f, circle))

function draw_poly(
        scene::Scene, screen::Screen, poly, points::Vector{<:Point2}, color::Colorant,
        model, strokecolor, strokestyle, strokewidth, miter_limit, joinstyle, linecap
    )
    space = poly.space[]
    points = apply_transform(transform_func(poly), points)
    points = clip_poly(poly.clip_planes[], points, space, model)
    points = _project_position(scene, space, points, model, true)

    isempty(points) && return

    path = points_to_path(points)

    # Fill
    paint = new_paint(color = to_skia_color(color))
    sk_canvas_draw_path(screen.canvas, path, paint)

    # Stroke
    sk_paint_set_style(paint, SK_PAINT_STYLE_STROKE)
    set_paint_color!(paint, to_color(strokecolor))
    sk_paint_set_stroke_width(paint, Float32(strokewidth))
    sk_paint_set_stroke_join(paint, joinstyle)
    sk_paint_set_stroke_cap(paint, linecap)
    sk_paint_set_stroke_miter(paint, Float32(miter_limit))

    dash_effect = to_skia_dash_effect(strokestyle, strokewidth)
    if dash_effect != C_NULL
        sk_paint_set_path_effect(paint, dash_effect)
    end

    sk_canvas_draw_path(screen.canvas, path, paint)
    sk_paint_delete(paint)
    sk_path_delete(path)
    return
end

function draw_poly(
        scene::Scene, screen::Screen, poly, points, color,
        model, strokecolor, strokestyle, strokewidth, miter_limit, joinstyle, linecap
    )
    return draw_poly_as_mesh(scene, screen, poly)
end

########################################
### GeometryPrimtive and BezierPath methods
########################################

draw_poly(scene::Scene, screen::Screen, poly, rect::Rect2) = draw_poly(scene, screen, poly, [rect])
draw_poly(scene::Scene, screen::Screen, poly, bezierpath::BezierPath) = draw_poly(scene, screen, poly, [bezierpath])

function draw_poly(scene::Scene, screen::Screen, poly, shapes::Vector{<:Union{Rect2, BezierPath}})
    model = poly.model[]::Mat4d
    space = poly.space[]::Symbol
    planes = poly.clip_planes[]::Vector{Plane3f}

    projected_shapes = map(shapes) do shape
        clipped = clip_shape(planes, shape, space, model)
        return project_shape(poly, space, clipped, model)
    end

    color = to_skia_plotcolor(poly.color[], poly)
    linestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())
    strokecolor = to_skia_plotcolor(poly.strokecolor[], poly)
    miter_limit = to_skia_miter_limit(poly.miter_limit[])
    joinstyle = to_skia_joinstyle(poly.joinstyle[])
    linecap = to_skia_linecap(poly.linecap[])

    broadcast_foreach(projected_shapes, color, strokecolor, poly.strokewidth[]) do shape, c, sc, sw
        path = shape_to_skia_path(shape)

        paint = new_paint(color = to_skia_color(c))
        sk_canvas_draw_path(screen.canvas, path, paint)

        sk_paint_set_style(paint, SK_PAINT_STYLE_STROKE)
        set_paint_color!(paint, to_color(sc))
        sk_paint_set_stroke_width(paint, Float32(sw))
        sk_paint_set_stroke_join(paint, joinstyle)
        sk_paint_set_stroke_cap(paint, linecap)
        sk_paint_set_stroke_miter(paint, Float32(miter_limit))

        dash_effect = to_skia_dash_effect(linestyle, sw)
        if dash_effect != C_NULL
            sk_paint_set_path_effect(paint, dash_effect)
        end

        sk_canvas_draw_path(screen.canvas, path, paint)
        sk_paint_delete(paint)
        sk_path_delete(path)
    end
    return
end

function project_shape(scene, space, shape::BezierPath, model)
    commands = Makie.PathCommand[]
    for cmd in shape.commands
        if cmd isa EllipticalArc
            bezier = Makie.elliptical_arc_to_beziers(cmd)
            for b in bezier.commands
                push!(commands, project_command(b, scene, space, model))
            end
        else
            push!(commands, project_command(cmd, scene, space, model))
        end
    end
    return BezierPath(commands)
end

function project_command(m::MoveTo, scene, space, model)
    return MoveTo(project_position(scene, space, m.p, model))
end
function project_command(l::LineTo, scene, space, model)
    return LineTo(project_position(scene, space, l.p, model))
end
function project_command(c::CurveTo, scene, space, model)
    return CurveTo(
        project_position(scene, space, c.c1, model),
        project_position(scene, space, c.c2, model),
        project_position(scene, space, c.p, model),
    )
end
project_command(c::ClosePath, scene, space, model) = c

function shape_to_skia_path(r::Rect2)
    o = origin(r)
    w, h = widths(r)
    path = sk_path_new()
    sk_path_add_rect(path, Ref(sk_rect_t(Float32(o[1]), Float32(o[2]),
        Float32(o[1] + w), Float32(o[2] + h))), SK_PATH_DIRECTION_CW)
    return path
end

function shape_to_skia_path(b::BezierPath)
    return bezierpath_to_skia_path(b)
end

draw_poly(scene::Scene, screen::Screen, poly, polygon::Polygon) = draw_poly(scene, screen, poly, [polygon])
draw_poly(scene::Scene, screen::Screen, poly, multipolygon::MultiPolygon) = draw_poly(scene, screen, poly, multipolygon.polygons)

function draw_poly(scene::Scene, screen::Screen, poly, polygons::AbstractArray{<:Polygon})
    model = poly.model[]
    space = poly.space[]
    projected_polys = map(polygons) do polygon
        return project_polygon(poly, space, polygon, poly.clip_planes[], model)
    end

    color = to_skia_plotcolor(poly.color[], poly)
    strokecolor = to_skia_plotcolor(poly.strokecolor[], poly)
    strokestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())
    miter_limit = to_skia_miter_limit(poly.miter_limit[])
    joinstyle = to_skia_joinstyle(poly.joinstyle[])
    linecap = to_skia_linecap(poly.linecap[])

    broadcast_foreach(projected_polys, color, strokecolor, poly.strokewidth[]) do po, c, sc, sw
        path = polygon_to_skia_path(po)
        paint = new_paint(color = to_skia_color(c))
        sk_canvas_draw_path(screen.canvas, path, paint)
        sk_paint_set_style(paint, SK_PAINT_STYLE_STROKE)
        set_paint_color!(paint, to_color(sc))
        sk_paint_set_stroke_width(paint, Float32(sw))
        sk_paint_set_stroke_join(paint, joinstyle)
        sk_paint_set_stroke_cap(paint, linecap)
        sk_paint_set_stroke_miter(paint, Float32(miter_limit))

        dash_effect = to_skia_dash_effect(strokestyle, sw)
        if dash_effect != C_NULL
            sk_paint_set_path_effect(paint, dash_effect)
        end

        sk_canvas_draw_path(screen.canvas, path, paint)
        sk_paint_delete(paint)
        sk_path_delete(path)
    end
    return
end

function draw_poly(scene::Scene, screen::Screen, poly, polygons::AbstractArray{<:MultiPolygon})
    model = poly.model[]
    space = poly.space[]
    projected_polys = map(polygons) do polygon
        project_multipolygon(poly, space, polygon, poly.clip_planes[], model)
    end

    color = to_skia_plotcolor(poly.color[], poly)
    strokecolor = to_skia_plotcolor(poly.strokecolor[], poly)
    strokestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())
    miter_limit = to_skia_miter_limit(poly.miter_limit[])
    joinstyle = to_skia_joinstyle(poly.joinstyle[])
    linecap = to_skia_linecap(poly.linecap[])

    broadcast_foreach(projected_polys, color, strokecolor, poly.strokewidth[]) do mpo, c, sc, sw
        for po in mpo.polygons
            path = polygon_to_skia_path(po)
            paint = new_paint(color = to_skia_color(c))
            sk_canvas_draw_path(screen.canvas, path, paint)
            sk_paint_set_style(paint, SK_PAINT_STYLE_STROKE)
            set_paint_color!(paint, to_color(sc))
            sk_paint_set_stroke_width(paint, Float32(sw))
            sk_paint_set_stroke_join(paint, joinstyle)
            sk_paint_set_stroke_cap(paint, linecap)
            sk_paint_set_stroke_miter(paint, Float32(miter_limit))

            dash_effect = to_skia_dash_effect(strokestyle, sw)
            if dash_effect != C_NULL
                sk_paint_set_path_effect(paint, dash_effect)
            end

            sk_canvas_draw_path(screen.canvas, path, paint)
            sk_paint_delete(paint)
            sk_path_delete(path)
        end
    end
    return
end

function polygon_to_skia_path(polygon)
    isempty(polygon.exterior) && return sk_path_new()
    ext = decompose(Point2f, polygon.exterior)
    path = sk_path_new()
    sk_path_set_filltype(path, SK_PATH_FILLTYPE_EVENODD)
    sk_path_move_to(path, Float32(ext[1][1]), Float32(ext[1][2]))
    for point in ext[2:end]
        sk_path_line_to(path, Float32(point[1]), Float32(point[2]))
    end
    sk_path_close(path)
    interiors = decompose.(Point2f, polygon.interiors)
    for interior in interiors
        n = length(interior)
        sk_path_move_to(path, Float32(interior[1][1]), Float32(interior[1][2]))
        for idx in 2:n
            point = interior[idx]
            sk_path_line_to(path, Float32(point[1]), Float32(point[2]))
        end
        sk_path_close(path)
    end
    return path
end

################################################################################
#                                     Band                                     #
################################################################################

function draw_plot(
        scene::Scene, screen::Screen,
        band::Band{<:Tuple{<:AbstractVector{<:Point2}, <:AbstractVector{<:Point2}}}
    )
    if !(band.color[] isa AbstractArray)
        color = to_skia_plotcolor(band.color[], band)
        model = band.model[]
        space = band.space[]
        xdir::Bool = band.direction[] === :x

        upperpoints = xdir ? band[1][] : reverse.(band[1][])
        lowerpoints = xdir ? band[2][] : reverse.(band[2][])

        for rng in band_segment_ranges(lowerpoints, upperpoints)
            points_segment = vcat(@view(lowerpoints[rng]), reverse(@view(upperpoints[rng])))
            points = clip_poly(band.clip_planes[], points_segment, space, model)
            points = project_position.(Ref(band), space, points, Ref(model))

            path = points_to_path(points)
            paint = new_paint(color = to_skia_color(color))
            sk_canvas_draw_path(screen.canvas, path, paint)
            sk_paint_delete(paint)
            sk_path_delete(path)
        end

        for p in band.plots
            p isa Mesh && continue
            draw_plot(scene, screen, p)
        end
    else
        for p in band.plots
            draw_plot(scene, screen, p)
        end
    end
    return nothing
end

function is_skiamakie_atomic_plot(plot::Band{<:Tuple{<:AbstractVector{<:Point2}, <:AbstractVector{<:Point2}}})
    return true
end

function band_segment_ranges(lowerpoints, upperpoints)
    ranges = UnitRange{Int}[]
    start = nothing
    for i in eachindex(lowerpoints, upperpoints)
        if isnan(lowerpoints[i]) || isnan(upperpoints[i])
            if start !== nothing && i - start > 1
                push!(ranges, start:(i - 1))
            end
            start = nothing
        elseif start === nothing
            start = i
        elseif i == lastindex(lowerpoints)
            push!(ranges, start:i)
        end
    end
    return ranges
end

################################################################################
#                                  Tricontourf                                 #
################################################################################

function draw_plot(scene::Scene, screen::Screen, tric::Tricontourf)
    pol = only(tric.plots)::Poly
    colornumbers = pol.color[]
    colors = to_skia_plotcolor(colornumbers, pol)
    polygons = pol[1][]
    model = pol.model[]
    space = pol.space[]
    projected_polys = project_polygon.(Ref(tric), space, polygons, Ref(tric.clip_planes[]), Ref(model))

    paint = new_paint()
    for (i, (po, col)) in enumerate(zip(projected_polys, colors))
        path = polygon_to_skia_path(po)
        if i == length(colornumbers) || colornumbers[i] != colornumbers[i + 1]
            set_paint_color!(paint, col)
            sk_canvas_draw_path(screen.canvas, path, paint)
        end
        sk_path_delete(path)
    end
    sk_paint_delete(paint)
    return
end

is_skiamakie_atomic_plot(plot::Tricontourf) = true

################################################################################
#                                   Arrows2D                                   #
################################################################################

function draw_plot(scene::Scene, screen::Screen, arrow::Arrows2D)
    poly = only(arrow.plots)
    color = to_skia_plotcolor(poly.color[], poly)
    model = Ref(poly.model[])
    strokecolor = to_skia_plotcolor(poly.strokecolor[], poly)
    strokestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())
    strokewidth = poly.strokewidth[]
    miter_limit = to_skia_miter_limit(poly.miter_limit[])
    joinstyle = to_skia_joinstyle(poly.joinstyle[])
    linecap = to_skia_linecap(poly.linecap[])

    broadcast_foreach(
        poly.meshes[], color, model, strokecolor, strokestyle, strokewidth
    ) do mesh, props...
        points = [Point2(c[1], c[2]) for c in coordinates(mesh)]
        draw_poly(scene, screen, poly, points, props..., miter_limit, joinstyle, linecap)
    end
    return nothing
end

is_skiamakie_atomic_plot(plot::Arrows2D) = true
