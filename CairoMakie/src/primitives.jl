################################################################################
#                             Lines, LineSegments                              #
################################################################################

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
            # For 3D compatibility (and rotation, inversion/mirror) we pad cells
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

function draw_mesh2D(screen, color, vs::Vector{<: Point2}, fs::Vector{GLTriangleFace})
    return draw_mesh2D(screen.context, color, vs, fs, eachindex(fs))
end

function draw_mesh2D(ctx::Cairo.CairoContext, per_face_cols, vs::Vector, fs::Vector{GLTriangleFace}, indices)
    # Prioritize colors of the mesh if present
    # This is a hack, which needs cleaning up in the Mesh plot type!

    for i in indices
        c1, c2, c3 = per_face_cols[i]
        t1, t2, t3 =  vs[fs[i]] #triangle points

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

function draw_mesh2D(ctx::Cairo.CairoContext, pattern::Cairo.CairoPattern, vs::Vector, fs::Vector{GLTriangleFace}, indices)
    # Prioritize colors of the mesh if present
    # This is a hack, which needs cleaning up in the Mesh plot type!
    Cairo.set_source(ctx, pattern)

    for i in indices
        t1, t2, t3 = vs[fs[i]] # triangle points

        # don't draw any mesh faces with NaN components.
        if isnan(t1) || isnan(t2) || isnan(t3)
            continue
        end

        # TODO:
        # - this may create gaps like heatmap?
        # - for some reason this is liqhter than it should be?
        Cairo.move_to(ctx, t1[1], t1[2])
        Cairo.line_to(ctx, t2[1], t2[2])
        Cairo.line_to(ctx, t3[1], t3[2])
        Cairo.close_path(ctx)
        Cairo.fill(ctx);
    end
    pattern_set_matrix(pattern, Cairo.CairoMatrix(1, 0, 0, 1, 0, 0))
    return nothing
end

function average_z(positions, face)
    vs = positions[face]
    sum(v -> v[3], vs) / length(vs)
end

function strip_translation(M::Mat4{T}) where {T}
    return @inbounds Mat4{T}(
        M[1], M[2], M[3], M[4],
        M[5], M[6], M[7], M[8],
        M[9], M[10], M[11], M[12],
        0, 0, 0, M[16],
    )
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

# Still used for voxels
function _transform_to_world(scene::Scene, @nospecialize(plot), pos)
    space = plot.space[]::Symbol
    model = plot.model[]::Mat4d
    f32_model = Makie.f32_convert_matrix(scene.float32convert, space) * model
    tf = Makie.transform_func(plot)
    return _transform_to_world(f32_model, tf, pos)
end

function _transform_to_world(f32_model, tf, pos)
    return map(pos) do p
        transformed = Makie.apply_transform(tf, p)
        p4d = to_ndim(Point4d, to_ndim(Point3d, transformed, 0), 1)
        p4d = f32_model * p4d
        return p4d[Vec(1,2,3)] / p4d[4]
    end
end
