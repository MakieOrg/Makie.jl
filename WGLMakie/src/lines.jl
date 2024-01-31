# Same as GLMakie, see GLMakie/shaders/lines.jl
# TODO: maybe move to Makie?
dist(a, b) = abs(a-b)
mindist(x, a, b) = min(dist(a, x), dist(b, x))
function gappy(x, ps)
    n = length(ps)
    x <= first(ps) && return first(ps) - x
    for j=1:(n-1)
        p0 = ps[j]
        p1 = ps[min(j+1, n)]
        if p0 <= x && p1 >= x
            return mindist(x, p0, p1) * (isodd(j) ? 1 : -1)
        end
    end
    return last(ps) - x
end
function ticks(points, resolution)
    scaled = ((resolution + 1) / resolution) .* points
    r = range(first(scaled), stop=last(scaled), length=resolution+1)[1:end-1]
    return Float16[-gappy(x, scaled) for x = r]
end

function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    Makie.@converted_attribute plot (linewidth, linestyle)

    uniforms = Dict(
        :model => plot.model,
        :depth_shift => plot.depth_shift,
        :picking => false
    )
    if isnothing(to_value(linestyle))
        uniforms[:pattern] = false
        uniforms[:pattern_length] = 1f0
    else
        # TODO: pixel per unit
        pattern = map((ls, lw) -> lw .* ls, plot, linestyle, linewidth)
        uniforms[:pattern] = Sampler(map(pt -> ticks(pt, 100), pattern), x_repeat = :repeat)
        uniforms[:pattern_length] = map(pt -> Float32(last(pt) - first(pt)), pattern)
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

    points_transformed = lift(plot, transform_func_obs(plot), plot[1], plot.space) do tf, ps, space
        output = apply_transform(tf, ps, space)
        # TODO: Do this in javascript?
        if !isempty(output)
            new_output = similar(output, length(output) + 2)
            new_output[1] = output[1]
            @views copyto!(new_output[2:end-1], output)
            new_output[end] = output[end]
            return new_output
            # pushfirst!(output, output[1])
            # push!(output, output[end])
            # @info output
            # return eltype(output)[first(output); output; last(output)]
        end
        return output
    end
    positions = lift(serialize_buffer_attribute, plot, points_transformed)
    attributes = Dict{Symbol, Any}(:linepoint => positions)

    # TODO: in Javascript
    if plot isa Lines && to_value(linestyle) isa Vector
        cam = Makie.parent_scene(plot).camera
        pvm = lift(*, plot, cam.projectionview, uniforms[:model])
        attributes[:lastlen] = map(plot, points_transformed, pvm, cam.resolution) do ps, pvm, res
            # clip -> pixel, but we can skip offset
            scale = Vec2f(0.5 * res[1], 0.5 * res[2])
            # Initial position
            clip = pvm * to_ndim(Point4f, to_ndim(Point3f, ps[1], 0f0), 1f0)
            prev = scale .* Point2f(clip) ./ clip[4]

            # calculate cumulative pixel scale length
            output = Vector{Float32}(undef, length(ps))
            output[1] = 0f0
            for i in 2:length(ps)
                clip = pvm * to_ndim(Point4f, to_ndim(Point3f, ps[i], 0f0), 1f0)
                current = scale .* Point2f(clip) ./ clip[4]
                output[i] = output[i-1] + norm(current - prev)
                prev = current
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
            attributes[name] = lift(plot, attr) do vals
                # TODO: in js?
                # padded = isempty(vals) ? vals : eltype(vals)[first(vals); vals; last(vals)]
                if !isempty(vals)
                    new_output = similar(vals, length(vals) + 2)
                    new_output[1] = vals[1]
                    @views copyto!(new_output[2:end-1], vals)
                    new_output[end] = vals[end]
                    return serialize_buffer_attribute(new_output)
                end
                serialize_buffer_attribute(vals)
            end
        end
    end

    # @info typeof(plot)
    # @info attributes

    attr = Dict(
        :name => string(Makie.plotkey(plot)) * "-" * string(objectid(plot)),
        :visible => plot.visible,
        :uuid => js_uuid(plot),
        :plot_type => plot isa LineSegments ? "linesegments" : "lines",
        :cam_space => plot.space[],
        :uniforms => serialize_uniforms(uniforms),
        :uniform_updater => uniform_updater(plot, uniforms),
        :attributes => attributes
    )
    return attr
end
