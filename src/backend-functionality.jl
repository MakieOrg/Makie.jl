
using ComputePipeline

add_computation!(attr::ComputeGraph, scene::Scene, symbols::Symbol...) =
    add_computation!(attr, scene::Scene, Val.(symbols)...)

add_computation!(attr::ComputeGraph, symbols::Symbol...) = add_computation!(attr, Val.(symbols)...)

function add_computation!(attr, scene, ::Val{:scene_origin})
    add_input!(attr, :viewport, scene.viewport[])
    on(viewport -> Makie.update!(attr; viewport=viewport), scene.viewport) # TODO: This doesn't update immediately?
    register_computation!(attr, [:viewport], [:scene_origin]) do (viewport,), changed, last
        !changed[1] && return nothing
        new_val = Vec2f(origin(viewport[]))
        if !isnothing(last) && last[1][] == new_val
            return nothing
        else
            return (new_val,)
        end
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
        if isnothing(cached)
            tex = ShaderAbstractions.Sampler(sdf, x_repeat = :repeat)
        else
            tex = cached[1][]
            ShaderAbstractions.update!(tex, sdf)
        end
        return (tex, len)
    end
end


function get_lastlen(points::Vector{Point2f}, pvm::Mat4, res::Vec2f, islines::Bool)
    !islines && zeros(Float32, length(points))
    isempty(points) && return Float32[]
    output = Vector{Float32}(undef, length(points))
    # clip -> pixel, but we can skip scene offset
    scale = Vec2f(0.5 * res[1], 0.5 * res[2])
    # position of start of first drawn line segment (TODO: deal with multiple nans at start)
    clip = pvm * to_ndim(Point4f, to_ndim(Point3f, points[2], 0.0f0), 1.0f0)
    prev = scale .* Point2f(clip) ./ clip[4]

    # calculate cumulative pixel scale length
    output[1] = 0.0f0   # duplicated point
    output[2] = 0.0f0   # start of first line segment
    output[end] = 0.0f0 # duplicated end point
    i = 3           # end of first line segment, start of second
    while i < length(points)
        if isfinite(points[i])
            clip = pvm * to_ndim(Point4f, to_ndim(Point3f, points[i], 0.0f0), 1.0f0)
            current = scale .* Point2f(clip) ./ clip[4]
            l = norm(current - prev)
            output[i] = output[i - 1] + l
            prev = current
            i += 1
        else
            # a vertex section (NaN, A, B, C) does not draw, so
            # norm(B - A) should not contribute to line length.
            # (norm(B - A) is 0 for capped lines but not for loops)
            output[i] = 0.0f0
            output[i + 1] = 0.0f0
            if i + 2 <= length(points)
                output[min(end, i + 2)] = 0.0f0
                clip = pvm * to_ndim(Point4f, to_ndim(Point3f, points[i + 2], 0.0f0), 1.0f0)
                prev = scale .* Point2f(clip) ./ clip[4]
            end
            i += 3
        end
    end
    return output
end
