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




################################################################################
#                                Heatmap, Image                                #
################################################################################



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
