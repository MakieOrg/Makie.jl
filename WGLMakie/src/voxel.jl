function create_shader(scene::Scene, plot::Makie.Voxels)
    uniform_dict = Dict{Symbol, Any}()
    uniform_dict[:voxel_id] = Sampler(plot.converted[end], minfilter = :nearest)
    # for plane sorting
    uniform_dict[:depthsorting] = plot.depthsorting
    uniform_dict[:eyeposition] = Vec3f(1)
    uniform_dict[:view_direction] = camera(scene).view_direction
    # lighting
    uniform_dict[:diffuse] = lift(x -> convert_attribute(x, Key{:diffuse}()), plot, plot.diffuse)
    uniform_dict[:specular] = lift(x -> convert_attribute(x, Key{:specular}()), plot, plot.specular)
    uniform_dict[:shininess] = lift(x -> convert_attribute(x, Key{:shininess}()), plot, plot.shininess)
    uniform_dict[:depth_shift] = get(plot, :depth_shift, Observable(0.0f0))
    uniform_dict[:light_direction] = Vec3f(1)
    uniform_dict[:light_color] = Vec3f(1)
    uniform_dict[:ambient] = Vec3f(1)
    # picking
    uniform_dict[:picking] = false
    uniform_dict[:object_id] = UInt32(0)
    # other
    uniform_dict[:normalmatrix] = map(plot.model) do m
        # should be fine to ignore placement matrix here because
        # translation is ignored and scale shouldn't matter
        i = Vec(1, 2, 3)
        return Mat3f(transpose(inv(m[i, i])))
    end
    uniform_dict[:shading] = to_value(get(plot, :shading, NoShading)) != NoShading
    uniform_dict[:gap] = lift(x -> convert_attribute(x, Key{:gap}(), Key{:voxels}()), plot.gap)

    # TODO: localized update
    # buffer = Vector{UInt8}(undef, 1)
    on(plot, plot._local_update) do (is, js, ks)
        # required_length = length(is) * length(js) * length(ks)
        # if length(buffer) < required_length
        #     resize!(buffer, required_length)
        # end
        # idx = 1
        # for k in ks, j in js, i in is
        #     buffer[idx] = plot.converted[end].val[i, j, k]
        #     idx += 1
        # end
        # GLAbstraction.texsubimage(tex, buffer, is, js, ks)
        notify(plot.converted[end])
        return
    end

    # adjust model matrix with placement matrix
    uniform_dict[:model] = map(
            plot, plot.converted...,  plot.model
        ) do xs, ys, zs, chunk, model
        mini = minimum.((xs, ys, zs))
        width = maximum.((xs, ys, zs)) .- mini
        # with f32convert applying to 3D plots patch_model should apply to all of this
        return Mat4f(model) *
            Makie.scalematrix(Vec3f(width ./ size(chunk))) *
            Makie.translationmatrix(Vec3f(mini))
    end

    maybe_color_mapping = plot.calculated_colors[]
    uv_map = plot.uvmap
    if maybe_color_mapping isa Makie.ColorMapping
        uniform_dict[:color_map] = Sampler(maybe_color_mapping.colormap, minfilter = :nearest)
        uniform_dict[:uv_map] = false
        uniform_dict[:color] = false
    elseif !isnothing(to_value(uv_map))
        uniform_dict[:color_map] = false
        # WebGL doesn't have sampler1D so we need to pad id -> uv mappings to
        # (id, side) -> uv mappings
        wgl_uv_map = map(plot, uv_map) do uv_map
            if uv_map isa Vector
                new_map = Matrix{Vec4f}(undef, length(uv_map), 6)
                for col in 1:6
                    new_map[:, col] .= uv_map
                end
                return new_map
            else
                return uv_map
            end
        end
        uniform_dict[:uv_map] = Sampler(wgl_uv_map, minfilter = :nearest)
        interp = to_value(plot.interpolate) ? :linear : :nearest
        uniform_dict[:color] = Sampler(maybe_color_mapping, minfilter = interp)
    else
        uniform_dict[:color_map] = false
        uniform_dict[:uv_map] = false
        uniform_dict[:color] = Sampler(maybe_color_mapping, minfilter = :nearest)
    end

    # TODO: this is a waste
    dummy_data = Observable(Float32[])
    onany(plot, plot.gap, plot.converted[end]) do gap, chunk
        N = sum(size(chunk))
        N_instances = ifelse(gap > 0.01, 2 * N, N + 3)
        if N_instances != length(dummy_data[]) # avoid updating unneccesarily
            dummy_data[] = [0f0 for _ in 1:N_instances]
        end
        return
    end
    notify(plot.gap)

    instance = GeometryBasics.mesh(Rect2(0f0, 0f0, 1f0, 1f0))

    return InstancedProgram(WebGL(), lasset("voxel.vert"), lasset("voxel.frag"),
                        instance, VertexArray(dummy = dummy_data), uniform_dict)
end
