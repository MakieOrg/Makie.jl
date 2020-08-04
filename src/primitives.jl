################################################################################
#                             Lines, LineSegments                              #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Union{Lines, LineSegments})
    fields = @get_attribute(primitive, (color, linewidth, linestyle))
    linestyle = AbstractPlotting.convert_attribute(linestyle, AbstractPlotting.key"linestyle"())
    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]

    isempty(positions) && return

    # workaround for a LineSegments object created from a GLNormalMesh
    # the input argument is a view of points using faces, which results in
    # a vector of tuples of two points. we convert those to a list of points
    # so they don't trip up the rest of the pipeline
    # TODO this shouldn't be necessary anymore!
    if positions isa SubArray{<:Point3, 1, P, <:Tuple{Array{<:AbstractFace}}} where P
        positions = let
            pos = Point3f0[]
            for tup in positions
                push!(pos, tup[1])
                push!(pos, tup[2])
            end
            pos
        end
    end

    projected_positions = project_position.(Ref(scene), positions, Ref(model))

    if color isa AbstractArray{<: Number}
        color = numbers_to_colors(color, primitive)
    end

    # color is now a color or an array of colors
    # if it's an array of colors, each segment must be stroked separately

    # The linestyle can be set globally, as we do here.
    # However, there is a discrepancy between AbstractPlotting
    # and Cairo when it comes to linestyles.
    # For AbstractPlotting, the linestyle array is cumulative,
    # and defines the "absolute" endpoints of segments.
    # However, for Cairo, each value provides the length of
    # alternate "on" and "off" portions of the stroke.
    # Therefore, we take the diff of the given linestyle,
    # to convert the "absolute" coordinates into "relative" ones.
    if !isnothing(linestyle) && !(linewidth isa AbstractArray)
        Cairo.set_dash(ctx, diff(Float64.(linestyle)) .* linewidth)
    end
    if color isa AbstractArray || linewidth isa AbstractArray
        # stroke each segment separately, this means disjointed segments with probably
        # wonky dash patterns if segments are short

        # we can hide the gaps by setting the line cap to round
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_ROUND)
        draw_multi(
            primitive, ctx,
            projected_positions,
            color, linewidth,
            isnothing(linestyle) ? nothing : diff(Float64.(linestyle))
        )
    else
        # stroke the whole line at once if it has only one color
        # this allows correct linestyles and line joins as well and will be the
        # most common case
        Cairo.set_line_width(ctx, linewidth)
        Cairo.set_source_rgba(ctx, red(color), green(color), blue(color), alpha(color))
        draw_single(primitive, ctx, projected_positions)
    end
    nothing
end

function draw_single(primitive::Lines, ctx, positions)
    Cairo.move_to(ctx, positions[1]...)
    for i in 2:length(positions)
        if isnan(positions[i])
            i == length(positions) && break
            Cairo.move_to(ctx, positions[i+1]...)
        else
            Cairo.line_to(ctx, positions[i]...)
        end
    end
    Cairo.stroke(ctx)
end

function draw_single(primitive::LineSegments, ctx, positions)
    @assert iseven(length(positions))
    Cairo.move_to(ctx, positions[1]...)
    for i in 2:length(positions)
        if iseven(i)
            Cairo.line_to(ctx, positions[i]...)
        else
            Cairo.move_to(ctx, positions[i]...)
        end
    end
    Cairo.stroke(ctx)
end

# if linewidth is not an array
function draw_multi(primitive, ctx, positions, colors::AbstractArray, linewidth, dash)
    draw_multi(primitive, ctx, positions, colors, [linewidth for c in colors], dash)
end

# if color is not an array
function draw_multi(primitive, ctx, positions, color, linewidths::AbstractArray, dash)
    draw_multi(primitive, ctx, positions, [color for l in linewidths], linewidths, dash)
end

