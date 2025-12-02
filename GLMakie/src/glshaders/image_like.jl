using .GLAbstraction: StandardPrerender

struct VolumePrerender
    sp::StandardPrerender
end
VolumePrerender(a, b) = VolumePrerender(StandardPrerender(a, b))

function (x::VolumePrerender)()
    x.sp()
    glEnable(GL_CULL_FACE)
    return glCullFace(GL_FRONT)
end

@nospecialize
"""
A matrix of Intensities will result in a contourf kind of plot
"""
function draw_heatmap(screen, data::Dict)
    primitive = triangle_mesh(Rect2(0.0f0, 0.0f0, 1.0f0, 1.0f0))
    to_opengl_mesh!(screen.glscreen, data, primitive)
    pop!(data, :shading, FastShading)
    @gen_defaults! data begin
        intensity = nothing => Texture
        color_map = nothing => Texture
        color_norm = nothing
        transparency = false
        shader = GLVisualizeShader(
            screen,
            "fragment_output.frag", "heatmap.vert", "heatmap.frag",
            view = Dict(
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
        fxaa = false
        px_per_unit = 1.0f0
    end
    return assemble_shader(data)
end

function draw_volume(screen, data::Dict)
    geom = Rect3f(Vec3f(0), Vec3f(1))
    to_opengl_mesh!(screen.glscreen, data, const_lift(GeometryBasics.triangle_mesh, geom))
    shading = pop!(data, :shading, FastShading)
    pop!(data, :backlight, 0.0f0) # We overwrite this
    @gen_defaults! data begin
        volumedata = Array{Float32, 3}(undef, 0, 0, 0) => Texture
        model = Mat4f(I)
        modelinv = const_lift(inv, model)
        color_map = nothing => Texture
        color_norm = nothing
        color = nothing => Texture

        algorithm = MaximumIntensityProjection
        absorption = 1.0f0
        isovalue = 0.5f0
        isorange = 0.01f0
        backlight = 1.0f0
        enable_depth = true
        transparency = false
        px_per_unit = 1.0f0
        shader = GLVisualizeShader(
            screen,
            "volume.vert",
            "fragment_output.frag", "lighting.frag", "volume.frag",
            view = Dict(
                "shading" => light_calc(shading),
                "MAX_LIGHTS" => "#define MAX_LIGHTS $(screen.config.max_lights)",
                "MAX_LIGHT_PARAMETERS" => "#define MAX_LIGHT_PARAMETERS $(screen.config.max_light_parameters)",
                "ENABLE_DEPTH" => to_value(enable_depth) ? "#define ENABLE_DEPTH" : "",
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
        prerender = VolumePrerender(data[:transparency], data[:overdraw])
        postrender = () -> glDisable(GL_CULL_FACE)
    end
    return assemble_shader(data)
end
@specialize
