function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    Makie.@converted_attribute plot (linewidth, linestyle, linecap, joinstyle)

    f32c, model = Makie.patch_model(plot)
    uniforms = Dict(
        :model => model,
        :depth_shift => plot.depth_shift,
        :picking => false,
        :linecap => linecap,
        :scene_origin => lift(vp -> Vec2f(origin(vp)), plot, scene.viewport)
    )
    if plot isa Lines
        uniforms[:joinstyle] = joinstyle
        uniforms[:miter_limit] = lift(x -> cos(pi - x), plot, plot.miter_limit)
    end

    # TODO: maybe convert nothing to Sampler([-1.0]) to allowed dynamic linestyles?
    if isnothing(to_value(linestyle))
        uniforms[:pattern] = false
        uniforms[:pattern_length] = 1f0
    else
        uniforms[:pattern] = Sampler(lift(Makie.linestyle_to_sdf, plot, linestyle); x_repeat=:repeat)
        uniforms[:pattern_length] = lift(ls -> Float32(last(ls) - first(ls)), plot, linestyle)
    end

    color = plot.calculated_colors
    if color[] isa Makie.ColorMapping
        uniforms[:colormap] = Sampler(color[].colormap)
        uniforms[:colorrange] = color[].colorrange_scaled
        uniforms[:highclip] = Makie.highclip(color[])
        uniforms[:lowclip] = Makie.lowclip(color[])
        uniforms[:nan_color] = color[].nan_color
        color = color[].color_scaled
    else
        for name in [:nan_color, :highclip, :lowclip]
            uniforms[name] = RGBAf(0, 0, 0, 0)
        end
        get!(uniforms, :colormap, false)
        get!(uniforms, :colorrange, false)
    end

    # This is mostly NaN handling. The shader only draws a segment if each
    # involved point are not NaN, i.e. p1 -- p2 is only drawn if all of
    # (p0, p1, p2, p3) are not NaN. So if p3 is NaN we need to dublicate p2 to
    # make the p1 -- p2 segment draw, which is what indices does.
    indices = Observable(UInt32[])
    points_transformed = lift(
            plot, f32c, transform_func_obs(plot), plot.model, plot[1], plot.space
        ) do f32c, tf, model, ps, space

        transformed_points = apply_transform_and_f32_conversion(f32c, tf, model, ps, space)
        # TODO: Do this in javascript?
        empty!(indices[])
        if isempty(transformed_points)
            notify(indices)
            return transformed_points
        else
            sizehint!(indices[], length(transformed_points) + 2)

            was_nan = true
            loop_start_idx = -1
            for (i, p) in pairs(transformed_points)
                if isnan(p)
                    # line section end (last was value, now nan)
                    if !was_nan
                        # does previous point close loop?
                        # loop started && 3+ segments && start == end
                        if loop_start_idx != -1 && (loop_start_idx + 2 < length(indices[])) &&
                            (transformed_points[indices[][loop_start_idx]] ≈ transformed_points[i-1])

                            #               start -v             v- end
                            # adjust from       j  j j+1 .. i-2 i-1
                            # to           nan i-2 j j+1 .. i-2 i-1 j+1 nan
                            # where start == end thus j == i-1
                            # if nan is present in a quartet of vertices
                            # (nan, i-2, j, i+1) the segment (i-2, j) will not
                            # be drawn (which we want as that segment would overlap)

                            # tweak dublicated vertices to be loop vertices
                            push!(indices[], indices[][loop_start_idx+1])
                            indices[][loop_start_idx-1] = i-2
                            # nan is inserted at bottom (and not necessary for start/end)

                        else # no loop, dublicate end point
                            push!(indices[], i-1)
                        end
                    end
                    loop_start_idx = -1
                    was_nan = true
                else

                    if was_nan
                        # line section start - dublicate point
                        push!(indices[], i)
                        # first point in a potential loop
                        loop_start_idx = length(indices[])+1
                    end
                    was_nan = false
                end

                # push normal line point (including nan)
                push!(indices[], i)
            end

            # Finish line (insert dublicate end point or close loop)
            if !was_nan
                if loop_start_idx != -1 && (loop_start_idx + 2 < length(indices[])) &&
                    (transformed_points[indices[][loop_start_idx]] ≈ transformed_points[end])

                    push!(indices[], indices[][loop_start_idx+1])
                    indices[][loop_start_idx-1] = prevind(transformed_points, lastindex(transformed_points))
                else
                    push!(indices[], lastindex(transformed_points))
                end
            end

            return transformed_points[indices[]]
        end
    end
    positions = lift(serialize_buffer_attribute, plot, points_transformed)
    attributes = Dict{Symbol, Any}(
        :linepoint => positions,
        :lineindex => lift(_ -> serialize_buffer_attribute(indices[]), plot, points_transformed),
    )

    # TODO: in Javascript
    # NOTE: clip.w needs to be available in shaders to avoid line inversion problems
    #       if transformations are done on the CPU (compare with GLMakie)
    # This calculates the cumulative pixel-space distance of each point from the
    # last start point of a line. (I.e. from either the first point or the first
    # point after the last NaN)
    if plot isa Lines && to_value(linestyle) isa Vector
        cam = Makie.parent_scene(plot).camera
        pvm = lift(plot, cam.projectionview, cam.pixel_space, plot.space, uniforms[:model]) do _, _, space, model
            return Makie.space_to_clip(cam, space, true) * model
        end
        attributes[:lastlen] = lift(plot, points_transformed, pvm, cam.resolution) do ps, pvm, res
            output = Vector{Float32}(undef, length(ps))

            if !isempty(ps)
                # clip -> pixel, but we can skip scene offset
                scale = Vec2f(0.5 * res[1], 0.5 * res[2])
                # position of start of first drawn line segment (TODO: deal with multiple nans at start)
                clip = pvm * to_ndim(Point4f, to_ndim(Point3f, ps[2], 0f0), 1f0)
                prev = scale .* Point2f(clip) ./ clip[4]

                # calculate cumulative pixel scale length
                output[1] = 0f0   # dublicated point
                output[2] = 0f0   # start of first line segment
                output[end] = 0f0 # dublicated end point
                i = 3           # end of first line segment, start of second
                while i < length(ps)
                    if isfinite(ps[i])
                        clip = pvm * to_ndim(Point4f, to_ndim(Point3f, ps[i], 0f0), 1f0)
                        current = scale .* Point2f(clip) ./ clip[4]
                        l = norm(current - prev)
                        output[i] = output[i-1] + l
                        prev = current
                        i += 1
                    else
                        # a vertex section (NaN, A, B, C) does not draw, so
                        # norm(B - A) should not contribute to line length.
                        # (norm(B - A) is 0 for capped lines but not for loops)
                        output[i] = 0f0
                        output[i+1] = 0f0
                        if i+2 <= length(ps)
                            output[min(end, i+2)] = 0f0
                            clip = pvm * to_ndim(Point4f, to_ndim(Point3f, ps[i+2], 0f0), 1f0)
                            prev = scale .* Point2f(clip) ./ clip[4]
                        end
                        i += 3
                    end
                end
            end

            return serialize_buffer_attribute(output)
        end
    else
        attributes[:lastlen] = lift(plot, points_transformed) do ps
            return serialize_buffer_attribute(zeros(Float32, length(ps)))
        end
    end

    for (name, attr) in [:color => color, :linewidth => linewidth]
        if Makie.is_scalar_attribute(to_value(attr))
            uniforms[Symbol("$(name)_start")] = attr
            uniforms[Symbol("$(name)_end")] = attr
        else
            # TODO: to js?
            # dublicates per vertex attributes to match positional dublication
            # min(idxs, end) avoids update order issues here
            attributes[name] = lift(plot, indices, attr) do idxs, vals
                serialize_buffer_attribute(vals[min.(idxs, end)])
            end
        end
    end

    # Handle clip planes
    uniforms[:num_clip_planes] = lift(plot, plot.clip_planes, plot.space) do planes, space
        return Makie.is_data_space(space) ? length(planes) : 0
    end

    uniforms[:clip_planes] = lift(plot, scene.camera.projectionview, plot.clip_planes, plot.space) do pv, planes, space
        Makie.is_data_space(space) || return [Vec4f(0, 0, 0, -1e9) for _ in 1:8]

        if length(planes) > 8
            @warn("Only up to 8 clip planes are supported. The rest are ignored!", maxlog = 1)
        end

        clip_planes = Makie.to_clip_space(pv, planes)

        output = Vector{Vec4f}(undef, 8)
        for i in 1:min(length(planes), 8)
            output[i] = Makie.gl_plane_format(clip_planes[i])
        end
        for i in min(length(planes), 8)+1:8
            output[i] = Vec4f(0, 0, 0, -1e9)
        end
        return output
    end

    attr = Dict(
        :name => string(Makie.plotkey(plot)) * "-" * string(objectid(plot)),
        :visible => plot.visible,
        :uuid => js_uuid(plot),
        :plot_type => plot isa LineSegments ? "linesegments" : "lines",
        :cam_space => plot.space[],
        :uniforms => serialize_uniforms(uniforms),
        :uniform_updater => uniform_updater(plot, uniforms),
        :attributes => attributes,
        :transparency => plot.transparency,
        :overdraw => plot.overdraw,
        :zvalue => Makie.zvalue2d(plot)
    )
    return attr
end
