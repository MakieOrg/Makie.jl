################################################################################
#                             Lines, LineSegments                              #
################################################################################

function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Union{Lines, LineSegments}))
    @get_attribute(primitive, (color, linewidth, linestyle, space, model))
    ctx = screen.context
    positions = primitive[1][]

    isempty(positions) && return

    # color is now a color or an array of colors
    # if it's an array of colors, each segment must be stroked separately
    color = to_color(primitive.calculated_colors[])

    # Lines need to be handled more carefully with perspective projections to
    # avoid them inverting.
    # TODO: If we have neither perspective projection not clip_planes we can
    #       use the normal projection_position() here
    projected_positions, color, linewidth =
        project_line_points(scene, primitive, positions, color, linewidth)

    # The linestyle can be set globally, as we do here.
    # However, there is a discrepancy between Makie
    # and Cairo when it comes to linestyles.
    # For Makie, the linestyle array is cumulative,
    # and defines the "absolute" endpoints of segments.
    # However, for Cairo, each value provides the length of
    # alternate "on" and "off" portions of the stroke.
    # Therefore, we take the diff of the given linestyle,
    # to convert the "absolute" coordinates into "relative" ones.
    if !isnothing(linestyle) && !(linewidth isa AbstractArray)
        pattern = diff(Float64.(linestyle)) .* linewidth
        isodd(length(pattern)) && push!(pattern, 0)
        Cairo.set_dash(ctx, pattern)
    end

    # linecap
    linecap = primitive.linecap[]
    if linecap == :square
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_SQUARE)
    elseif linecap == :round
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_ROUND)
    else # :butt
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_BUTT)
    end

    # joinstyle
    miter_angle = to_value(get(primitive, :miter_limit, 2pi/3))
    set_miter_limit(ctx, 2.0 * Makie.miter_angle_to_distance(miter_angle))

    joinstyle = to_value(get(primitive, :joinstyle, :miter))
    if joinstyle == :round
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_ROUND)
    elseif joinstyle == :bevel
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_BEVEL)
    else # :miter
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_MITER)
    end

    if primitive isa Lines && to_value(primitive.args[1]) isa BezierPath
        return draw_bezierpath_lines(ctx, to_value(primitive.args[1]), primitive, color, space, model, linewidth)
    end

    if color isa AbstractArray || linewidth isa AbstractArray
        # stroke each segment separately, this means disjointed segments with probably
        # wonky dash patterns if segments are short
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

function draw_bezierpath_lines(ctx, bezierpath::BezierPath, scene, color, space, model, linewidth)
    for c in bezierpath.commands
        proj_comm = project_command(c, scene, space, model)
        path_command(ctx, proj_comm)
    end
    Cairo.set_source_rgba(ctx, rgbatuple(color)...)
    Cairo.set_line_width(ctx, linewidth)
    Cairo.stroke(ctx)
    return
end

function project_command(m::MoveTo, scene, space, model)
    MoveTo(project_position(scene, space, m.p, model))
end

function project_command(l::LineTo, scene, space, model)
    LineTo(project_position(scene, space, l.p, model))
end

function project_command(c::CurveTo, scene, space, model)
    CurveTo(
        project_position(scene, space, c.c1, model),
        project_position(scene, space, c.c2, model),
        project_position(scene, space, c.p, model),
    )
end

project_command(c::ClosePath, scene, space, model) = c

function draw_single(primitive::Lines, ctx, positions)
    isempty(positions) && return

    n = length(positions)
    start = positions[begin]

    @inbounds for i in 1:n
        p = positions[i]
        # only take action for non-NaNs
        if !isnan(p)
            # new line segment at beginning or if previously NaN
            if i == 1 || isnan(positions[i-1])
                Cairo.move_to(ctx, p...)
                start = p
            else
                Cairo.line_to(ctx, p...)
                # complete line segment at end or if next point is NaN
                if i == n || isnan(positions[i+1])
                    if p ≈ start
                        Cairo.close_path(ctx)
                    end
                    Cairo.stroke(ctx)
                end
            end
        end
    end
    # force clearing of path in case of skipped NaN
    Cairo.new_path(ctx)
end

function draw_single(primitive::LineSegments, ctx, positions)

    @assert iseven(length(positions))

    @inbounds for i in 1:2:length(positions)-1
        p1 = positions[i]
        p2 = positions[i+1]

        if isnan(p1) || isnan(p2)
            continue
        else
            Cairo.move_to(ctx, p1...)
            Cairo.line_to(ctx, p2...)
            Cairo.stroke(ctx)
        end
    end
    # force clearing of path in case of skipped NaN
    Cairo.new_path(ctx)
end

# getindex if array, otherwise just return value
using Makie: sv_getindex

function draw_multi(primitive::LineSegments, ctx, positions, colors, linewidths, dash)
    @assert iseven(length(positions))

    for i in 1:2:length(positions)
        if isnan(positions[i+1]) || isnan(positions[i])
            continue
        end
        lw = sv_getindex(linewidths, i)
        if lw != sv_getindex(linewidths, i+1)
            error("Cairo doesn't support two different line widths ($lw and $(sv_getindex(linewidths, i+1)) at the endpoints of a line.")
        end
        Cairo.move_to(ctx, positions[i]...)
        Cairo.line_to(ctx, positions[i+1]...)
        Cairo.set_line_width(ctx, lw)

        !isnothing(dash) && Cairo.set_dash(ctx, dash .* lw)
        c1 = sv_getindex(colors, i)
        c2 = sv_getindex(colors, i+1)
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

