using .GLAbstraction: StandardPrerender

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
    get!(data, :shading, FastShading)
    @gen_defaults! data begin
        intensity = nothing => Texture
        color_map = nothing => Texture
        color_norm = nothing
        transparency = false
        fxaa = false
        px_per_unit = 1.0f0
    end
    return RenderObject(screen.glscreen, data)
end

function default_shader(screen, robj, ::Heatmap, param)
    shader = GLVisualizeShader(
        screen,
        "fragment_output.frag", "heatmap.vert", "heatmap.frag",
        view = Dict(param...)
    )
    return shader
end

function draw_volume(screen, data::Dict)
    geom = Rect3f(Vec3f(0), Vec3f(1))
    to_opengl_mesh!(screen.glscreen, data, const_lift(GeometryBasics.triangle_mesh, geom))
    shading = get!(data, :shading, FastShading)
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
    end
    return RenderObject(screen.glscreen, data)
end

function default_setup!(screen, robj, ::Volume, name, param)
    shading = get!(robj.uniforms, :shading, FastShading)
    shader = GLVisualizeShader(
        screen,
        "volume.vert",
        "fragment_output.frag", "lighting.frag", "volume.frag",
        view = Dict(
            "shading" => light_calc(shading),
            "MAX_LIGHTS" => "#define MAX_LIGHTS $(screen.config.max_lights)",
            "MAX_LIGHT_PARAMETERS" => "#define MAX_LIGHT_PARAMETERS $(screen.config.max_light_parameters)",
            "ENABLE_DEPTH" => Bool(robj.uniforms[:enable_depth]) ? "#define ENABLE_DEPTH" : "",
            param...
        )
    )
    prerender = VolumePrerender(get_default_prerender(robj, name))
    # TODO: make a struct for this to clean it up?
    postrender = () -> glDisable(GL_CULL_FACE)

    add_instructions!(robj, name, shader, pre = prerender, post = postrender)
    return
end
@specialize
