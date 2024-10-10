################################################################################
#                    Poly - the not so primitive, primitive                    #
################################################################################

"""
Special method for polys so we don't fall back to atomic meshes, which are much more
complex and slower to draw than standard paths with single color.
"""
function draw_plot(scene::Scene, screen::Screen, poly::Poly)
    # dispatch on input arguments to poly to use smarter drawing methods than
    # meshes if possible.
    # however, since recipes exist, we can't explicitly handle all cases here
    # so, we should also take a look at converted
    # First, we check whether a `draw_poly` method exists for the input arguments
    # before conversion:
    return if Base.hasmethod(draw_poly, Tuple{Scene, Screen, typeof(poly), typeof.(to_value.(poly.args))...})
        draw_poly(scene, screen, poly, to_value.(poly.args)...)
    # If not, we check whether a `draw_poly` method exists for the arguments after conversion
    # (`plot.converted`).  This allows anything which decomposes to be checked for.
    elseif Base.hasmethod(draw_poly, Tuple{Scene, Screen, typeof(poly), typeof.(to_value.(poly.converted))...})
        draw_poly(scene, screen, poly, to_value.(poly.converted)...)
    # In the worst case, we return to drawing the polygon as a mesh + lines.
    else
        draw_poly_as_mesh(scene, screen, poly)
    end
end

# Override `is_cairomakie_atomic_plot` to allow `poly` to remain a unit,
# instead of auto-decomposing in lines and mesh.
is_cairomakie_atomic_plot(plot::Poly) = true


function draw_poly_as_mesh(scene, screen, poly)
    for i in eachindex(poly.plots)
        draw_plot(scene, screen, poly.plots[i])
    end
end

# As a general fallback, draw all polys as meshes.
# This also applies for e.g. per-vertex color.
function draw_poly(scene::Scene, screen::Screen, poly, points, color, model, strokecolor, strokestyle, strokewidth)
    draw_poly_as_mesh(scene, screen, poly)
end

function draw_poly(scene::Scene, screen::Screen, poly, points::Vector{<:Point2})
    color = to_cairo_color(poly.color[], poly)
    strokecolor = to_cairo_color(poly.strokecolor[], poly)
    strokestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())
    draw_poly(scene, screen, poly, points, color, poly.model[], strokecolor, strokestyle, poly.strokewidth[])
end

# when color is a Makie.AbstractPattern, we don't need to go to Mesh
function draw_poly(scene::Scene, screen::Screen, poly, points::Vector{<:Point2}, color::Union{Colorant, Cairo.CairoPattern},
        model, strokecolor, strokestyle, strokewidth)
    space = to_value(get(poly, :space, :data))
    points = clip_poly(poly.clip_planes[], points, space, model)
    points = _project_position(scene, space, points, model, true)
    Cairo.move_to(screen.context, points[1]...)
    for p in points[2:end]
        Cairo.line_to(screen.context, p...)
    end
    Cairo.close_path(screen.context)

    set_source(screen.context, color)

    Cairo.fill_preserve(screen.context)
    Cairo.set_source_rgba(screen.context, rgbatuple(to_color(strokecolor))...)
    Cairo.set_line_width(screen.context, strokewidth)
    isnothing(strokestyle) || Cairo.set_dash(screen.context, diff(Float64.(strokestyle)) .* strokewidth)
    Cairo.stroke(screen.context)
end

function draw_poly(scene::Scene, screen::Screen, poly, points_list::Vector{<:Vector{<:Point2}})
    color = to_cairo_color(poly.color[], poly)
    strokecolor = to_cairo_color(poly.strokecolor[], poly)
    strokestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())

    broadcast_foreach(points_list, color,
        strokecolor, strokestyle, poly.strokewidth[], Ref(poly.model[])) do points, color, strokecolor, strokestyle, strokewidth, model
            draw_poly(scene, screen, poly, points, color, model, strokecolor, strokestyle, strokewidth)
    end
end

draw_poly(scene::Scene, screen::Screen, poly, rect::Rect2) = draw_poly(scene, screen, poly, [rect])
draw_poly(scene::Scene, screen::Screen, poly, bezierpath::BezierPath) = draw_poly(scene, screen, poly, [bezierpath])