function draw_multi(primitive::Lines, ctx, positions, colors, linewidths, dash)
    isempty(positions) && return

    @assert !(colors isa AbstractVector) || length(colors) == length(positions)
    @assert !(linewidths isa AbstractVector) || length(linewidths) == length(positions)

    prev_color = sv_getindex(colors, 1)
    prev_linewidth = sv_getindex(linewidths, 1)
    prev_position = positions[begin]
    prev_nan = isnan(prev_position)
    prev_continued = false
    start = positions[begin]

    if !prev_nan
        # first is not nan, move_to
        Cairo.move_to(ctx, positions[begin]...)
    else
        # first is nan, do nothing
    end

    for i in eachindex(positions)[begin+1:end]
        this_position = positions[i]
        this_color = sv_getindex(colors, i)
        this_nan = isnan(this_position)
        this_linewidth = sv_getindex(linewidths, i)
        if this_nan
            # this is nan
            if prev_continued
                # and this is prev_continued, so set source and stroke to finish previous line
                (prev_position ≈ start) && Cairo.close_path(ctx)
                Cairo.set_line_width(ctx, this_linewidth)
                !isnothing(dash) && Cairo.set_dash(ctx, dash .* this_linewidth)
                Cairo.set_source_rgba(ctx, red(prev_color), green(prev_color), blue(prev_color), alpha(prev_color))
                Cairo.stroke(ctx)
            else
                # but this is not prev_continued, so do nothing
            end
        end
        if prev_nan
            # previous was nan
            if !this_nan
                # but this is not nan, so move to this position
                Cairo.move_to(ctx, this_position...)
                start = this_position
            else
                # and this is also nan, do nothing
            end
        else
            if this_color == prev_color
                # this color is like the previous
                if !this_nan
                    # and this is not nan, so line_to and set prev_continued
                    this_linewidth != prev_linewidth && error("Encountered two different linewidth values $prev_linewidth and $this_linewidth in `lines` at index $(i-1). Different linewidths in one line are only permitted in CairoMakie when separated by a NaN point.")
                    Cairo.line_to(ctx, this_position...)
                    prev_continued = true

                    if i == lastindex(positions)
                        # this is the last element so stroke this
                        (this_position ≈ start) && Cairo.close_path(ctx)
                        Cairo.set_line_width(ctx, this_linewidth)
                        !isnothing(dash) && Cairo.set_dash(ctx, dash .* this_linewidth)
                        Cairo.set_source_rgba(ctx, red(this_color), green(this_color), blue(this_color), alpha(this_color))
                        Cairo.stroke(ctx)
                    end
                else
                    # but this is nan, so do nothing
                end
            else
                prev_continued = false

                # finish previous line segment
                Cairo.set_line_width(ctx, prev_linewidth)
                !isnothing(dash) && Cairo.set_dash(ctx, dash .* prev_linewidth)
                Cairo.set_source_rgba(ctx, red(prev_color), green(prev_color), blue(prev_color), alpha(prev_color))
                Cairo.stroke(ctx)

                if !this_nan
                    this_linewidth != prev_linewidth && error("Encountered two different linewidth values $prev_linewidth and $this_linewidth in `lines` at index $(i-1). Different linewidths in one line are only permitted in CairoMakie when separated by a NaN point.")
                    # this is not nan
                    # and this color is different than the previous, so move_to prev and line_to this
                    # create gradient pattern and stroke
                    Cairo.move_to(ctx, prev_position...)
                    Cairo.line_to(ctx, this_position...)
                    !isnothing(dash) && Cairo.set_dash(ctx, dash .* this_linewidth)
                    Cairo.set_line_width(ctx, this_linewidth)

                    pat = Cairo.pattern_create_linear(prev_position..., this_position...)
                    Cairo.pattern_add_color_stop_rgba(pat, 0, red(prev_color), green(prev_color), blue(prev_color), alpha(prev_color))
                    Cairo.pattern_add_color_stop_rgba(pat, 1, red(this_color), green(this_color), blue(this_color), alpha(this_color))
                    Cairo.set_source(ctx, pat)
                    Cairo.stroke(ctx)
                    Cairo.destroy(pat)

                    Cairo.move_to(ctx, this_position...)
                else
                    # this is nan, do nothing
                end
            end
        end
        prev_nan = this_nan
        prev_color = this_color
        prev_linewidth = this_linewidth
        prev_position = this_position
    end
end

################################################################################
#                                   Scatter                                    #
################################################################################

function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Scatter))
    @get_attribute(primitive, (
        markersize, strokecolor, strokewidth, marker, marker_offset, rotation,
        transform_marker, model, markerspace, space, clip_planes)
    )

    marker = cairo_scatter_marker(primitive.marker[]) # this goes through CairoMakie's conversion system and not Makie's...
    ctx = screen.context
    positions = primitive[1][]
    isempty(positions) && return
    size_model = transform_marker ? model : Mat4d(I)

    font = to_font(to_value(get(primitive, :font, Makie.defaultfont())))
    colors = to_color(primitive.calculated_colors[])
    markerspace = primitive.markerspace[]
    space = primitive.space[]
    transfunc = Makie.transform_func(primitive)
    billboard = primitive.rotation[] isa Billboard

    return draw_atomic_scatter(scene, ctx, transfunc, colors, markersize, strokecolor, strokewidth, marker,
                               marker_offset, rotation, model, positions, size_model, font, markerspace,
                               space, clip_planes, billboard)
end

function draw_atomic_scatter(
        scene, ctx, transfunc, colors, markersize, strokecolor, strokewidth,
        marker, marker_offset, rotation, model, positions, size_model, font,
        markerspace, space, clip_planes, billboard
    )

    transformed = apply_transform(transfunc, positions, space)
    indices = unclipped_indices(to_model_space(model, clip_planes), transformed, space)
    transform = Makie.clip_to_space(scene.camera, markerspace) *
        Makie.space_to_clip(scene.camera, space) *
        Makie.f32_convert_matrix(scene.float32convert, space) *
        model
    model33 = size_model[Vec(1,2,3), Vec(1,2,3)]

    Makie.broadcast_foreach_index(view(transformed, indices), indices, colors, markersize, strokecolor,
            strokewidth, marker, marker_offset, remove_billboard(rotation)) do pos, col,
            markersize, strokecolor, strokewidth, m, mo, rotation

        isnan(pos) && return
        isnan(rotation) && return # matches GLMakie
        isnan(markersize) && return

        p4d = transform * to_ndim(Point4d, to_ndim(Point3d, pos, 0), 1)
        o = p4d[Vec(1, 2, 3)] ./ p4d[4] .+ model33 * to_ndim(Vec3d, mo, 0)
        proj_pos, mat, jl_mat = project_marker(scene, markerspace, o,
            markersize, rotation, size_model, billboard)

        # mat and jl_mat are the same matrix, once as a CairoMatrix, once as a Mat2f
        # They both describe an approximate basis transformation matrix from
        # marker space to pixel space with scaling appropriate to markersize.
        # Markers that can be drawn from points/vertices of shape (e.g. Rect)
        # could be projected more accurately by projecting each point individually
        # and then building the shape.

        # Enclosed area of the marker must be at least 1 pixel?
        (abs(det(jl_mat)) < 1) && return

        Cairo.set_source_rgba(ctx, rgbatuple(col)...)
        Cairo.save(ctx)
        if m isa Char
            draw_marker(ctx, m, best_font(m, font), proj_pos, strokecolor, strokewidth, jl_mat, mat)
        else
            draw_marker(ctx, m, proj_pos, strokecolor, strokewidth, mat)
        end
        Cairo.restore(ctx)
    end

    return
