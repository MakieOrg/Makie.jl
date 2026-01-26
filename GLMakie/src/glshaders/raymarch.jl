# Note:

function assemble_raymarched_robj!(data, screen::Screen, attr, args, input2glname)
    # if args.scaled_color isa AbstractArray{<:Real}
    #     data[:color_map] = args.alpha_colormap
    #     data[:color_norm] = args.scaled_colorrange
    # end

    shading = pop!(data, :shading)

    # add_color_attributes!(
    #     screen, attr, data,
    #     args.scaled_color, args.alpha_colormap, args.scaled_colorrange
    # )

    @gen_defaults! data begin
        vertices = nothing => GLBuffer
        faces = nothing => indexbuffer

        id_buffer = nothing => Texture
        data_buffer = nothing => Texture
        brick_colors = nothing => Texture

        transparency = false
        overdraw = false
        px_per_unit = 1f0

        shader = GLVisualizeShader(
            screen,
            "volume.vert",
            "fragment_output.frag", "lighting.frag", "raymarch.frag",
            view = Dict(
                "shading" => light_calc(shading),
                "MAX_LIGHTS" => "#define MAX_LIGHTS $(screen.config.max_lights)",
                "MAX_LIGHT_PARAMETERS" => "#define MAX_LIGHT_PARAMETERS $(screen.config.max_light_parameters)",
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency)),
                "operation_enum" => Makie.SDF.Commands.glsl_enum(),
            )
        )
        prerender = VolumePrerender(data[:transparency], data[:overdraw])
        postrender = () -> glDisable(GL_CULL_FACE)
    end

    return assemble_shader(data)
end

function register_opengl_mesh!(attr, source::Union{Symbol, Makie.ComputePipeline.Computed})
    map!(attr, source, [:vertices, :faces]) do mesh
        ps = GeometryBasics.decompose(Point3f, mesh)
        fs = GeometryBasics.decompose(GLTriangleFace, mesh)
        return ps, fs
    end
end

function draw_atomic(screen::Screen, scene::Scene, plot::SDFScatter)
    attr = plot.attributes

    Makie.add_computation!(attr, Val(:uniform_clip_planes), :model, :model)
    Makie.register_world_normalmatrix!(attr, :model)
    Makie.register_view_normalmatrix!(attr, :model)
    register_opengl_mesh!(attr, :boundingbox)

    # map!(attr, [:marker, :mode, :N_elements], :marker_mode) do marker, mode, N
    #     # marker probably won't have that many options
    #     # mode is just additive or subtractive, so one bit
    #     return fill(0x00, N)
    # end

    # TODO: reuse in clip planes
    map!(attr, :model, :modelinv) do model
        return Mat4f(inv(model))
    end

    inputs = Symbol[
    ]
    uniforms = Symbol[
        # :marker_mode, :positions_transformed_f32c, :markersize, :rotation, :smudge_range,
        # :alpha_colormap, :scaled_colorrange, :scaled_color,
        # :lowclip_color, :highclip_color, :nan_color,
        :id_buffer, :data_buffer,

        :diffuse, :specular, :shininess, :backlight,
        :vertices, :faces, :model, :modelinv,
    ]

    input2glname = Dict{Symbol, Symbol}(
        # :positions_transformed_f32c => :position,
        # :scaled_color => :color,
        # :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :uniform_num_clip_planes => :_num_clip_planes
    )

    robj = register_robj!(assemble_raymarched_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end