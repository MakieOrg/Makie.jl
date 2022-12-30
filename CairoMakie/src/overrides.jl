################################################################################
#                    Poly - the not so primitive, primitive                    #
################################################################################


"""
Special method for polys so we don't fall back to atomic meshes, which are much more
complex and slower to draw than standard paths with single color.
"""
function draw_plot(scene::Scene, screen::Screen, poly::Poly)
    # dispatch on input arguments to poly to use smarter drawing methods than
    # meshes if possible
    draw_poly(scene, screen, poly, to_value.(poly.input_args)...)
end

"""
Fallback method for args without special treatment.
"""
function draw_poly(scene::Scene, screen::Screen, poly, args...)
    draw_poly_as_mesh(scene, screen, poly)
end

function draw_poly_as_mesh(scene, screen, poly)
    draw_plot(scene, screen, poly.plots[1])
    draw_plot(scene, screen, poly.plots[2])
end


# in the rare case of per-vertex colors redirect to mesh drawing
function draw_poly(scene::Scene, screen::Screen, poly, points::Vector{<:Point2}, color::AbstractArray, model, strokecolor, strokewidth)
    draw_poly_as_mesh(scene, screen, poly)
end

function draw_poly(scene::Scene, screen::Screen, poly, points::Vector{<:Point2})
    color = to_color(poly.color[])
    strokecolor = to_color(poly.color[])
    draw_poly(scene, screen, poly, points, color, poly.model[], strokecolor, poly.strokewidth[])
end

# when color is a Makie.AbstractPattern, we don't need to go to Mesh
function draw_poly(scene::Scene, screen::Screen, poly, points::Vector{<:Point2}, color::Union{Colorant, Makie.AbstractPattern},
        model, strokecolor, strokewidth)
    space = to_value(get(poly, :space, :data))
    points = project_position.(Ref(scene), space, points, Ref(model))
    Cairo.move_to(screen.context, points[1]...)
    for p in points[2:end]
        Cairo.line_to(screen.context, p...)
    end
    Cairo.close_path(screen.context)
    if color isa Makie.AbstractPattern
        cairopattern = Cairo.CairoPattern(color)
        Cairo.pattern_set_extend(cairopattern, Cairo.EXTEND_REPEAT);
        Cairo.set_source(screen.context, cairopattern)
    else
        Cairo.set_source_rgba(screen.context, rgbatuple(to_color(color))...)
    end

    Cairo.fill_preserve(screen.context)
    Cairo.set_source_rgba(screen.context, rgbatuple(to_color(strokecolor))...)
    Cairo.set_line_width(screen.context, strokewidth)
    Cairo.stroke(screen.context)
end

function draw_poly(scene::Scene, screen::Screen, poly, points_list::Vector{<:Vector{<:Point2}})
    color = to_color(poly.color[])
    strokecolor = to_color(poly.strokecolor[])
    broadcast_foreach(points_list, color,
        strokecolor, poly.strokewidth[], Ref(poly.model[])) do points, color, strokecolor, strokewidth, model
            draw_poly(scene, screen, poly, points, color, model, strokecolor, strokewidth)
    end
end

draw_poly(scene::Scene, screen::Screen, poly, rect::Rect2) = draw_poly(scene, screen, poly, [rect])

function draw_poly(scene::Scene, screen::Screen, poly, rects::Vector{<:Rect2})
    model = poly.model[]
    space = to_value(get(poly, :space, :data))
    projected_rects = project_rect.(Ref(scene), space, rects, Ref(model))

    color = poly.color[]
    if color isa AbstractArray{<:Number}
        color = numbers_to_colors(color, poly)
    elseif color isa String
        # string is erroneously broadcasted as chars otherwise
        color = to_color(color)
    elseif color isa Makie.AbstractPattern
        cairopattern = Cairo.CairoPattern(color)
        Cairo.pattern_set_extend(cairopattern, Cairo.EXTEND_REPEAT);
    end
    strokecolor = poly.strokecolor[]
    if strokecolor isa AbstractArray{<:Number}
        strokecolor = numbers_to_colors(strokecolor, poly)
    elseif strokecolor isa String
        # string is erroneously broadcasted as chars otherwise
        strokecolor = to_color(strokecolor)
    end

    broadcast_foreach(projected_rects, color, strokecolor, poly.strokewidth[]) do r, c, sc, sw
        Cairo.rectangle(screen.context, origin(r)..., widths(r)...)
        if c isa Makie.AbstractPattern
            Cairo.set_source(screen.context, cairopattern)
        else
            Cairo.set_source_rgba(screen.context, rgbatuple(to_color(c))...)
        end
        Cairo.fill_preserve(screen.context)
        Cairo.set_source_rgba(screen.context, rgbatuple(to_color(sc))...)
        Cairo.set_line_width(screen.context, sw)
        Cairo.stroke(screen.context)
    end