end

function draw_marker(ctx, marker::Char, font, pos, strokecolor, strokewidth, jl_mat, mat)
    cairoface = set_ft_font(ctx, font)

    # The given pos includes the user position which corresponds to the center
    # of the marker and the user marker_offset which may shift the position.
    # At this point we still need to center the character we draw. For that we
    # get the character boundingbox where (0,0) is the anchor point:
    charextent = Makie.FreeTypeAbstraction.get_extent(font, marker)
    inkbb = Makie.FreeTypeAbstraction.inkboundingbox(charextent)

    # And calculate an offset to the the center of the marker
    centering_offset = Makie.origin(inkbb) .+ 0.5f0 .* widths(inkbb)
    # which we then transform from marker space to screen space using the
    # local coordinate transform derived by project_marker()
    # (Need yflip because Cairo's y coordinates are reversed)
    char_offset = Vec2f(jl_mat * ((1, -1) .* centering_offset))

    # The offset is then applied to pos and the marker placement is set
    charorigin = pos - char_offset
    Cairo.translate(ctx, charorigin[1], charorigin[2])

    # The font matrix takes care of rotation, scaling and shearing of the marker
    old_matrix = get_font_matrix(ctx)
    set_font_matrix(ctx, mat)

    Cairo.move_to(ctx, 0, 0)
    Cairo.text_path(ctx, string(marker))
    Cairo.fill_preserve(ctx)
    # stroke
    Cairo.set_line_width(ctx, strokewidth)
    Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
    Cairo.stroke(ctx)

    # if we use set_ft_font we should destroy the pointer it returns
    cairo_font_face_destroy(cairoface)

    set_font_matrix(ctx, old_matrix)
    return
end

function draw_marker(ctx, ::Type{<: Circle}, pos, strokecolor, strokewidth, mat)
    # There are already active transforms so we can't Cairo.set_matrix() here
    Cairo.translate(ctx, pos[1], pos[2])
    cairo_transform(ctx, mat)
    Cairo.arc(ctx, 0, 0, 0.5, 0, 2*pi)
    Cairo.fill_preserve(ctx)
    Cairo.set_line_width(ctx, Float64(strokewidth))
    sc = to_color(strokecolor)
    Cairo.set_source_rgba(ctx, rgbatuple(sc)...)
    Cairo.stroke(ctx)
    return
end

function draw_marker(ctx, ::Union{Makie.FastPixel,<:Type{<:Rect}}, pos, strokecolor, strokewidth, mat)
    # There are already active transforms so we can't Cairo.set_matrix() here
    Cairo.translate(ctx, pos[1], pos[2])
    cairo_transform(ctx, mat)
    Cairo.rectangle(ctx, -0.5, -0.5, 1, 1)
    Cairo.fill_preserve(ctx)
    Cairo.set_line_width(ctx, Float64(strokewidth))
    sc = to_color(strokecolor)
    Cairo.set_source_rgba(ctx, rgbatuple(sc)...)
    Cairo.stroke(ctx)
    return
end

function draw_marker(ctx, beziermarker::BezierPath, pos, strokecolor, strokewidth, mat)
    Cairo.save(ctx)
    # There are already active transforms so we can't Cairo.set_matrix() here
    Cairo.translate(ctx, pos[1], pos[2])
    cairo_transform(ctx, mat)
    Cairo.scale(ctx, 1, -1) # maybe to transition BezierPath y to Cairo y?
    draw_path(ctx, beziermarker)
    Cairo.fill_preserve(ctx)
    sc = to_color(strokecolor)
    Cairo.set_source_rgba(ctx, rgbatuple(sc)...)
    Cairo.set_line_width(ctx, Float64(strokewidth))
    Cairo.stroke(ctx)
    Cairo.restore(ctx)
    return
end

function draw_path(ctx, bp::BezierPath)
    for i in eachindex(bp.commands)
        @inbounds command = bp.commands[i]
        if command isa MoveTo
            path_command(ctx, command)
        elseif command isa LineTo
            path_command(ctx, command)
        elseif command isa CurveTo
            path_command(ctx, command)
        elseif command isa ClosePath
            path_command(ctx, command)
        elseif command isa EllipticalArc
            path_command(ctx, command)
        end
    end
end
path_command(ctx, c::MoveTo) = Cairo.move_to(ctx, c.p...)
path_command(ctx, c::LineTo) = Cairo.line_to(ctx, c.p...)
path_command(ctx, c::CurveTo) = Cairo.curve_to(ctx, c.c1..., c.c2..., c.p...)
path_command(ctx, ::ClosePath) = Cairo.close_path(ctx)
function path_command(ctx, c::EllipticalArc)
    Cairo.save(ctx)
    Cairo.translate(ctx, c.c...)
    Cairo.rotate(ctx, c.angle)
    Cairo.scale(ctx, 1, c.r2 / c.r1)
    if c.a2 > c.a1
        Cairo.arc(ctx, 0, 0, c.r1, c.a1, c.a2)
    else
        Cairo.arc_negative(ctx, 0, 0, c.r1, c.a1, c.a2)
    end
    Cairo.restore(ctx)
end


function draw_marker(ctx, marker::Matrix{T}, pos,
    strokecolor #= unused =#, strokewidth #= unused =#,
    mat) where T<:Colorant

    # convert marker to Cairo compatible image data
    marker = permutedims(marker, (2,1))
    marker_surf = to_cairo_image(marker)

    w, h = size(marker)

    # There are already active transforms so we can't Cairo.set_matrix() here
    Cairo.translate(ctx, pos[1], pos[2])
    cairo_transform(ctx, mat)
    Cairo.scale(ctx, 1.0 / w, 1.0 / h)
    Cairo.set_source_surface(ctx, marker_surf, -w/2, -h/2)
    Cairo.paint(ctx)
    return
