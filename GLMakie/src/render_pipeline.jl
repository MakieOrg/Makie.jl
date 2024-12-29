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
    empty!(factory.children)

    # reuse buffers that match formats (and make sure that factory.buffers
    # follows the order of formats)
    buffers = copy(factory.buffers)
    empty!(factory.buffers)
    for format in formats
        T = format_to_type(format)
        found = false
        # for (i, buffer) in enumerate(buffers)
        #     if T == eltype(buffer) && (get(format.extras, :minfilter, :nearest) == buffer.parameters.minfilter)
        #         found = true
        #         push!(factory.buffers, popat!(buffers, i))
        #         break
        #     end
        # end

        if !found
            if haskey(format.extras, :minfilter)
                interp = format.extras[:minfilter]
                if !(eltype(T) == N0f8 || eltype(T) <: AbstractFloat) && (interp == :linear)
                    error("Cannot use :linear interpolation with non float types.")
                end
            else
                interp = :nearest
            end
            tex = Texture(T, size(factory), minfilter = interp, x_repeat = :clamp_to_edge)
            push!(factory.buffers, tex)
        end
    end

    # Always rebuild this though, since we don't know which buffers are the
    # final output buffers
    fb = GLFramebuffer(size(factory))
    depth_buffer = Texture(
        Ptr{GLAbstraction.DepthStencil_24_8}(C_NULL), size(factory),
        minfilter = :nearest, x_repeat = :clamp_to_edge,
        internalformat = GL_DEPTH24_STENCIL8,
        format = GL_DEPTH_STENCIL
    )
    attach_depthstencilbuffer(fb, :depth_stencil, depth_buffer)
    # attach_depthstencilbuffer(fb, :depth_stencil, get_buffer(factory.fb, :depth_stencil))
    factory.fb = fb

    return factory
end


function gl_render_pipeline!(screen::Screen, pipeline::Makie.Pipeline)
    pipeline.stages[end].name === :Display || error("Pipeline must end with a Display stage")
    previous_pipeline = screen.render_pipeline

    # Exit early if the pipeline is already up to date
    previous_pipeline.parent == pipeline && return

    # TODO: check if pipeline is different from the last one before replacing it
    factory = screen.framebuffer_factory

    # Maybe safer to wait on rendertask to finish and replace the GLRenderPipeline
    # with an empty one while we mess with it?
    wait(screen)
    screen.render_pipeline = GLRenderPipeline()

    # Resolve pipeline
    buffers, connection2idx = Makie.generate_buffers(pipeline)

    # Add required buffers
    reset!(factory, buffers)

    # Add back output color and objectid attachments
    buffer_idx = connection2idx[Makie.get_input_connection(pipeline.stages[end], :color)]
    attach_colorbuffer(factory.fb, :color, get_buffer(factory, buffer_idx))
    buffer_idx = connection2idx[Makie.get_input_connection(pipeline.stages[end], :objectid)]
    attach_colorbuffer(factory.fb, :objectid, get_buffer(factory, buffer_idx))


    render_pipeline = AbstractRenderStep[]
    for stage in pipeline.stages
        inputs = Dict{Symbol, Any}(map(collect(keys(stage.inputs))) do key
            connection = stage.input_connections[stage.inputs[key]]
            return Symbol(key, :_buffer) => get_buffer(factory, connection2idx[connection])
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

        # can we reconstruct? (reconstruct should update framebuffer, and replace
        # inputs if necessary, i.e. handle differences in connections and attributes)
        idx = findfirst(previous_pipeline.parent.stages) do old
            (old.name == stage.name) &&
            (old.inputs == stage.inputs) && (old.outputs == stage.outputs) &&
            (old.input_formats == stage.input_formats) &&
            (old.output_formats == stage.output_formats)
        end

        if idx === nothing
            pass = construct(Val(stage.name), screen, framebuffer, inputs, stage)
        else
            pass = reconstruct(previous_pipeline.steps[idx], screen, framebuffer, inputs, stage)
        end

        # I guess stage should also have extra information for settings? Or should
        # that be in scene.theme?
        # Maybe just leave it there for now
        push!(render_pipeline, pass)
    end

    screen.render_pipeline = GLRenderPipeline(pipeline, render_pipeline)
    screen.requires_update = true

    return
end