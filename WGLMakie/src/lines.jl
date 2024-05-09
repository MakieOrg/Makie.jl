function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    Makie.@converted_attribute plot (linewidth, linestyle, linecap, joinstyle)

    uniforms = Dict(
        :model => map(Makie.patch_model, f32_conversion_obs(plot), plot.model),
        :depth_shift => plot.depth_shift,
        :picking => false,
        :linecap => linecap,
        :scene_origin => map(vp -> Vec2f(origin(vp)), plot, scene.viewport)
    )
    if plot isa Lines
        uniforms[:joinstyle] = joinstyle
        uniforms[:miter_limit] = map(x -> cos(pi - x), plot, plot.miter_limit)
    end

    # TODO: maybe convert nothing to Sampler([-1.0]) to allowed dynamic linestyles?
    if isnothing(to_value(linestyle))
        uniforms[:pattern] = false
        uniforms[:pattern_length] = 1f0
    else
        uniforms[:pattern] = Sampler(lift(Makie.linestyle_to_sdf, plot, linestyle); x_repeat=:repeat)
        uniforms[:pattern_length] = lift(ls -> Float32(last(ls) - first(ls)), linestyle)
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
    indices = Observable(Int[])
    points_transformed = lift(
            plot, f32_conversion_obs(scene), transform_func_obs(plot), plot[1], plot.space
        ) do f32c, tf, ps, space

        transformed_points = apply_transform_and_f32_conversion(f32c, tf, ps, space)
        # TODO: Do this in javascript?
        if isempty(transformed_points)
            empty!(indices[])
            notify(indices)
            return transformed_points
        else
            sizehint!(empty!(indices[]), length(transformed_points) + 2)
            was_nan = true
            for i in eachindex(transformed_points)
                # dublicate first and last element of line selection
                if isnan(transformed_points[i])
                    if !was_nan
                        push!(indices[], i-1) # end of line dublication
                    end
                    was_nan = true
                elseif was_nan
                    push!(indices[], i) # start of line dublication
                    was_nan = false
                end

                push!(indices[], i)
            end
            push!(indices[], length(transformed_points))
            notify(indices)

            return transformed_points[indices[]]
        end
    end
    positions = lift(serialize_buffer_attribute, plot, points_transformed)
    attributes = Dict{Symbol, Any}(:linepoint => positions)

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
        attributes[:lastlen] = map(plot, points_transformed, pvm, cam.resolution) do ps, pvm, res
            output = Vector{Float32}(undef, length(ps))

            if !isempty(ps)
                # clip -> pixel, but we can skip offset
                scale = Vec2f(0.5 * res[1], 0.5 * res[2])
                # Initial position
                clip = pvm * to_ndim(Point4f, to_ndim(Point3f, ps[1], 0f0), 1f0)
                prev = scale .* Point2f(clip) ./ clip[4]

                # calculate cumulative pixel scale length
                output[1] = 0f0
                for i in 2:length(ps)
                    clip = pvm * to_ndim(Point4f, to_ndim(Point3f, ps[i], 0f0), 1f0)
                    current = scale .* Point2f(clip) ./ clip[4]
                    l = norm(current - prev)
                    output[i] = ifelse(isnan(l), 0f0, output[i-1] + l)
                    prev = current
                end
            end

            return serialize_buffer_attribute(output)
        end
    else
        attributes[:lastlen] = map(plot, points_transformed) do ps
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
        :overdraw => plot.overdraw
    )
    return attr
end