end

################################################################################
#                                     Text                                     #
################################################################################

function p3_to_p2(p::Point3{T}) where T
    if p[3] == 0 || isnan(p[3])
        Point2{T}(p[Vec(1,2)]...)
    else
        error("Can't reduce Point3 to Point2 with nonzero third component $(p[3]).")
    end
end

function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Text{<:Tuple{<:Union{AbstractArray{<:Makie.GlyphCollection}, Makie.GlyphCollection}}}))
    ctx = screen.context
    @get_attribute(primitive, (rotation, model, space, markerspace, offset, clip_planes))
    transform_marker = to_value(get(primitive, :transform_marker, true))::Bool
    position = primitive.position[]
    # use cached glyph info
    glyph_collection = to_value(primitive[1])

    draw_glyph_collection(
        scene, ctx, position, glyph_collection, remove_billboard(rotation),
        model, space, markerspace, offset, primitive.transformation, transform_marker,
        clip_planes
    )

    nothing
end

function draw_glyph_collection(
        scene, ctx, positions, glyph_collections::AbstractArray, rotation,
        model::Mat, space, markerspace, offset, transformation, transform_marker,
        clip_planes
    )

    # TODO: why is the Ref around model necessary? doesn't broadcast_foreach handle staticarrays matrices?
    broadcast_foreach(positions, glyph_collections, rotation, Ref(model), space,
        markerspace, offset) do pos, glayout, ro, mo, sp, msp, off

        draw_glyph_collection(scene, ctx, pos, glayout, ro, mo, sp, msp, off, transformation, transform_marker, clip_planes)
    end
end

_deref(x) = x
_deref(x::Ref) = x[]

function draw_glyph_collection(
        scene, ctx, position, glyph_collection, rotation, _model, space,
        markerspace, offsets, transformation, transform_marker, clip_planes)

    glyphs = glyph_collection.glyphs
    glyphoffsets = glyph_collection.origins
    fonts = glyph_collection.fonts
    rotations = glyph_collection.rotations
    scales = glyph_collection.scales
    colors = glyph_collection.colors
    strokewidths = glyph_collection.strokewidths
    strokecolors = glyph_collection.strokecolors

    model = _deref(_model)
    model33 = transform_marker ? model[Vec(1, 2, 3), Vec(1, 2, 3)] : Mat3d(I)
    id = Mat4f(I)

    glyph_pos = let
        # TODO: f32convert may run into issues here if markerspace is :data or
        #       :transformed (repeated application in glyphpos etc)
        transform_func = transformation.transform_func[]
        transformed = apply_transform(transform_func, position, space)
        p = model * to_ndim(Point4d, to_ndim(Point3d, transformed, 0), 1)

        Makie.is_data_space(space) && is_clipped(clip_planes, p) && return

        Makie.clip_to_space(scene.camera, markerspace) *
        Makie.space_to_clip(scene.camera, space) *
        Makie.f32_convert_matrix(scene.float32convert, space) *
        p
    end

    Cairo.save(ctx)

    broadcast_foreach(glyphs, glyphoffsets, fonts, rotations, scales, colors, strokewidths, strokecolors, offsets) do glyph,
        glyphoffset, font, rotation, scale, color, strokewidth, strokecolor, offset

        cairoface = set_ft_font(ctx, font)
        old_matrix = get_font_matrix(ctx)

        p3_offset = to_ndim(Point3f, offset, 0)

        # Not renderable by font (e.g. '\n')
        # TODO, filter out \n in GlyphCollection, and render unrenderables as box
        glyph == 0 && return

        Cairo.save(ctx)
        Cairo.set_source_rgba(ctx, rgbatuple(color)...)

        # offsets and scale apply in markerspace
        gp3 = glyph_pos[Vec(1, 2, 3)] ./ glyph_pos[4] .+ model33 * (glyphoffset .+ p3_offset)

        if any(isnan, gp3)
            Cairo.restore(ctx)
            return
        end

        scale2 = scale isa Number ? Vec2d(scale, scale) : scale
        glyphpos, mat, _ = project_marker(scene, markerspace, gp3, scale2, rotation, model33, id)

        Cairo.save(ctx)
        set_font_matrix(ctx, mat)
        show_glyph(ctx, glyph, glyphpos...)
        Cairo.restore(ctx)

        if strokewidth > 0 && strokecolor != RGBAf(0, 0, 0, 0)
            Cairo.save(ctx)
            Cairo.move_to(ctx, glyphpos...)
            set_font_matrix(ctx, mat)
            glyph_path(ctx, glyph, glyphpos...)
            Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
            Cairo.set_line_width(ctx, strokewidth)
            Cairo.stroke(ctx)
            Cairo.restore(ctx)
        end
        Cairo.restore(ctx)

        cairo_font_face_destroy(cairoface)
        set_font_matrix(ctx, old_matrix)
    end

    Cairo.restore(ctx)
    return
end

################################################################################
#                                Heatmap, Image                                #
################################################################################

"""
    regularly_spaced_array_to_range(arr)
If possible, converts `arr` to a range.
If not, returns array unchanged.
"""
function regularly_spaced_array_to_range(arr)
    diffs = unique!(sort!(diff(arr)))
    step = sum(diffs) ./ length(diffs)
    if all(x-> x ≈ step, diffs)
        m, M = extrema(arr)
        if step < zero(step)
            m, M = M, m
        end
        # don't use stop=M, since that may not include M
        return range(m; step=step, length=length(arr))
    else
        return arr
    end
end

regularly_spaced_array_to_range(arr::AbstractRange) = arr

function premultiplied_rgba(a::AbstractArray{<:ColorAlpha})
    map(premultiplied_rgba, a)
end
premultiplied_rgba(a::AbstractArray{<:Color}) = RGBA.(a)

premultiplied_rgba(r::RGBA) = RGBA(r.r * r.alpha, r.g * r.alpha, r.b * r.alpha, r.alpha)
premultiplied_rgba(c::Colorant) = premultiplied_rgba(RGBA(c))

