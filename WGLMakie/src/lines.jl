function nan_free_points_indices((inpoints,), changed, last)
    last_indices = isnothing(last) ? UInt32[] : last[2][]
    points = inpoints[]
    isempty(points) && return (points, last_indices)
    indices = UInt32[]
    sizehint!(indices, length(points) + 2)
    was_nan = true
    loop_start = -1
    for (i, p) in pairs(points)
        if isnan(p)
            # line section end (last was value, now nan)
            if !was_nan
                # does previous point close loop?
                # loop started && 3+ segments && start == end
                if loop_start != -1 &&
                    (loop_start + 2 < length(indices)) &&
                    (points[indices[loop_start]] ≈ points[i - 1])

                    #               start -v             v- end
                    # adjust from       j  j j+1 .. i-2 i-1
                    # to           nan i-2 j j+1 .. i-2 i-1 j+1 nan
                    # where start == end thus j == i-1
                    # if nan is present in a quartet of vertices
                    # (nan, i-2, j, i+1) the segment (i-2, j) will not
                    # be drawn (which we want as that segment would overlap)

                    # tweak duplicated vertices to be loop vertices
                    push!(indices, indices[loop_start + 1])
                    indices[loop_start - 1] = i - 2
                    # nan is inserted at bottom (and not necessary for start/end)
                else # no loop, duplicate end point
                    push!(indices, i - 1)
                end
            end
            loop_start = -1
            was_nan = true
        else
            if was_nan
                # line section start - duplicate point
                push!(indices, i)
                # first point in a potential loop
                loop_start = length(indices) + 1
            end
            was_nan = false
        end
        # push normal line point (including nan)
        push!(indices, i)
    end
    # Finish line (insert duplicate end point or close loop)
    if !was_nan
        if loop_start != -1 &&
            (loop_start + 2 < length(indices)) &&
            (points[indices[loop_start]] ≈ points[end])
            push!(indices, indices[loop_start + 1])
            indices[loop_start - 1] = prevind(points, lastindex(points))
        else
            push!(indices, lastindex(points))
        end
    end
    indices_changed = indices != last_indices
    points_changed = changed[1] || indices_changed
    return (points_changed ? points[indices] : nothing, indices == last_indices ? nothing : indices)
end

function create_lines_data(islines, attr)

    uniforms = Dict(
        :model => attr.model_f32c[],
        :depth_shift => attr.depth_shift[],
        :picking => false,
        :linecap => attr.linecap[],
        :scene_origin => attr.scene_origin[],
    )
    if islines
        uniforms[:joinstyle] = attr.joinstyle[]
        uniforms[:miter_limit] = attr.gl_miter_limit[]
    end

    if isnothing(attr.linestyle[])
        uniforms[:pattern] = false
        uniforms[:pattern_length] = 1.0f0
    else
        uniforms[:pattern] = Sampler(attr.gl_pattern[]; x_repeat=:repeat)
        uniforms[:pattern_length] = attr.gl_pattern_length[]
    end

    if !isnothing(attr.scaled_colorrange[])
        uniforms[:colormap] = Sampler(attr.alpha_colormap[])
        uniforms[:colorrange] = attr.scaled_colorrange[]
        uniforms[:highclip] = attr._highclip[]
        uniforms[:lowclip] = attr._lowclip[]
        uniforms[:nan_color] = attr.nan_color[]
        color = attr.scaled_color[]
    else
        for name in [:nan_color, :highclip, :lowclip]
            uniforms[name] = RGBAf(0, 0, 0, 0)
        end
        uniforms[:colormap] = false
        uniforms[:colorrange] = false
        color = attr.scaled_color[]
    end

    to_buff_obs(x) = Observable(serialize_buffer_attribute(x))

    attributes = Dict{Symbol,Any}(
        :linepoint => to_buff_obs(attr.linepoint[]),
        :lineindex => to_buff_obs(attr.lineindex[]),
        :lastlen => to_buff_obs(zeros(Float32, length(attr.linepoint[]))),
    )

    for (name, vals) in [:color => color, :linewidth => attr.linewidth[]]
        if Makie.is_scalar_attribute(to_value(vals))
            uniforms[Symbol("$(name)_start")] = vals
            uniforms[Symbol("$(name)_end")] = vals
        else
            # TODO: to js?
            # duplicates per vertex attributes to match positional duplication
            # min(idxs, end) avoids update order issues here
            attributes[name] = Observable(serialize_buffer_attribute(vals))
        end
    end

    uniforms[:num_clip_planes] = 0
    uniforms[:clip_planes] = [Vec4f(0, 0, 0, -1e9) for _ in 1:8]

    return Dict(
        :visible => Observable(attr.visible[]),
        :plot_type => islines ? "lines" : "linesegments",
        :cam_space => attr.space[],
        :uniforms => serialize_uniforms(uniforms),
        :attributes => attributes,
        :transparency => attr.transparency[],
        :overdraw => false, # TODO
        :zvalue => 0,
    )
end

const LINE_INPUTS = [
    # relevant to compile time decisions
    :space,
    :scaled_color,
    :alpha_colormap,
    :scaled_colorrange,
    # Auto
    :linepoint,
    :lineindex,
    :linecap,
    :linestyle,
    :gl_pattern,
    :gl_pattern_length,
    :linewidth,
    :scene_origin,
    :transparency,
    :visible,
    :model_f32c,
    :_lowclip,
    :_highclip,
    :nan_color,
    :depth_shift,
]

function create_lines_robj(islines, args, changed, last)
    inputs = copy(LINE_INPUTS)
    r = Dict{Symbol, Symbol}()
    if islines
        push!(inputs, :joinstyle, :gl_miter_limit)
    end
    if isnothing(last)
        return (create_lines_data(islines, (; zip(inputs, args)...)), Observable([]))
    else
        new_values = [
            [get(r, inputs[i], inputs[i]), serialize_three(args[i][])] for i in 1:length(inputs) if changed[i]
        ]
        updater = last[2][]
        updater[] = new_values
        return nothing
    end
end

function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    attr = plot.args[1]

    Makie.add_computation!(attr, scene, :scene_origin)
    Makie.add_computation!(attr, :gl_pattern, :gl_pattern_length)

    islines = plot isa Lines
    inputs = copy(LINE_INPUTS)

    if islines
        Makie.add_computation!(attr, :gl_miter_limit)
        push!(inputs, :joinstyle, :gl_miter_limit)
    end

    register_computation!(
        nan_free_points_indices, attr, [:positions_transformed_f32c], [:linepoint, :lineindex]
    )

    register_computation!(
        (args...) -> create_lines_robj(islines, args...), attr, inputs, [:wgl_renderobject, :wgl_update_obs]
    )

    dict = attr[:wgl_renderobject][]
    dict[:uuid] = js_uuid(plot)
    dict[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    dict[:updater] = attr[:wgl_update_obs][]
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return
    end
    return dict
end
