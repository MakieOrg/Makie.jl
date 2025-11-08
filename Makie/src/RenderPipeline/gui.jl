# An attempt at a graphical editor for RenderPipeline

function pipeline_gui!(ax, pipeline)
    width = 5

    rects = Rect2f[]
    header_line = Point2f[]
    header = Tuple{String, Point2f}[]
    marker_pos = Vector{Point2f}[]
    input = Vector{Tuple{String, Point2f}}[]
    output = Vector{Tuple{String, Point2f}}[]
    stageio_lookup = Tuple{Int, Int}[]

    max_size = 0
    max_size2 = 0

    for (idx, stage) in enumerate(pipeline.stages)
        output_height = length(stage.outputs)
        height = length(stage.inputs) + output_height

        r = Rect2f(-width / 2, -height, width, height + 2)
        push!(rects, r)
        push!(header_line, Point2f(-0.5width, 0), Point2f(0.5width, 0))
        push!(header, (string(stage.name), Point2f(0, 1)))

        ops = sort!([(string(s), Point2f(0.5width, 0.5 - y)) for (s, y) in stage.outputs], by = x -> -x[2][2])
        ips = sort!(
            [(string(s), Point2f(-0.5width, 0.5 - y - output_height)) for (s, y) in stage.inputs],
            by = x -> -x[2][2]
        )

        push!(input, ips)
        push!(output, ops)
        push!(marker_pos, vcat(last.(ips), last.(ops)))
        append!(stageio_lookup, [(idx, -i) for i in 1:length(stage.inputs)])
        append!(stageio_lookup, [(idx, i) for i in 1:length(stage.outputs)])

        if max_size < length(stage.inputs) + length(stage.outputs)
            max_size2 = max_size
            max_size = length(stage.inputs) + length(stage.outputs)
        end
    end


    origins = Observable([Point2f(8x, 0) for x in eachindex(pipeline.stages)])

    # Do something to get better starting layout...
    begin
        shift = 0.5 * (4 + max_size + max_size2 + 1)
        # vector[connection idx] = [(stage idx, input/output index)] (- input, + output)
        conn2stageio = [Tuple{Int, Int}[] for _ in eachindex(pipeline.formats)]
        for (stageio, conn) in pipeline.stageio2idx
            push!(conn2stageio[conn], stageio)
        end

        for i in length(pipeline.stages):-1:1
            targets = Int[]
            for j in eachindex(pipeline.stages[i].input_formats)
                if haskey(pipeline.stageio2idx, (i, -j))
                    conn_idx = pipeline.stageio2idx[(i, -j)]
                    for (stage_idx, io) in conn2stageio[conn_idx]
                        if io > 0 # is output
                            push!(targets, stage_idx)
                        end
                    end
                end
            end

            if !isempty(targets)
                y0 = 0.5 * (length(targets) + 1)
                for (j, stage_idx) in enumerate(targets)
                    origins[][stage_idx] = Point2f(origins[][stage_idx][1], origins[][i][2]) + Point2f(0, shift * (y0 - j))
                end
            end
        end
    end

    rects_obs = Observable(Rect2f[])
    header_line_obs = Observable(Point2f[])
    header_obs = Observable(Tuple{String, Point2f}[])
    marker_pos_obs = Observable(Point2f[])
    input_obs = Observable(Tuple{String, Point2f}[])
    output_obs = Observable(Tuple{String, Point2f}[])
    path_ps_obs = Observable(Point2f[])
    path_cs_obs = Observable(RGBf[])

    on(origins) do origins
        rects_obs[] = rects .+ origins
        header_line_obs[] = [origins[i] .+ header_line[2(i - 1) + j] for i in eachindex(origins) for j in 1:2]
        header_obs[] = map((x, pos) -> (x[1], pos + x[2]), header, origins)

        marker_pos_obs[] = mapreduce(vcat, marker_pos, origins) do ps, pos
            return [p + pos for p in ps]
        end
        input_obs[] = mapreduce(vcat, input, origins) do input, pos
            return [(x[1], x[2] + pos) for x in input]
        end
        output_obs[] = mapreduce(vcat, output, origins) do input, pos
            return [(x[1], x[2] + pos) for x in input]
        end
    end

    function bezier_connect(p0, p1)
        x0, y0 = ifelse(p0[1] < p1[1], p0, p1)
        x1, y1 = ifelse(p0[1] < p1[1], p1, p0)
        mid = 0.5 * (x0 + x1)
        path = Any[Makie.MoveTo(x0, y0)]
        if (x1 - x0) > 10
            push!(
                path,
                Makie.LineTo(Point2f(mid - 5, y0)),
                Makie.CurveTo(Point2f(mid + 1, y0), Point2f(mid - 1, y1), Point2f(mid + 5, y1)),
                Makie.LineTo(Point2f(x1, y1))
            )
        else
            push!(path, Makie.CurveTo(Point2f(mid + 1, y0), Point2f(mid - 1, y1), Point2f(x1, y1)))
        end
        path = Makie.BezierPath(path)
        return Makie.convert_arguments(PointBased(), path)[1]
    end

    on(origins) do origins
        # vector[connection idx] = [(stage idx, input/output index)] (- input, + output)
        conn2stageio = [Tuple{Int, Int}[] for _ in eachindex(pipeline.formats)]
        for (stageio, conn) in pipeline.stageio2idx
            push!(conn2stageio[conn], stageio)
        end

        paths = Point2f[]
        color_pool = Makie.to_colormap(:seaborn_bright)
        cs = RGBf[]
        for (idx, stageio) in enumerate(conn2stageio)
            sort!(stageio, by = first)
            N = length(stageio)
            for i in 1:(N - 1)
                start_stage, start_idx = stageio[i]
                start_idx < 0 && continue # is a stage input
                for j in (i + 1):N
                    stop_stage, stop_idx = stageio[j]
                    stop_idx > 0 && continue # is a stage output
                    p0 = output[start_stage][start_idx][2] + origins[start_stage]
                    p1 = input[stop_stage][-stop_idx][2] + origins[stop_stage]
                    ps = bezier_connect(p0, p1)
                    append!(paths, ps)
                    push!(paths, Point2f(NaN))
                    append!(cs, [color_pool[mod1(idx, end)] for _ in ps])
                    push!(cs, RGBf(0, 0, 0))
                end
            end
        end
        path_ps_obs.val = paths
        path_cs_obs[] = cs
        notify(path_ps_obs)
        return
    end

    notify(origins)

    scale = map(pv -> max(0.5, 10 * min(pv[1, 1], pv[2, 2])), get_scene(ax).camera.projectionview)

    poly!(
        ax, rects_obs, strokewidth = scale, strokecolor = :black, fxaa = false,
        shading = NoShading, color = :lightgray, transparency = false
    )
    linesegments!(ax, header_line_obs, linewidth = scale, color = :black)
    text!(
        ax, header_obs, markerspace = :data, fontsize = 0.8, color = :black,
        align = (:center, :center)
    )

    text!(
        ax, output_obs, markerspace = :data, fontsize = 0.75, color = :black,
        align = (:right, :center), offset = (-0.25, 0)
    )
    text!(
        ax, input_obs, markerspace = :data, fontsize = 0.75, color = :black,
        align = (:left, :center), offset = (0.25, 0)
    )

    p = scatter!(ax, marker_pos_obs, color = :black, markerspace = :data, marker = Circle, markersize = 0.3)
    translate!(p, 0, 0, 1)

    p = lines!(ax, path_ps_obs, color = path_cs_obs)
    translate!(p, 0, 0, -1)

    new_conn_plot = lines!(ax, Point2f[], color = :black, visible = false)

    # Drag RenderStages around & connect inputs/outputs
    selected_idx = Ref(-1)
    connecting = Ref(false) # true = drawing line - false = moving stage
    drag_offset = Ref(Point2f(0))
    start_pos = Ref(Point2f(0))
    io_range = 0.4
    on(events(ax).mousebutton, priority = 100) do event
        if event.button == Mouse.left
            if event.action == Mouse.press
                pos = mouseposition(ax)
                for (i, p) in enumerate(marker_pos_obs[])
                    if norm(pos - p) < io_range
                        selected_idx[] = i
                        connecting[] = true
                        start_pos[] = p
                        return Consume(true)
                    end
                end
                for (i, rect) in enumerate(rects_obs[])
                    if pos in rect
                        selected_idx[] = i
                        connecting[] = false
                        drag_offset[] = origins[][i] - pos
                        return Consume(true)
                    end
                end
            elseif (event.action == Mouse.release) && (selected_idx[] != -1)
                if connecting[]
                    pos = mouseposition(ax)
                    for (i, p) in enumerate(marker_pos_obs[])
                        if norm(pos - p) < io_range
                            start_stage, start_io = stageio_lookup[selected_idx[]]
                            stop_stage, stop_io = stageio_lookup[i]
                            @info start_stage, start_io, stop_stage, stop_io
                            if (start_io > 0) && (stop_io < 0) && (start_stage < stop_stage) # output to input
                                Makie.connect!(pipeline, start_stage, start_io, stop_stage, -stop_io)
                                notify(origins) # trigger redraw of connections
                            elseif (start_io < 0) && (stop_io > 0) && (stop_stage < start_stage) # input to output
                                Makie.connect!(pipeline, stop_stage, stop_io, start_stage, -start_io)
                                notify(origins) # trigger redraw of connections
                            end
                            selected_idx[] = -1
                            new_conn_plot.visible[] = false
                            return Consume(true)
                        end
                    end
                end
                new_conn_plot.visible[] = false
                selected_idx[] = -1
                return Consume(true)
            end
        end
        return Consume(false)
    end

    on(events(ax).mouseposition, priority = 100) do event
        if selected_idx[] != -1
            curr = mouseposition(ax)
            if connecting[]
                new_conn_plot[1][] = bezier_connect(start_pos[], curr)
                new_conn_plot.visible[] = true
            else
                origins[][selected_idx[]] = curr + drag_offset[]
                notify(origins)
            end
            return Consume(true)
        end
        return Consume(false)
    end

    return on(events(ax).keyboardbutton, priority = 100) do event
        if (event.key == Keyboard.o) && (event.action == Keyboard.press)
            @info origins[]
        end
    end

end