function draw_atomic(scene::Scene, screen::Screen{RT}, @nospecialize(primitive::Union{Heatmap, Image})) where RT
    ctx = screen.context
    image = primitive[3][]
    xs, ys = primitive[1][], primitive[2][]
    if xs isa Makie.EndPoints
        l, r = xs
        N = size(image, 1)
        xs = range(l, r, length = N+1)
    else
        xs = regularly_spaced_array_to_range(xs)
    end
    if ys isa Makie.EndPoints
        l, r = ys
        N = size(image, 2)
        ys = range(l, r, length = N+1)
    else
        ys = regularly_spaced_array_to_range(ys)
    end
    model = primitive.model[]::Mat4d
    interpolate = to_value(primitive.interpolate)

    # Debug attribute we can set to disable fastpath
    # probably shouldn't really be part of the interface
    fast_path = to_value(get(primitive, :fast_path, true))
    disable_fast_path = !fast_path
    # Vector backends don't support FILTER_NEAREST for interp == false, so in that case we also need to draw rects
    is_vector = is_vector_backend(ctx)
    t = Makie.transform_func(primitive)
    identity_transform = (t === identity || t isa Tuple && all(x-> x === identity, t)) && (abs(model[1, 2]) < 1e-15)
    regular_grid = xs isa AbstractRange && ys isa AbstractRange
    xy_aligned = Makie.is_translation_scale_matrix(scene.camera.projectionview[])

    if interpolate
        if !regular_grid
            error("$(typeof(primitive).parameters[1]) with interpolate = true with a non-regular grid is not supported right now.")
        end
        if !identity_transform
            error("$(typeof(primitive).parameters[1]) with interpolate = true with a non-identity transform is not supported right now.")
        end
    end

    imsize = ((first(xs), last(xs)), (first(ys), last(ys)))
    # find projected image corners
    # this already takes care of flipping the image to correct cairo orientation
    space = to_value(get(primitive, :space, :data))
    xy = project_position(primitive, space, Point2(first.(imsize)), model)
    xymax = project_position(primitive, space, Point2(last.(imsize)), model)
    w, h = xymax .- xy

    uv_transform = if primitive isa Image
        val = to_value(get(primitive, :uv_transform, I))
        T = Makie.convert_attribute(val, Makie.key"uv_transform"(), Makie.key"image"())
        # Cairo uses pixel units so we need to transform those to a 0..1 range,
        # then apply uv_transform, then scale them back to pixel units.
        # Cairo also doesn't have the yflip we have in OpenGL, so we need to
        # invert y.
        T3 = Mat3f(T[1], T[2], 0, T[3], T[4], 0, T[5], T[6], 1)
        T3 = Makie.uv_transform(Vec2f(size(image))) * T3 *
            Makie.uv_transform(Vec2f(0, 1), 1f0 ./ Vec2f(size(image, 1), -size(image, 2)))
        T3[Vec(1, 2), Vec(1,2,3)]
    else
        Mat{2, 3, Float32}(1,0,0,1,0,0)
    end

    can_use_fast_path = !(is_vector && !interpolate) && regular_grid && identity_transform &&
        (interpolate || xy_aligned) && isempty(primitive.clip_planes[])
    use_fast_path = can_use_fast_path && !disable_fast_path

    if use_fast_path
        s = to_cairo_image(to_color(primitive.calculated_colors[]))

        weird_cairo_limit = (2^15) - 23
        if s.width > weird_cairo_limit || s.height > weird_cairo_limit
            error("Cairo stops rendering images bigger than $(weird_cairo_limit), which is likely a bug in Cairo. Please resample your image/heatmap with heatmap(Resampler(data)).")
        end
        Cairo.rectangle(ctx, xy..., w, h)
        Cairo.save(ctx)
        Cairo.translate(ctx, xy...)
        Cairo.scale(ctx, w / s.width, h / s.height)
        Cairo.set_source_surface(ctx, s, 0, 0)
        p = Cairo.get_source(ctx)
        if RT !== SVG
            # this is needed to avoid blurry edges in png renderings, however since Cairo 1.18 this
            # setting seems to create broken SVGs
            Cairo.pattern_set_extend(p, Cairo.EXTEND_PAD)
        end
        filt = interpolate ? Cairo.FILTER_BILINEAR : Cairo.FILTER_NEAREST
        Cairo.pattern_set_filter(p, filt)
        pattern_set_matrix(p, Cairo.CairoMatrix(uv_transform...))
        Cairo.fill(ctx)
        Cairo.restore(ctx)
        pattern_set_matrix(p, Cairo.CairoMatrix(1, 0, 0, 1, 0, 0))
    else
        # find projected image corners
        # this already takes care of flipping the image to correct cairo orientation
        space = to_value(get(primitive, :space, :data))
        xys = let
            ps = [Point2(x, y) for x in xs, y in ys]
            transformed = apply_transform(transform_func(primitive), ps, space)
            T = eltype(transformed)

            planes = if Makie.is_data_space(space)
                to_model_space(model, primitive.clip_planes[])
            else
                Plane3f[]
            end

            for i in eachindex(transformed)
                if is_clipped(planes, transformed[i])
                    transformed[i] = T(NaN)
                end
            end

            _project_position(scene, space, transformed, model, true)
        end
        colors = to_color(primitive.calculated_colors[])

        # Note: xs and ys should have size ni+1, nj+1
        ni, nj = size(image)
        if ni + 1 != length(xs) || nj + 1 != length(ys)
            error("Error in conversion pipeline. xs and ys should have size ni+1, nj+1. Found: xs: $(length(xs)), ys: $(length(ys)), ni: $(ni), nj: $(nj)")
        end
        _draw_rect_heatmap(ctx, xys, ni, nj, colors)
    end
end

function _draw_rect_heatmap(ctx, xys, ni, nj, colors)
    @inbounds for i in 1:ni, j in 1:nj
        p1 = xys[i, j]
        p2 = xys[i+1, j]
        p3 = xys[i+1, j+1]
        p4 = xys[i, j+1]
        if isnan(p1) || isnan(p2) || isnan(p3) || isnan(p4)
            continue
        end

        # Rectangles and polygons that are directly adjacent usually show
        # white lines between them due to anti aliasing. To avoid this we
        # increase their size slightly.

        if alpha(colors[i, j]) == 1
            # To avoid gaps between heatmap cells we pad cells.
            # For 3D compatability (and rotation, inversion/mirror) we pad cells
            # using directional vectors, not along x/y directions.
            v1 = normalize(p2 - p1)
            v2 = normalize(p4 - p1)
            # To avoid shifting cells we only pad them on the +i, +j side, which
            # gets covered by later cells.
            # To avoid enlarging the final column and row of the heatmap, the
            # last set of cells is not padded. (i != ni), (j != nj)
            p2 += Float32(i != ni) * v1
            p3 += Float32(i != ni) * v1 + Float32(j != nj) * v2
            p4 += Float32(j != nj) * v2
        end

        Cairo.set_line_width(ctx, 0)
        Cairo.move_to(ctx, p1[1], p1[2])
        Cairo.line_to(ctx, p2[1], p2[2])
        Cairo.line_to(ctx, p3[1], p3[2])
        Cairo.line_to(ctx, p4[1], p4[2])
        Cairo.close_path(ctx)
        Cairo.set_source_rgba(ctx, rgbatuple(colors[i, j])...)
        Cairo.fill(ctx)
    end