function draw_poly(scene::Scene, screen::Screen, poly, shapes::Vector{<:Union{Rect2, BezierPath}})
    model = poly.model[]::Mat4d
    space = to_value(get(poly, :space, :data))::Symbol
    planes = poly.clip_planes[]::Vector{Plane3f}

    projected_shapes = map(shapes) do shape
        clipped = clip_shape(planes, shape, space, model)
        return project_shape(poly, space, clipped, model)
    end

    color = to_cairo_color(poly.color[], poly)

    linestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())
    if isnothing(linestyle)
        linestyle_diffed = nothing
    elseif linestyle isa AbstractVector{<:Real}
        linestyle_diffed = diff(Float64.(linestyle))
    else
        error("Wrong type for linestyle: $(poly.linestyle[]).")
    end
    strokecolor = to_cairo_color(poly.strokecolor[], poly)
    broadcast_foreach(projected_shapes, color, strokecolor, poly.strokewidth[]) do shape, c, sc, sw
        create_shape_path!(screen.context, shape)
        set_source(screen.context, c)
        Cairo.fill_preserve(screen.context)
        isnothing(linestyle_diffed) || Cairo.set_dash(screen.context, linestyle_diffed .* sw)
        set_source(screen.context, sc)
        Cairo.set_line_width(screen.context, sw)
        Cairo.stroke(screen.context)
    end
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
    BezierPath(commands)
end

function create_shape_path!(ctx, r::Rect2)
    Cairo.rectangle(ctx, origin(r)..., widths(r)...)
end

function create_shape_path!(ctx, b::BezierPath)
    for cmd in b.commands
        path_command(ctx, cmd)
    end
end

function polypath(ctx, polygon)
    isempty(polygon) && return nothing
    ext = decompose(Point2f, polygon.exterior)
    Cairo.set_fill_type(ctx, Cairo.CAIRO_FILL_RULE_EVEN_ODD)
    Cairo.move_to(ctx, ext[1]...)
    for point in ext[2:end]
        Cairo.line_to(ctx, point...)
    end
    Cairo.close_path(ctx)
    interiors = decompose.(Point2f, polygon.interiors)
    for interior in interiors
        # Cairo needs to have interiors counter clockwise
        n = length(interior)
        Cairo.move_to(ctx, interior[1]...)
        for idx in 2:n
            point = interior[idx]
            Cairo.line_to(ctx, point...)
        end
        Cairo.close_path(ctx)
    end
end

draw_poly(scene::Scene, screen::Screen, poly, polygon::Polygon) = draw_poly(scene, screen, poly, [polygon])
draw_poly(scene::Scene, screen::Screen, poly, multipolygon::MultiPolygon) = draw_poly(scene, screen, poly, multipolygon.polygons)
draw_poly(scene::Scene, screen::Screen, poly, circle::Circle) = draw_poly(scene, screen, poly, decompose(Point2f, circle))

function draw_poly(scene::Scene, screen::Screen, poly, polygons::AbstractArray{<:Polygon})
    model = poly.model[]
    space = to_value(get(poly, :space, :data))
    projected_polys = map(polygons) do polygon
        return project_polygon(poly, space, polygon, poly.clip_planes[], model)
    end

    color = to_cairo_color(poly.color[], poly)
    strokecolor = to_cairo_color(poly.strokecolor[], poly)
    strokestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())

    broadcast_foreach(projected_polys, color, strokecolor, strokestyle, poly.strokewidth[]) do po, c, sc, ss, sw
        polypath(screen.context, po)
        set_source(screen.context, c)
        Cairo.fill_preserve(screen.context)
        set_source(screen.context, sc)
        Cairo.set_line_width(screen.context, sw)
        Cairo.stroke(screen.context)
    end

end