end

function polypath(ctx, polygon)
    ext = decompose(Point2f, polygon.exterior)
    Cairo.move_to(ctx, ext[1]...)
    for point in ext[2:end]
        Cairo.line_to(ctx, point...)
    end
    Cairo.close_path(ctx)

    interiors = decompose.(Point2f, polygon.interiors)
    for interior in interiors
        Cairo.move_to(ctx, interior[1]...)
        for point in interior[2:end]
            Cairo.line_to(ctx, point...)
        end
        Cairo.close_path(ctx)
    end
end

draw_poly(scene::Scene, screen::Screen, poly, polygon::Polygon) = draw_poly(scene, screen, poly, [polygon])
draw_poly(scene::Scene, screen::Screen, poly, circle::Circle) = draw_poly(scene, screen, poly, decompose(Point2f, circle))

function draw_poly(scene::Scene, screen::Screen, poly, polygons::AbstractArray{<:Polygon})
    model = poly.model[]
    space = to_value(get(poly, :space, :data))
    projected_polys = project_polygon.(Ref(scene), space, polygons, Ref(model))

    color = poly.color[]
    if color isa AbstractArray{<:Number}
        color = numbers_to_colors(color, poly)
    elseif color isa String
        # string is erroneously broadcasted as chars otherwise
        color = to_color(color)
    end
    strokecolor = poly.strokecolor[]
    if strokecolor isa AbstractArray{<:Number}
        strokecolor = numbers_to_colors(strokecolor, poly)
    elseif strokecolor isa String
        # string is erroneously broadcasted as chars otherwise
        strokecolor = to_color(strokecolor)
    end
    broadcast_foreach(projected_polys, color, strokecolor, poly.strokewidth[]) do po, c, sc, sw
        polypath(screen.context, po)
        Cairo.set_source_rgba(screen.context, rgbatuple(c)...)
        Cairo.fill_preserve(screen.context)
        Cairo.set_source_rgba(screen.context, rgbatuple(sc)...)
        Cairo.set_line_width(screen.context, sw)
        Cairo.stroke(screen.context)
    end

end


################################################################################
#                                     Band                                     #
#     Override because band is usually a polygon, but because it supports      #
#        gradients as well via `mesh` we have to intercept the poly use        #
################################################################################

function draw_plot(scene::Scene, screen::Screen,
        band::Band{<:Tuple{<:AbstractVector{<:Point2},<:AbstractVector{<:Point2}}})

    if !(band.color[] isa AbstractArray)
        upperpoints = band[1][]
        lowerpoints = band[2][]
        points = vcat(lowerpoints, reverse(upperpoints))
        model = band.model[]
        space = to_value(get(band, :space, :data))
        points = project_position.(Ref(scene), space, points, Ref(model))
        Cairo.move_to(screen.context, points[1]...)
        for p in points[2:end]
            Cairo.line_to(screen.context, p...)
        end
        Cairo.close_path(screen.context)
        Cairo.set_source_rgba(screen.context, rgbatuple(to_color(band.color[]))...)
        Cairo.fill(screen.context)
    else
        for p in band.plots
            draw_plot(scene, screen, p)
        end
    end

    nothing
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
    colors = numbers_to_colors(colornumbers, pol)

    polygons = pol[1][]

    model = pol.model[]
    space = to_value(get(pol, :space, :data))
    projected_polys = project_polygon.(Ref(scene), space, polygons, Ref(model))

    function draw_tripolys(polys, colornumbers, colors)
        for (i, (pol, colnum, col)) in enumerate(zip(polys, colornumbers, colors))
            polypath(screen.context, pol)
            if i == length(colornumbers) || colnum != colornumbers[i+1]
                Cairo.set_source_rgba(screen.context, rgbatuple(col)...)
                Cairo.fill(screen.context)
            end
        end
        return
    end

    draw_tripolys(projected_polys, colornumbers, colors)

    return
end