end


################################################################################
#                                     Mesh                                     #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.Mesh))
    mesh = primitive[1][]
    if Makie.cameracontrols(scene) isa Union{Camera2D, Makie.PixelCamera, Makie.EmptyCamera}
        draw_mesh2D(scene, screen, primitive, mesh)
    else
        if !haskey(primitive, :faceculling)
            primitive[:faceculling] = Observable(-10)
        end
        uv_transform = Makie.convert_attribute(primitive[:uv_transform][], Makie.key"uv_transform"(), Makie.key"mesh"())
        draw_mesh3D(scene, screen, primitive, mesh; uv_transform = uv_transform)
    end
    return nothing
end

function draw_mesh2D(scene, screen, @nospecialize(plot::Makie.Mesh), @nospecialize(mesh::GeometryBasics.Mesh))
    space = to_value(get(plot, :space, :data))::Symbol
    transform_func = Makie.transform_func(plot)
    model = plot.model[]::Mat4d
    vs = project_position(scene, transform_func, space, GeometryBasics.coordinates(mesh), model)::Vector{Point2f}
    fs = decompose(GLTriangleFace, mesh)::Vector{GLTriangleFace}
    uv = decompose_uv(mesh)::Union{Nothing, Vector{Vec2f}}
    # Note: This assume the function is only called from mesh plots
    uv_transform = Makie.convert_attribute(plot[:uv_transform][], Makie.key"uv_transform"(), Makie.key"mesh"())
    if uv isa Vector{Vec2f} && to_value(uv_transform) !== nothing
        uv = map(uv -> uv_transform * to_ndim(Vec3f, uv, 1), uv)
    end
    color = hasproperty(mesh, :color) ? to_color(mesh.color) : plot.calculated_colors[]
    cols = per_face_colors(color, nothing, fs, nothing, uv)
    return draw_mesh2D(screen, cols, vs, fs)
end

function draw_mesh2D(screen, per_face_cols, vs::Vector{<: Point2}, fs::Vector{GLTriangleFace})

    ctx = screen.context
    # Prioritize colors of the mesh if present
    # This is a hack, which needs cleaning up in the Mesh plot type!

    for (f, (c1, c2, c3)) in zip(fs, per_face_cols)
        t1, t2, t3 =  vs[f] #triangle points

        # don't draw any mesh faces with NaN components.
        if isnan(t1) || isnan(t2) || isnan(t3)
            continue
        end

        pattern = Cairo.CairoPatternMesh()

        Cairo.mesh_pattern_begin_patch(pattern)

        Cairo.mesh_pattern_move_to(pattern, t1[1], t1[2])
        Cairo.mesh_pattern_line_to(pattern, t2[1], t2[2])
        Cairo.mesh_pattern_line_to(pattern, t3[1], t3[2])

        mesh_pattern_set_corner_color(pattern, 0, c1)
        mesh_pattern_set_corner_color(pattern, 1, c2)
        mesh_pattern_set_corner_color(pattern, 2, c3)

        Cairo.mesh_pattern_end_patch(pattern)
        Cairo.set_source(ctx, pattern)
        Cairo.close_path(ctx)
        Cairo.paint(ctx)
        Cairo.destroy(pattern)
    end
    return nothing
end

function average_z(positions, face)
    vs = positions[face]
    sum(v -> v[3], vs) / length(vs)
end

nan2zero(x) = !isnan(x) * x

function strip_translation(M::Mat4{T}) where {T}
    return @inbounds Mat4{T}(
        M[1], M[2], M[3], M[4],
        M[5], M[6], M[7], M[8],
        M[9], M[10], M[11], M[12],
        0, 0, 0, M[16],
    )
end

function draw_mesh3D(
        scene, screen, attributes, mesh; pos = Vec3d(0), scale = 1.0, rotation = Mat4d(I),
        uv_transform = Mat{2, 3, Float32}(1,0,0,1,0,0)
    )
    @get_attribute(attributes, (shading, diffuse, specular, shininess, faceculling, clip_planes))

    matcap = to_value(get(attributes, :matcap, nothing))
    transform_marker = to_value(get(attributes, :transform_marker, true))
    meshpoints = decompose(Point3f, mesh)::Vector{Point3f}
    meshfaces = decompose(GLTriangleFace, mesh)::Vector{GLTriangleFace}
    meshnormals = normals(mesh)::Union{Nothing, Vector{Vec3f}} # note: can be made NaN-aware.
    meshuvs = texturecoordinates(mesh)::Union{Nothing, Vector{Vec2f}}

    if meshuvs isa Vector{Vec2f} && to_value(uv_transform) !== nothing
        meshuvs = map(uv -> uv_transform * to_ndim(Vec3f, uv, 1), meshuvs)
    end

    # Prioritize colors of the mesh if present
    color = hasproperty(mesh, :color) ? mesh.color : to_value(attributes.calculated_colors)
    per_face_col = per_face_colors(color, matcap, meshfaces, meshnormals, meshuvs)

    model = attributes.model[]::Mat4d
    space = to_value(get(attributes, :space, :data))::Symbol

    if haskey(attributes, :transform_marker)
        # meshscatter/voxels route:
        # - transform_func does not apply to vertices (only pos)
        # - only scaling from float32convert applies to vertices
        #   f32c_scale * (model) * rotation * scale * vertices  +  f32c * model * transform_func(plot[1])
        # = f32c_model * rotation * scale * vertices  +  pos   (see draw_atomic(meshscatter))
        transform_marker = attributes[:transform_marker][]::Bool
        f32c_model = transform_marker ? strip_translation(model) : Mat4d(I)
        if !isnothing(scene.float32convert) && Makie.is_data_space(space)
            f32c_model = Makie.scalematrix(scene.float32convert.scaling[].scale::Vec3d) * f32c_model
        end
    else
        # mesh/surface path
        # - transform_func applies to vertices here
        # - full float32convert applies to vertices
        # f32c * model * vertices = f32c_model * vertices
        transform_marker = true
        meshpoints = apply_transform(Makie.transform_func(attributes), meshpoints)
        f32c_model = Makie.f32_convert_matrix(scene.float32convert, space) * model
    end

    # TODO: assume Symbol here after this has been deprecated for a while
    if shading isa Bool
        @warn "`shading::Bool` is deprecated. Use `shading = NoShading` instead of false and `shading = FastShading` or `shading = MultiLightShading` instead of true."
        shading_bool = shading
    else
        shading_bool = shading != NoShading
    end

    if !isnothing(meshnormals) && to_value(get(attributes, :invert_normals, false))
        meshnormals .= -meshnormals
    end

    draw_mesh3D(
        scene, screen, space, meshpoints, meshfaces, meshnormals, per_face_col,
        pos, scale, rotation,
        f32c_model::Mat4d, shading_bool::Bool, diffuse::Vec3f,
        specular::Vec3f, shininess::Float32, faceculling::Int, clip_planes
    )
