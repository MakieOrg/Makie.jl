
using ComputePipeline

add_computation!(attr::ComputeGraph, scene::Scene, symbols::Symbol...) =
    add_computation!(attr, scene::Scene, Val.(symbols)...)

add_computation!(attr::ComputeGraph, symbols::Symbol...) = add_computation!(attr, Val.(symbols)...)

function add_computation!(attr, scene, ::Val{:scene_origin})
    add_input!(attr, :viewport, scene.viewport[])
    on(viewport -> Makie.update!(attr; viewport=viewport), scene.viewport) # TODO: This doesn't update immediately?
    register_computation!(attr, [:viewport], [:scene_origin]) do (viewport,), changed, output
        return (Vec2f(origin(viewport[])),)
    end
end

function add_computation!(attr, ::Val{:gl_miter_limit})
    register_computation!(attr, [:miter_limit], [:gl_miter_limit]) do (miter,), changed, output
        return (Float32(cos(pi - miter[])),)
    end
end

function add_computation!(attr, ::Val{:gl_pattern}, ::Val{:gl_pattern_length})
    # linestyle/pattern handling
    register_computation!(
        attr, [:linestyle], [:gl_pattern, :gl_pattern_length]
    ) do (linestyle,), changed, cached
        if isnothing(linestyle[])
            sdf = fill(Float16(-1.0), 100) # compat for switching from linestyle to solid/nothing
            len = 1.0f0 # should be irrelevant, compat for strictly solid lines
        else
            sdf = Makie.linestyle_to_sdf(linestyle[])
            len = Float32(last(linestyle[]) - first(linestyle[]))
        end
        return (sdf, len)
    end
end
