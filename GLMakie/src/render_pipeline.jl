function create_buffer!(factory::FramebufferFactory, format::Makie.BufferFormat)
    T = format_to_type(format)
    tex = Texture(T, size(factory), minfilter = :linear, x_repeat = :clamp_to_edge)
    # tex = Texture(T, size(factory), minfilter = :nearest, x_repeat = :clamp_to_edge)
    push!(factory, tex)
end

function format_to_type(format::Makie.BufferFormat)
    return format.dims == 1 ? format.type : Vec{format.dims, format.type}
end

function Makie.reset!(factory::FramebufferFactory, formats::Vector{Makie.BufferFormat})
    # empty!(factory.buffer_key2idx)
    empty!(factory.children)

    # reuse buffers that match formats (and make sure that factory.buffers
    # follows the order of formats)
    buffers = copy(factory.buffers)
    empty!(factory.buffers)
    for format in formats
        T = format_to_type(format)
        found = false
        for (i, buffer) in enumerate(buffers)
            if T == eltype(buffer) # TODO: && extra parameters match...
                found = true
                push!(factory.buffers, popat!(buffers, i))
                break
            end
        end

        if !found
            isfloattype = eltype(T) == N0f8 || eltype(T) <: AbstractFloat
            interp = isfloattype ? (:linear) : (:nearest)
            tex = Texture(T, size(factory), minfilter = interp, x_repeat = :clamp_to_edge)
            push!(factory.buffers, tex)
        end
    end

    # Always rebuild this though, since we don't know which buffers are the
    # final output buffers
    fb = GLFramebuffer(size(factory))
    attach_depthstencilbuffer(fb, :depth_stencil, get_buffer(factory.fb, :depth_stencil))
    factory.fb = fb

    return factory
end


function gl_render_pipeline!(screen::Screen, pipeline::Makie.Pipeline)
    # TODO: check if pipeline is different from the last one before replacing it
    render_pipeline = screen.render_pipeline
    factory = screen.framebuffer_factory

    empty!(render_pipeline)

    # Resolve pipeline
    buffers, connection2idx = Makie.generate_buffers(pipeline)

    # Add required buffers
    reset!(factory, buffers)

    first_render = true

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
            if first_render
                attach_colorbuffer(factory.fb, :objectid, get_buffer(framebuffer, :objectid))
                first_render = false
                RenderPlots(screen, framebuffer, inputs, :SSAO)
            else
                RenderPlots(screen, framebuffer, inputs, :FXAA)
            end
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
            attach_colorbuffer(factory.fb, :color, get_buffer(framebuffer, :color))
            BlitToScreen(framebuffer, attachment)
        elseif stage.name in [:SSAO1, :SSAO2, :FXAA1, :FXAA2, :OIT]
            RenderPass{stage.name}(screen, framebuffer, inputs)
        else
            error("Unknown stage $(stage.name)")
        end

        # I guess stage should also have extra information for settings? Or should
        # that be in scene.theme?
        # Maybe just leave it there for now
        push!(render_pipeline, pass)
    end

    return render_pipeline
end