end

function draw_mesh3D(
        scene, screen, space, meshpoints, meshfaces, meshnormals, per_face_col,
        pos, scale, rotation,
        f32c_model, shading, diffuse,
        specular, shininess, faceculling, clip_planes
    )
    ctx = screen.context
    projectionview = Makie.space_to_clip(scene.camera, space, true)
    eyeposition = scene.camera.eyeposition[]

    # local_model applies rotation and markersize from meshscatter to vertices
    i = Vec(1, 2, 3)
    local_model = rotation * Makie.scalematrix(Vec3d(scale))
    normalmatrix = transpose(inv(f32c_model[i, i] * local_model[i, i])) # see issue #3702

    # mesh, surface:        apply f32convert and model to vertices
    # meshscatter, voxels:  apply f32 scale, maybe model, rotation, markersize, positions to vertices
    # (see previous function)
    vs = broadcast(meshpoints) do v
        # Should v get a nan2zero?
        p4d = to_ndim(Vec4d, to_ndim(Vec3d, v, 0), 1)
        p4d = f32c_model * local_model * p4d
        return to_ndim(Vec4f, p4d .+ to_ndim(Vec4d, pos, 0), NaN32)
    end

    if Makie.is_data_space(space) && !isempty(clip_planes)
        valid = Bool[is_visible(clip_planes, p) for p in vs]
    else
        valid = Bool[]
    end

    if isnothing(meshnormals)
        ns = nothing
    else
        ns = map(n -> normalize(normalmatrix * n), meshnormals)
    end

    # Light math happens in view/camera space
    dirlight = Makie.get_directional_light(scene)
    if !isnothing(dirlight)
        lightdirection = if dirlight.camera_relative
            T = inv(scene.camera.view[][Vec(1,2,3), Vec(1,2,3)])
            normalize(T * dirlight.direction[])
        else
            normalize(dirlight.direction[])
        end
        c = dirlight.color[]
        light_color = Vec3f(red(c), green(c), blue(c))
    else
        lightdirection = Vec3f(0,0,-1)
        light_color = Vec3f(0)
    end

    ambientlight = Makie.get_ambient_light(scene)
    ambient = if !isnothing(ambientlight)
        c = ambientlight.color[]
        Vec3f(c.r, c.g, c.b)
    else
        Vec3f(0)
    end

    # Camera to screen space
    ts = map(vs) do v
        clip = projectionview * v
        @inbounds begin
            p = (clip ./ clip[4])[Vec(1, 2)]
            p_yflip = Vec2f(p[1], -p[2])
            p_0_to_1 = (p_yflip .+ 1f0) ./ 2f0
        end
        p = p_0_to_1 .* scene.camera.resolution[]
        return Vec3f(p[1], p[2], clip[3])
    end

    # vs are used as camdir (camera to vertex) for light calculation (in world space)
    vs = map(v -> normalize(v[i] - eyeposition), vs)

    # Approximate zorder
    average_zs = map(f -> average_z(ts, f), meshfaces)
    zorder = sortperm(average_zs)

    # Face culling
    if isempty(valid) && !isnothing(ns)
        zorder = filter(i -> any(last.(ns[meshfaces[i]]) .> faceculling), zorder)
    elseif !isempty(valid)
        zorder = filter(i -> all(valid[meshfaces[i]]), zorder)
    else
        # no clipped faces, no normals to rely on for culling -> do nothing
    end

    draw_pattern(
        ctx, zorder, shading, meshfaces, ts, per_face_col, ns, vs,
        lightdirection, light_color, shininess, diffuse, ambient, specular)
    return
end

function _calculate_shaded_vertexcolors(N, v, c, lightdir, light_color, ambient, diffuse, specular, shininess)
    L = lightdir
    diff_coeff = max(dot(L, -N), 0f0)
    H = normalize(L + v)
    spec_coeff = max(dot(H, -N), 0f0)^shininess
    c = RGBAf(c)
    # if this is one expression it introduces allocations??
    new_c_part1 = (ambient .+ light_color .* diff_coeff .* diffuse) .* Vec3f(c.r, c.g, c.b) #.+
    new_c = new_c_part1 .+ light_color .* specular * spec_coeff
    RGBAf(new_c..., c.alpha)
end