function draw_multi(primitive::Union{Lines, LineSegments}, ctx, positions, colors::AbstractArray, linewidths::AbstractArray, dash)
    if primitive isa LineSegments
        @assert iseven(length(positions))
    end
    @assert length(positions) == length(colors)
    @assert length(linewidths) == length(colors)

    iterator = if primitive isa Lines
        1:length(positions)-1
    elseif primitive isa LineSegments
        1:2:length(positions)
    end

    for i in iterator
        if isnan(positions[i+1]) || isnan(positions[i])
            continue
        end
        Cairo.move_to(ctx, positions[i]...)

        Cairo.line_to(ctx, positions[i+1]...)
        if linewidths[i] != linewidths[i+1]
            error("Cairo doesn't support two different line widths ($(linewidths[i]) and $(linewidths[i+1])) at the endpoints of a line.")
        end
        Cairo.set_line_width(ctx, linewidths[i])
        !isnothing(dash) && Cairo.set_dash(ctx, dash .* linewidths[i])
        c1 = colors[i]
        c2 = colors[i+1]
        # we can avoid the more expensive gradient if the colors are the same
        # this happens if one color was given for each segment
        if c1 == c2
            Cairo.set_source_rgba(ctx, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.stroke(ctx)
        else
            pat = Cairo.pattern_create_linear(positions[i]..., positions[i+1]...)
            Cairo.pattern_add_color_stop_rgba(pat, 0, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.pattern_add_color_stop_rgba(pat, 1, red(c2), green(c2), blue(c2), alpha(c2))
            Cairo.set_source(ctx, pat)
            Cairo.stroke(ctx)
            Cairo.destroy(pat)
        end
    end
end

################################################################################
#                                   Scatter                                    #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Scatter)
    fields = @get_attribute(primitive, (color, markersize, strokecolor, strokewidth, marker, marker_offset, rotations))
    @get_attribute(primitive, (transform_marker,))

    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]
    isempty(positions) && return
    size_model = transform_marker ? model : Mat4f0(I)

    font = to_font(to_value(get(primitive, :font, AbstractPlotting.defaultfont())))

    colors = if color isa AbstractArray{<: Number}
        numbers_to_colors(color, primitive)
    else
        color
    end

    broadcast_foreach(primitive[1][], colors, markersize, strokecolor,
                      strokewidth, marker, marker_offset, primitive.rotations[]) do point, col,
                          markersize, strokecolor, strokewidth, marker, mo, rotation

        # if we give size in pixels, the size is always equal to that value
        is_pixelspace = haskey(primitive, :markerspace) && primitive.markerspace[] == AbstractPlotting.Pixel
        scale = if is_pixelspace
            AbstractPlotting.to_2d_scale(markersize)
        else
            # otherwise calculate a scaled size
            project_scale(scene, markersize, size_model)
        end
        offset = if is_pixelspace
            AbstractPlotting.to_2d_scale(mo)
        else
            project_scale(scene, mo, size_model)
        end

        pos = project_position(scene, point, model)

        Cairo.set_source_rgba(ctx, rgbatuple(col)...)
        m = convert_attribute(marker, key"marker"(), key"scatter"())
        if m isa Char
            draw_marker(ctx, m, best_font(m, font), pos, scale, strokecolor, strokewidth, offset, rotation)
        else
            draw_marker(ctx, m, pos, scale, strokecolor, strokewidth, offset, rotation)
        end
    end
    nothing
end


function draw_marker(ctx, marker, pos, scale, strokecolor, strokewidth, marker_offset, rotation)

    marker_offset = marker_offset + scale ./ 2

    pos += Point2f0(marker_offset[1], -marker_offset[2])

    # Cairo.scale(ctx, scale...)
    Cairo.arc(ctx, pos[1], pos[2], scale[1]/2, 0, 2*pi)
    Cairo.fill_preserve(ctx)

    sc = to_color(strokecolor)

    Cairo.set_source_rgba(ctx, rgbatuple(sc)...)
    Cairo.set_line_width(ctx, Float64(strokewidth))
    Cairo.stroke(ctx)
end

function draw_marker(ctx, marker::Char, font, pos, scale, strokecolor, strokewidth, marker_offset, rotation)

    Cairo.save(ctx)

    # Marker offset is meant to be relative to the
    # bottom left corner of the box centered at
    # `pos` with sides defined by `scale`, but
    # this does not take the character's dimensions
    # into account.
    # Here, we reposition the marker offset to be
    # relative to the center of the char.
    marker_offset = marker_offset .+ scale ./ 2

    cairoface = set_ft_font(ctx, font)

    charextent = AbstractPlotting.FreeTypeAbstraction.internal_get_extent(font, marker)
    inkbb = AbstractPlotting.FreeTypeAbstraction.inkboundingbox(charextent)

    # scale normalized bbox by font size
    inkbb_scaled = FRect2D(origin(inkbb) .* scale, widths(inkbb) .* scale)

    # flip y for the centering shift of the character because in Cairo y goes down
    centering_offset = [1, -1] .* (-origin(inkbb_scaled) .- 0.5 .* widths(inkbb_scaled))
    # this is the origin where we actually have to place the glyph so it can be centered
    charorigin = pos .+ Vec2f0(marker_offset[1], -marker_offset[2])

    set_font_matrix(ctx, scale_matrix(scale...))

    # First, we translate to the point where the
    # marker is supposed to go.
    Cairo.translate(ctx, charorigin...)
    # Then, we rotate the context by the
    # appropriate amount,
    Cairo.rotate(ctx, to_2d_rotation(rotation))
    # and apply a centering offset to account for
    # the fact that text is shown from the (relative)
    # bottom left corner.
    Cairo.translate(ctx, centering_offset...)

    Cairo.text_path(ctx, string(marker))
    Cairo.fill_preserve(ctx)
    # stroke
    Cairo.set_line_width(ctx, strokewidth)
    Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
    Cairo.stroke(ctx)

    # if we use set_ft_font we should destroy the pointer it returns
    cairo_font_face_destroy(cairoface)

    Cairo.restore(ctx)

end


function draw_marker(ctx, marker::Union{Rect, Type{<: Rect}}, pos, scale, strokecolor, strokewidth, marker_offset, rotation)
    s2 = if marker isa Type{Rect}
        Point2(scale[1], -scale[2])
    else
        Point2((widths(marker) .* scale .* (1, -1))...)
    end

    offset = marker_offset .+ scale ./ 2

    pos += Point2f0(offset[1], -offset[2])

    Cairo.move_to(ctx, pos...)
    Cairo.rotate(ctx, to_2d_rotation(rotation))
    Cairo.rectangle(ctx, 0, 0, s2...)
    Cairo.fill_preserve(ctx);
    if strokewidth > 0.0
        sc = to_color(strokecolor)
        Cairo.set_source_rgba(ctx, rgbatuple(sc)...)
        Cairo.set_line_width(ctx, Float64(strokewidth))
        Cairo.stroke(ctx)
    end
end


################################################################################
#                                     Text                                     #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Text)
    ctx = screen.context
    @get_attribute(primitive, (textsize, color, font, align, rotation, model, justification, lineheight))
    txt = to_value(primitive[1])
    position = primitive.attributes[:position][]
    N = length(txt)
    atlas = AbstractPlotting.get_texture_atlas()
    if position isa Union{StaticArrays.StaticArray, Tuple{Real, Real}, GeometryBasics.Point} # one position to place text
        position = AbstractPlotting.layout_text(
            txt, position, textsize,
            font, align, rotation, model, justification, lineheight
        )
    end
    stridx = 1
    broadcast_foreach(1:N, position, textsize, color, font, rotation) do i, p, ts, cc, f, r
        Cairo.save(ctx)
        char = txt[stridx]

        stridx = nextind(txt, stridx)
        pos = project_position(scene, p, Mat4f0(I))
        scale = project_scale(scene, ts, Mat4f0(I))
        Cairo.move_to(ctx, pos[1], pos[2])
        Cairo.set_source_rgba(ctx, red(cc), green(cc), blue(cc), alpha(cc))
        cairoface = set_ft_font(ctx, f)

        mat = scale_matrix(scale...)
        set_font_matrix(ctx, mat)

        # TODO this only works in 2d
        Cairo.rotate(ctx, to_2d_rotation(r))

        if !(char in ('\r', '\n'))
            Cairo.show_text(ctx, string(char))
        end

        cairo_font_face_destroy(cairoface)

        Cairo.restore(ctx)
    end
    nothing
end

################################################################################
#                                Heatmap, Image                                #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Union{Heatmap, Image})
    ctx = screen.context
    image = primitive[3][]
    x, y = primitive[1][], primitive[2][]
    model = primitive[:model][]
    imsize = (extrema_nan(x), extrema_nan(y))

    # find projected image corners
    # this already takes care of flipping the image to correct cairo orientation
    xy = project_position(scene, Point2f0(first.(imsize)), model)
    xymax = project_position(scene, Point2f0(last.(imsize)), model)


    w, h = xymax .- xy
    interp = to_value(get(primitive, :interpolate, true))
    # TODO: use Gaussian blurring
    interp = interp ? Cairo.FILTER_BEST : Cairo.FILTER_NEAREST
    
    s = to_cairo_image(image, primitive)
    Cairo.rectangle(ctx, xy..., w, h)
    Cairo.save(ctx)
    Cairo.translate(ctx, xy...)
    Cairo.scale(ctx, w / s.width, h / s.height)
    Cairo.set_source_surface(ctx, s, 0, 0)
    p = Cairo.get_source(ctx)
    # Set filter doesn't work!?
    Cairo.pattern_set_filter(p, interp)
    Cairo.fill(ctx)
    Cairo.restore(ctx)
end

################################################################################
#                                     Mesh                                     #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::AbstractPlotting.Mesh)
    @get_attribute(primitive, (color,))

    colormap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    colorrange = get(primitive, :colorrange, nothing) |> to_value

    ctx = screen.context
    model = primitive.model[]
    mesh = primitive[1][]
    vs = coordinates(mesh); fs = faces(mesh)
    uv = hasproperty(mesh, :uv) ? mesh.uv : nothing
    pattern = Cairo.CairoPatternMesh()

    cols = per_face_colors(color, colormap, colorrange, vs, fs, uv)
    for (f, (c1, c2, c3)) in zip(fs, cols)
        t1, t2, t3 =  project_position.(scene, vs[f], (model,)) #triangle points
        Cairo.mesh_pattern_begin_patch(pattern)

        Cairo.mesh_pattern_move_to(pattern, t1...)
        Cairo.mesh_pattern_line_to(pattern, t2...)
        Cairo.mesh_pattern_line_to(pattern, t3...)

        mesh_pattern_set_corner_color(pattern, 0, c1)
        mesh_pattern_set_corner_color(pattern, 1, c2)
        mesh_pattern_set_corner_color(pattern, 2, c3)

        Cairo.mesh_pattern_end_patch(pattern)
    end
    Cairo.set_source(ctx, pattern)
    Cairo.close_path(ctx)
    Cairo.paint(ctx)
    return nothing
end
