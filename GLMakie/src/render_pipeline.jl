function create_buffer!(factory::FramebufferFactory, format::Makie.BufferFormat)
    T = if format.dims == 1
        format.type
    elseif format.type == Makie.Float8
        (RGB, RGBA)[format.dims-2]{format.type}
    else
        Vec{format.dims, format.type}
    end
    tex = Texture(T, size(factory), minfilter = :linear, x_repeat = :clamp_to_edge)
    # tex = Texture(T, size(factory), minfilter = :nearest, x_repeat = :clamp_to_edge)
    push!(factory, tex)
end

function gl_render_pipeline!(screen::Screen, pipeline::Makie.Pipeline)
    render_pipeline = screen.render_pipeline
    factory = screen.framebuffer_factory

    empty!(render_pipeline)
    unsafe_empty!(factory)

    # Resolve pipeline
    buffers, connection2idx = Makie.generate_buffers(pipeline)

    # Add required buffers
    for format in buffers
        create_buffer!(factory, format)
    end

    # TODO: Well looks like we do need to bundle?
    #       Otherwise resolving stage -> Postprocessor is going to be hard/annoying
    #       Well, or I just split them up I guess
    for stage in pipeline.stages
        inputs = Dict{Symbol, Texture}(map(collect(keys(stage.inputs))) do key
            connection = stage.input_connections[stage.inputs[key]]
            return key => get_buffer(factory, connection2idx[connection])
        end)

        N = length(stage.output_connections)
        if N == 0
            framebuffer = nothing
        else
            idx2name = Dict([idx => k for (k, idx) in stage.outputs])
            outputs = [connection2idx[stage.output_connections[i]] => idx2name[i] for i in 1:N]
            try
                framebuffer = generate_framebuffer(factory,outputs...)
            catch e
                rethrow(e)
            end
        end

        # TODO: hmm...
        pass = if stage.name == :ZSort
            SortPlots()
        elseif stage.name == :Render
            # TODO:
            buffer_idx = connection2idx[stage.output_connections[stage.outputs[:objectid]]]
            factory.buffer_key2idx[:objectid] = buffer_idx
            RenderPlots(screen, framebuffer, inputs, N == 2 ? (:FXAA) : (:SSAO))
        elseif stage.name == :TransparentRender
            RenderPlots(screen, framebuffer, inputs, :OIT)
        elseif stage.name == :Display
            # TODO: hacky
            prev = last(render_pipeline)
            framebuffer = prev.framebuffer
            # TODO: Technically need to find connection from prev to this stage
            #       that ends up in :color
            # Assuming that connection attached to a :color output:
            attachment = get_attachment(framebuffer, :color)
            buffer_idx = stage.inputs[:color]
            factory.buffer_key2idx[:color_output] = buffer_idx
            # idx = stage.input_connections[stage.inputs[:color]].inputs
            # attachment = framebuffer.attachments[idx]
            # factory.buffer_key2idx[:color_output] = idx
            BlitToScreen(framebuffer, attachment)
        elseif stage.name in [:SSAO1, :SSAO2, :FXAA1, :FXAA2, :OIT]
            RenderPass{stage.name}(screen, framebuffer, inputs)
        end

        # I guess stage should also have extra information for settings? Or should
        # that be in scene.theme?
        # Maybe just leave it there for now
        push!(render_pipeline, pass)
    end

    return render_pipeline
end
