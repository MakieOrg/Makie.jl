function serialize_three(scene::Scene, plot::Makie.Voxels)

    mesh = create_shader(scene, plot)

    mesh[:plot_type] = js_plot_type(plot)
    mesh[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    mesh[:visible] = plot.visible[]
    mesh[:uuid] = js_uuid(plot)
    mesh[:updater] = plot.attributes[:wgl_update_obs][]

    mesh[:overdraw] = plot.overdraw[]
    mesh[:transparency] = plot.transparency[]
    mesh[:space] = plot.space[]

    if haskey(plot, :markerspace)
        mesh[:markerspace] = plot.markerspace[]
        mesh[:cam_space] = plot.markerspace[]
    else
        mesh[:cam_space] = plot.space[]
    end

    mesh[:uniforms][:uniform_clip_planes] = serialize_three(plot.uniform_clip_planes[])
    mesh[:uniforms][:uniform_num_clip_planes] = serialize_three(plot.uniform_num_clip_planes[])

    return mesh
end

function create_shader(scene::Scene, plot::Voxels)
    attr = plot.attributes

    Makie.add_computation!(attr, scene, Val(:voxel_model))

    if haskey(attr, :voxel_colormap)
        map!(attr, :voxel_colormap, [:wgl_colormap, :wgl_uv_transform, :wgl_color]) do colormap
            # colormap is synchronized with the 255 values possible
            return (Sampler(colormap, minfilter = :nearest), false, false)
        end
    elseif haskey(attr, :voxel_color)
        Makie.add_computation!(attr, scene, Val(:voxel_uv_transform))
        register_computation!(
            attr, [:voxel_color, :packed_uv_transform, :interpolate],
            [:wgl_colormap, :wgl_uv_transform, :wgl_color]
        ) do inputs, changed, cached
            # how interpolate?
            color, uvt, interpolate = inputs
            filter = ifelse(interpolate, :linear, :nearest)
            if isnothing(uvt)
                return (false, false, Sampler(color, minfilter = filter)) # color vector
            else
                return (false, Sampler(uvt, minfilter = :nearest), Sampler(color, minfilter = filter)) # texture map
            end
        end
    else

    end

    Makie.register_world_normalmatrix!(attr, :voxel_model)
    Makie.add_computation!(attr, Val(:uniform_clip_planes), :model, :voxel_model)

    # TODO: this is a waste, should just be "make N instances with no data"
    register_computation!(attr, [:chunk_u8, :gap], [:dummy_data]) do (chunk, gap), changed, cached
        N = sum(size(chunk))
        N_instances = ifelse(gap > 0.01, 2 * N, N + 3)
        if isnothing(cached)
            return (zeros(Float32, N_instances),) # or smaller type?
        else
            dummy_data = cached[1]::Vector{Float32}
            if N_instances != length(dummy_data)
                resize!(dummy_data, N_instances)
                dummy_data .= 0
                return (dummy_data,)
            else
                return nothing
            end
        end
    end

    add_primitive_shading!(scene, attr)
    inputs = [
        :dummy_data,

        :depth_shift, :world_normalmatrix,
        :gap, :chunk_u8, :voxel_model,
        :wgl_colormap, :wgl_uv_transform, :wgl_color,

        :diffuse, :specular, :shininess, # :backlight,
        :depthsorting, :primitive_shading,
        :uniform_clip_planes, :uniform_num_clip_planes, :visible,
    ]

    return create_wgl_renderobject(voxel_program, attr, inputs)
end


function voxel_program(attr)
    uniforms = Dict(
        :diffuse => attr.diffuse,
        :specular => attr.specular,
        :shininess => attr.shininess,
        :picking => false,
        :object_id => UInt32(0),
        :depth_shift => attr.depth_shift,
        :eyeposition => Vec3f(1),
        :view_direction => Vec3f(1),
        :depthsorting => attr.depthsorting,
        :world_normalmatrix => attr.world_normalmatrix,
        :shading => attr.primitive_shading,
        :gap => attr.gap,
        :chunk_u8 => attr.chunk_u8,
        :voxel_model => attr.voxel_model,
        :wgl_colormap => attr.wgl_colormap,
        :wgl_uv_transform => attr.wgl_uv_transform,
        :wgl_color => attr.wgl_color,
    )

    # TODO: this is a waste, should just be "make N instances with no data"
    per_instance = Dict(:dummy_data => attr.dummy_data)
    instance = GeometryBasics.mesh(Rect2f(0, 0, 1, 1)) # dont need uv, normals

    data = create_instanced_shader(
        per_instance, instance, uniforms,
        lasset("voxel.vert"), lasset("voxel.frag")
    )

    return data
end
