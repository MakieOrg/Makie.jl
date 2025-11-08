"""
    initialize_attachments!(manager::FramebufferManager, formats)

Populates a `FramebufferManager` with buffers corresponding to the given formats.
These are then used to create Framebuffers.
"""
function initialize_attachments!(manager::FramebufferManager, formats::Vector{Makie.BufferFormat})
    # Implies `empty!(manager)` has not been called
    @assert isempty(manager.buffers) "Cannot initialize FramebufferManager that has already been initialized."

    to_internalformat(::Type{<:Makie.BFT.Depth{16}}) = GL_DEPTH_COMPONENT16
    to_internalformat(::Type{<:Makie.BFT.Depth{24}}) = GL_DEPTH_COMPONENT24
    to_internalformat(::Type{<:Makie.BFT.Depth{32}}) = GL_DEPTH_COMPONENT32F

    # function barrier for types?
    function get_buffer!(context, T, format)
        is_depth_buffer = Makie.is_depth_format(format)
        is_stencil_buffer = Makie.is_stencil_format(format)
        is_depth_stencil_buffer = Makie.is_depth_stencil_format(format)

        if is_depth_buffer || is_stencil_buffer || is_depth_stencil_buffer
            if is_depth_stencil_buffer
                # TODO: allow 32-8 depth stencil
                T === Makie.BFT.Depth24Stencil8 || error("$T not supported as a depth stencil buffer type.")
                return Texture(
                    context, Ptr{GLAbstraction.DepthStencil_24_8}(C_NULL), size(manager),
                    minfilter = :nearest, x_repeat = :clamp_to_edge,
                    internalformat = GL_DEPTH24_STENCIL8,
                    format = GL_DEPTH_STENCIL, samples = format.samples
                )
            elseif is_depth_buffer
                T === Nothing && error("Buffer element type is invalid.")
                return Texture(
                    context, Ptr{Float32}(C_NULL), size(manager),
                    minfilter = :nearest, x_repeat = :clamp_to_edge,
                    format = GL_DEPTH_COMPONENT, internalformat = to_internalformat(T),
                    samples = format.samples
                )
            else
                # untested
                T === Nothing && error("Buffer element type is invalid.")
                return Texture(
                    context, T, size(manager),
                    minfilter = :nearest, x_repeat = :clamp_to_edge,
                    format = GL_STENCIL, samples = format.samples
                )
            end
        end

        is_float_format = eltype(T) == N0f8 || eltype(T) <: AbstractFloat
        default_filter = ifelse(is_float_format, :linear, :nearest)
        minfilter = ifelse(format.minfilter === :any, ifelse(format.mipmap, :linear_mipmap_linear, default_filter), format.minfilter)
        magfilter = ifelse(format.magfilter === :any, default_filter, format.magfilter)

        if !is_float_format && (format.mipmap || minfilter != :nearest || magfilter != :nearest)
            error("Cannot use :linear interpolation or mipmaps with non float buffers.")
        end

        # TODO: Figure out what we need to do for mipmaps. Do we need to call
        #       glGenerateMipmap before every stage using the buffer? Should
        #       Stages do that? Do we need anything extra for setup?
        format.mipmap && error("Mipmaps not yet implemented for Pipeline buffers")

        return Texture(
            context, T, size(manager), minfilter = minfilter, magfilter = magfilter,
            x_repeat = format.repeat[1], y_repeat = format.repeat[2],
            samples = format.samples
        )
        1
    end

    # Add buffers in the order of `formats`
    for format in formats
        tex = get_buffer!(manager.context, Makie.format_to_type(format), format)
        push!(manager.buffers, tex)
    end

    return manager
end

"""
    gl_render_pipeline!(screen, pipeline::Makie.RenderPipeline)

Constructs a new `GLRenderPipeline` from a `Makie.RenderPipeline` and adds it
to the given `screen`. If a `GLRenderPipeline` already exists, it is destroyed
and replaced. This will also reset the `FramebufferManager`.
"""
function gl_render_pipeline!(screen::Screen, pipeline::Makie.RenderPipeline)
    pipeline.stages[end].name === :Display || error("RenderPipeline must end with a Display stage")

    # Exit early if the pipeline is already up to date
    lowered_pipeline = Makie.LoweredRenderPipeline(pipeline)
    screen.render_pipeline == pipeline && return

    return gl_render_pipeline!(screen, lowered_pipeline)
end

function gl_render_pipeline!(screen::Screen, pipeline::Makie.LoweredRenderPipeline)
    # Reset GL renderpipeline
    ShaderAbstractions.switch_context!(screen.glscreen)
    manager = screen.framebuffer_manager
    previous_pipeline = screen.render_pipeline
    screen.render_pipeline = GLRenderPipeline()

    # Generate all the necessary attachments in the order given above so the
    # correct GLFramebuffers can be generated
    destroy!(manager)
    initialize_attachments!(manager, pipeline.formats)

    # verify that last step is display
    final_stage = pipeline.stages[end]
    if !(final_stage.name === :Display && first.(final_stage.inputs) == [:depth, :color, :objectid])
        error("The final stage must be a Display stage with inputs (:depth, :color, :objectid). $final_stage")
    end

    # Constructing a RenderStep can be somewhat costly, so we want to reuse them
    # if possible. Steps that aren't reused and thus need to be deleted are
    # tracked here:
    needs_cleanup = collect(eachindex(previous_pipeline.steps))
    render_pipeline = GLRenderStage[]

    for stage in pipeline.stages
        # If the RenderStep already exists, update and reuse it, otherwise create it
        idx = findfirst(==(stage), previous_pipeline.parent.stages)

        if idx === nothing
            pass = construct(Val(stage.name), screen, stage)
        else
            pass = reconstruct(previous_pipeline.steps[idx], screen, stage)
            filter!(!=(idx), needs_cleanup)
        end

        push!(render_pipeline, pass)
    end

    # Cleanup any old RenderStep that has not been reused, passing along which
    # buffers must be preserved.
    foreach(i -> destroy!(previous_pipeline.steps[i]), needs_cleanup)

    screen.render_pipeline = GLRenderPipeline(pipeline, render_pipeline)

    return
end

function construct(name::Val, screen, stage)
    manager = screen.framebuffer_manager
    inputs = collect_buffers(manager, stage.inputs)
    framebuffer = generate_framebuffer(manager, stage.outputs)
    return construct(name, screen, framebuffer, inputs, stage)
end

function reconstruct(name::Val, screen, stage)
    manager = screen.framebuffer_manager
    inputs = collect_buffers(manager, stage.inputs)
    framebuffer = generate_framebuffer(manager, stage.outputs)
    return reconstruct(name, screen, framebuffer, inputs, stage)
end

"""
    collect_buffer(manager::FramebufferManager, sources)

This function is used to collect all the buffers listed in the `stage.inputs` or
`stage.outputs` of a `stage::Makie.LoweredStage`. They are returned in a
`Dict{Symbol, Any}` mapping the input/output name to the respective buffer.

To get an individual buffer `get_buffer(manager, stages.inputs[1][1])` can be used.
"""
function collect_buffers(manager::FramebufferManager, sources::Vector{Pair{Symbol, Int64}})
    d = Dict{Symbol, Any}()
    for (name, idx) in sources
        d[Symbol(name, :_buffer)] = get_buffer(manager, idx)
    end
    return d
end
