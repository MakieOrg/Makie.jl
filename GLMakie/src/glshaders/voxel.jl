@nospecialize
function draw_voxels(screen, main::VolumeTypes, data::Dict)
    geom = Rect2f(Point2f(0), Vec2f(1.0))
    to_opengl_mesh!(screen.glscreen, data, const_lift(GeometryBasics.triangle_mesh, geom))
    @gen_defaults! data begin
        voxel_id = main => Texture
        gap = 0.0f0
        instances = const_lift(gap, voxel_id) do gap, chunk
            N = sum(size(chunk))
            ifelse(gap > 0.01, 2 * N, N + 3)
        end
        model = Mat4f(I)
        backlight = 0.0f0
        color = nothing => Texture
        color_map = nothing => Texture
        uv_transform = nothing => Texture
        px_per_unit = 1.0f0
    end

    return RenderObject(screen.glscreen, data)
end

function default_shader(screen, robj, plot::Voxels, param)
    shading = get!(robj.uniforms, :shading, NoShading)::Makie.ShadingAlgorithm
    debug = to_value(get(plot.attributes, :debug, ""))
    shader = GLVisualizeShader(
        screen,
        "voxel.vert",
        "fragment_output.frag", "voxel.frag", "lighting.frag",
        view = Dict(
            "shading" => light_calc(shading),
            "MAX_LIGHTS" => "#define MAX_LIGHTS $(screen.config.max_lights)",
            "MAX_LIGHT_PARAMETERS" => "#define MAX_LIGHT_PARAMETERS $(screen.config.max_light_parameters)",
            "DEBUG_FLAG_DEFINE" => debug,
            param...
        )
    )
    return shader
end

@specialize
