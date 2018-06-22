#the idea of a pipeline together with renderpasses is that one can jus throw in a scene
#and the render functions take care of what renderables get drawn by what passes
struct Pipeline{Name}
    name::Symbol
    passes::Vector{RenderPass}
    context::AbstractContext
end
Pipeline(name::Symbol, rps::Vector{<:RenderPass}, context=current_context()) = Pipeline{name}(name, rps, context)

function render(pipe::Pipeline, args...)
    setup(pipe)
    for pass in pipe.passes
        setup(pass)
        pass(args...)
    end
    stop(pipe.passes[end])
end

function free!(pipe::Pipeline)
    if !is_current_context(pipe.context)
        return pipe
    end
    for pass in pipe.passes
        free!(pass)
    end
    return
end
#overload!
setup(pipe::Pipeline) = return
stop(pipe::Pipeline) = stop(pipe.passes[end])

resize_targets!(pipe::Pipeline, w, h) = resize_targets!(pipe, (w, h))
###WIP shadercleanup
function resize_targets!(pipe::Pipeline, wh)
    for pass in pipe.passes
        resize_target!(pass, wh)
    end
end
