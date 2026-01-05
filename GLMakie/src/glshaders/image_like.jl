struct VolumePrerender{T}
    pre::T
end

function (x::VolumePrerender)()
    x.pre()
    glEnable(GL_CULL_FACE)
    glCullFace(GL_FRONT)
    return
end

@nospecialize
"""
A matrix of Intensities will result in a contourf kind of plot
"""
function draw_heatmap(screen, data::Dict)
    primitive = triangle_mesh(Rect2(0.0f0, 0.0f0, 1.0f0, 1.0f0))
    to_opengl_mesh!(screen.glscreen, data, primitive)
    @gen_defaults! data begin
        intensity = nothing => Texture
        color_map = nothing => Texture
        color_norm = nothing
        px_per_unit = 1.0f0
    end
    return RenderObject(screen.glscreen, data)
end

function draw_volume(screen, data::Dict)
    geom = Rect3f(Vec3f(0), Vec3f(1))
    to_opengl_mesh!(screen.glscreen, data, const_lift(GeometryBasics.triangle_mesh, geom))
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
        enable_depth = true
        px_per_unit = 1.0f0
    end
    return RenderObject(screen.glscreen, data)
end

@specialize

function default_shader(screen::Screen, @nospecialize(::RenderObject), ::Heatmap, view::Dict{String, String})
    shader = GLVisualizeShader(
        screen,
        "fragment_output.frag", "heatmap.vert", "heatmap.frag",
        view = view
    )
    return shader
end

get_prerender(plot::Volume, name::Symbol) = VolumePrerender(get_default_prerender(plot, name))
get_postrender(::Volume, ::Symbol) = () -> glDisable(GL_CULL_FACE)

function default_shader(screen::Screen, @nospecialize(robj::RenderObject), plot::Volume, view::Dict{String, String})
    shading = Makie.get_shading_mode(plot)
    view["shading"] = light_calc(shading)::String
    view["MAX_LIGHTS"] = "#define MAX_LIGHTS $(screen.config.max_lights)"
    view["MAX_LIGHT_PARAMETERS"] = "#define MAX_LIGHT_PARAMETERS $(screen.config.max_light_parameters)"
    view["ENABLE_DEPTH"] = Bool(robj.uniforms[:enable_depth]) ? "#define ENABLE_DEPTH" : ""

    shader = GLVisualizeShader(
        screen,
        "volume.vert",
        "fragment_output.frag", "lighting.frag", "volume.frag",
        view = view
    )
    return shader
end