function draw_pattern(ctx, zorder, shading, meshfaces, ts, per_face_col, ns, vs, lightdir, light_color, shininess, diffuse, ambient, specular)
    for k in reverse(zorder)

        f = meshfaces[k]
        # avoid SizedVector through Face indexing
        t1 = ts[f[1]]
        t2 = ts[f[2]]
        t3 = ts[f[3]]

        # skip any mesh segments with NaN points.
        if isnan(t1) || isnan(t2) || isnan(t3)
            continue
        end

        facecolors = per_face_col[k]
        # light calculation
        if shading && !isnothing(ns)
            c1, c2, c3 = Base.Cartesian.@ntuple 3 i -> begin
                # these face index expressions currently allocate for SizedVectors
                # if done like `ns[f]`
                N = ns[f[i]]
                v = vs[f[i]]
                c = facecolors[i]
                _calculate_shaded_vertexcolors(N, v, c, lightdir, light_color, ambient, diffuse, specular, shininess)
            end
        else
            c1, c2, c3 = facecolors
        end

        # debug normal coloring
        # n1, n2, n3 = Vec3f(0.5) .+ 0.5ns[f]
        # c1 = RGB(n1...)
        # c2 = RGB(n2...)
        # c3 = RGB(n3...)

        pattern = Cairo.CairoPatternMesh()

        Cairo.mesh_pattern_begin_patch(pattern)

        Cairo.mesh_pattern_move_to(pattern, t1[1], t1[2])
        Cairo.mesh_pattern_line_to(pattern, t2[1], t2[2])
        Cairo.mesh_pattern_line_to(pattern, t3[1], t3[2])

        mesh_pattern_set_corner_color(pattern, 0, c1)
        mesh_pattern_set_corner_color(pattern, 1, c2)
        mesh_pattern_set_corner_color(pattern, 2, c3)

        Cairo.mesh_pattern_end_patch(pattern)
        Cairo.set_source(ctx, pattern)
        Cairo.close_path(ctx)
        Cairo.paint(ctx)
        Cairo.destroy(pattern)
    end

end

################################################################################
#                                   Surface                                    #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.Surface))
    # Pretend the surface plot is a mesh plot and plot that instead
    mesh = Makie.surface2mesh(primitive[1][], primitive[2][], primitive[3][])
    old = primitive[:color]
    if old[] === nothing
        primitive[:color] = primitive[3]
    end
    if !haskey(primitive, :faceculling)
        primitive[:faceculling] = Observable(-10)
    end
    uv_transform = Makie.convert_attribute(primitive[:uv_transform][], Makie.key"uv_transform"(), Makie.key"surface"())
    draw_mesh3D(scene, screen, primitive, mesh; uv_transform = uv_transform)
    primitive[:color] = old
    return nothing
end


################################################################################
#                                 MeshScatter                                  #
################################################################################


function _transform_to_world(scene::Scene, @nospecialize(plot), pos)
    space = plot.space[]::Symbol
    model = plot.model[]::Mat4d
    f32_model = Makie.f32_convert_matrix(scene.float32convert, space) * model
    tf = Makie.transform_func(plot)
    return _transform_to_world(f32_model, tf, space, pos)
end

function _transform_to_world(f32_model, tf, space, pos)
    return map(pos) do p
        transformed = Makie.apply_transform(tf, p, space)
        p4d = to_ndim(Point4d, to_ndim(Point3d, transformed, 0), 1)
        p4d = f32_model * p4d
        return p4d[Vec(1,2,3)] / p4d[4]
    end
end

function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.MeshScatter))
    @get_attribute(primitive, (model, marker, markersize, rotation))

    # We combine vertices and positions in world space. Here we do the
    # transformation to world space
    transformed_pos = _transform_to_world(scene, primitive, primitive[1][])

    # For correct z-ordering we need to be in view/camera or screen space
    view = scene.camera.view[]
    zorder = sortperm(transformed_pos, by = p -> begin
        p4d = to_ndim(Vec4d, p, 1)
        cam_pos = view[Vec(3,4), Vec(1,2,3,4)] * p4d
        cam_pos[1] / cam_pos[2]
    end, rev=false)

    color = to_color(primitive.calculated_colors[])
    submesh = Attributes(
        model = model,
        calculated_colors = color,
        shading = primitive.shading, diffuse = primitive.diffuse,
        specular = primitive.specular, shininess = primitive.shininess,
        faceculling = get(primitive, :faceculling, -10),
        transformation = Makie.transformation(primitive),
        clip_planes = primitive.clip_planes,
        transform_marker = primitive.transform_marker
    )

    uv_transform = Makie.convert_attribute(primitive[:uv_transform][], Makie.key"uv_transform"(), Makie.key"meshscatter"())
    for i in zorder
        if color isa AbstractVector
            submesh[:calculated_colors] = color[i]
        end
        scale = markersize isa Vector ? markersize[i] : markersize
        _rotation = Makie.rotationmatrix4(to_rotation(Makie.sv_getindex(rotation, i)))
        _uv_transform = Makie.sv_getindex(uv_transform, i)

        draw_mesh3D(
            scene, screen, submesh, marker, pos = transformed_pos[i],
            scale = scale isa Real ? Vec3f(scale) : to_ndim(Vec3f, scale, 1f0),
            rotation = _rotation, uv_transform = _uv_transform
        )
    end

    return nothing
end



################################################################################
#                                    Voxel                                     #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.Voxels))
    pos = Makie.voxel_positions(primitive)
    scale = Makie.voxel_size(primitive)
    colors = Makie.voxel_colors(primitive)
    marker = GeometryBasics.expand_faceviews(normal_mesh(Rect3f(Point3f(-0.5), Vec3f(1))))

    # transformation to world space
    transformed_pos = _transform_to_world(scene, primitive, pos)

    # Face culling
    if !isempty(primitive.clip_planes[]) && Makie.is_data_space(primitive.space[])
        valid = [is_visible(primitive.clip_planes[], p) for p in transformed_pos]
        transformed_pos = transformed_pos[valid]
        colors = colors[valid]
    end

    # For correct z-ordering we need to be in view/camera or screen space
    view = scene.camera.view[]
    zorder = sortperm(transformed_pos, by = p -> begin
        p4d = to_ndim(Vec4d, p, 1)
        cam_pos = view[Vec(3,4), Vec(1,2,3,4)] * p4d
        cam_pos[1] / cam_pos[2]
    end, rev=false)

    submesh = Attributes(
        model = primitive.model,
        shading = primitive.shading, diffuse = primitive.diffuse,
        specular = primitive.specular, shininess = primitive.shininess,
        faceculling = get(primitive, :faceculling, -10),
        transformation = Makie.transformation(primitive),
        clip_planes = Plane3f[],
        transform_marker = true
    )

    for i in zorder
        submesh[:calculated_colors] = colors[i]
        draw_mesh3D(scene, screen, submesh, marker, pos = transformed_pos[i], scale = scale)
    end

    return nothing
end
