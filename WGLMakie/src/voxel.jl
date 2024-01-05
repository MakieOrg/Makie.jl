function create_shader(scene::Scene, plot::Makie.Voxel)

    uniform_dict = Dict{Symbol, Any}(
        :voxel_id => Sampler(plot.converted[end], minfilter = :nearest),
        # for plane sorting
        :depthsorting => plot.depthsorting,
        :eyeposition => Vec3f(1),
        :view_direction => camera(scene).view_direction,
        # lighting
        :diffuse => lift(x -> convert_attribute(x, Key{:diffuse}()), plot, plot.diffuse),
        :specular => lift(x -> convert_attribute(x, Key{:specular}()), plot, plot.specular),
        :shininess => lift(x -> convert_attribute(x, Key{:shininess}()), plot, plot.shininess),
        :depth_shift => get(plot, :depth_shift, Observable(0.0f0)),
        :light_direction => Vec3f(1),
        :light_color => Vec3f(1),
        :ambient => Vec3f(1),
        # picking
        :picking => false,
        :object_id => UInt32(0),
        # other
        :normalmatrix => map(plot.model) do m
            # should be fine to ignore placement matrix here because
            # translation is ignored and scale shouldn't matter
            i = Vec(1, 2, 3)
            return transpose(inv(m[i, i]))
        end,
        :shading => to_value(get(plot, :shading, NoShading)) != NoShading,
    )

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
        return model *
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
    N_instances = sum(size(plot.converted[end][])) + 3
    dummy_data = [0f0 for _ in 1:N_instances]

    instance = uv_mesh(Rect2(0f0, 0f0, 1f0, 1f0))

    return InstancedProgram(WebGL(), lasset("voxel.vert"), lasset("voxel.frag"),
                        instance, VertexArray(dummy = dummy_data), uniform_dict)
end