function draw_poly(scene::Scene, screen::Screen, poly, polygons::AbstractArray{<: MultiPolygon})
    model = poly.model[]
    space = to_value(get(poly, :space, :data))
    projected_polys = map(polygons) do polygon
        project_multipolygon(poly, space, polygon, poly.clip_planes[], model)
    end

    color = to_cairo_color(poly.color[], poly)
    strokecolor = to_cairo_color(poly.strokecolor[], poly)
    strokestyle = Makie.convert_attribute(poly.linestyle[], key"linestyle"())
    broadcast_foreach(projected_polys, color, strokecolor, strokestyle, poly.strokewidth[]) do mpo, c, sc, ss, sw
        for po in mpo.polygons
            polypath(screen.context, po)
            set_source(screen.context, c)
            Cairo.fill_preserve(screen.context)
            set_source(screen.context, sc)
            isnothing(ss) || Cairo.set_dash(screen.context, diff(Float64.(ss)) .* sw)
            Cairo.set_line_width(screen.context, sw)
            Cairo.stroke(screen.context)
        end
    end

end


################################################################################
#                                     Band                                     #
#     Override because band is usually a polygon, but because it supports      #
#        gradients as well via `mesh` we have to intercept the poly use        #
################################################################################

function band_segment_ranges(lowerpoints, upperpoints)
    ranges = UnitRange{Int}[]
    start = nothing

    for i in eachindex(lowerpoints, upperpoints)
        if isnan(lowerpoints[i]) || isnan(upperpoints[i])
            if start !== nothing && i - start > 1 # more than one point
                push!(ranges, start:i-1)
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

function draw_plot(scene::Scene, screen::Screen,
        band::Band{<:Tuple{<:AbstractVector{<:Point2},<:AbstractVector{<:Point2}}})

    if !(band.color[] isa AbstractArray)
        basecolor = to_cairo_color(band.color[], band)
        color = coloralpha(basecolor, alpha(basecolor) * band.alpha[])

        model = band.model[]
        space = to_value(get(band, :space, :data))

        upperpoints = band[1][]
        lowerpoints = band[2][]

        for rng in band_segment_ranges(lowerpoints, upperpoints)
            points = vcat(@view(lowerpoints[rng]), reverse(@view(upperpoints[rng])))
            points = clip_poly(band.clip_planes[], points, space, model)
            points = project_position.(Ref(band), space, points, Ref(model))
            Cairo.move_to(screen.context, points[1]...)
            for p in points[2:end]
                Cairo.line_to(screen.context, p...)
            end
            Cairo.close_path(screen.context)
            set_source(screen.context, color)
            Cairo.fill(screen.context)
        end
    else
        for p in band.plots
            draw_plot(scene, screen, p)
        end
    end

    nothing
end

# Override `is_cairomakie_atomic_plot` to allow this dispatch of `band` to remain a unit,
# instead of auto-decomposing in lines and mesh.
function is_cairomakie_atomic_plot(plot::Band{<:Tuple{<:AbstractVector{<:Point2},<:AbstractVector{<:Point2}}})
    return true
end

#################################################################################
#                                  Tricontourf                                  #
# Tricontourf creates many disjoint polygons that are adjacent and form contour #
#  bands, however, at the gaps we see white antialiasing artifacts. Therefore   #
#               we override behavior and draw each band in one go               #
#################################################################################

function draw_plot(scene::Scene, screen::Screen, tric::Tricontourf)

    pol = only(tric.plots)::Poly
    colornumbers = pol.color[]
    colors = to_cairo_color(colornumbers, pol)
    polygons = pol[1][]
    model = pol.model[]
    space = to_value(get(pol, :space, :data))
    projected_polys = project_polygon.(Ref(tric), space, polygons, Ref(tric.clip_planes[]), Ref(model))

    function draw_tripolys(polys, colornumbers, colors)
        for (i, (pol, colnum, col)) in enumerate(zip(polys, colornumbers, colors))
            polypath(screen.context, pol)
            if i == length(colornumbers) || colnum != colornumbers[i+1]
                set_source(screen.context, col)
                Cairo.fill(screen.context)
            end
        end
        return
    end

    draw_tripolys(projected_polys, colornumbers, colors)

    return
end

# Override `is_cairomakie_atomic_plot` to allow `Tricontourf` to remain a unit,
# instead of auto-decomposing in lines and mesh.
function is_cairomakie_atomic_plot(plot::Tricontourf)
    return true
end
