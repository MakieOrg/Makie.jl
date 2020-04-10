using GLFW

include("GLAbstraction/GLAbstraction.jl")

using .GLAbstraction

const atlas_texture_cache = Dict{Any, Tuple{Texture{Float16, 2}, Function}}()

function get_texture!(atlas)
    # clean up dead context!
    filter!(atlas_texture_cache) do (ctx, tex_func)
        if GLAbstraction.context_alive(ctx)
            true
        else
            AbstractPlotting.remove_font_render_callback!(tex_func[2])
            false
        end
    end
    tex, func = get!(atlas_texture_cache, GLAbstraction.current_context()) do
        tex = Texture(
                atlas.data,
                minfilter = :linear,
                magfilter = :linear,
                # TODO: Consider alternatives to using the builtin anisotropic
                # samplers for signed distance fields; the anisotropic
                # filtering should happen *after* the SDF thresholding, but
                # with the builtin sampler it happens before.
                anisotropic = 16f0,
        )
        # update the texture, whenever a new font is added to the atlas
        function callback(distance_field, rectangle)
            ctx = tex.context
            if GLAbstraction.context_alive(ctx)
                prev_ctx = GLAbstraction.current_context()
                ShaderAbstractions.switch_context!(ctx)
                tex[rectangle] = distance_field
                ShaderAbstractions.switch_context!(prev_ctx)
            end
        end
        AbstractPlotting.font_render_callback!(callback)
        return (tex, callback)
    end
    tex
end

include("GLVisualize/GLVisualize.jl")
using .GLVisualize

include("glwindow.jl")
include("screen.jl")
include("rendering.jl")
include("events.jl")
include("drawing_primitives.jl")

function AbstractPlotting.backend_display(x::GLBackend, scene::Scene)
    screen = global_gl_screen(size(scene), AbstractPlotting.use_display[])
    display_loading_image(screen)
    AbstractPlotting.backend_display(screen, scene)
    return screen
end

"""
    scene2image(scene::Scene)

Buffers the `scene` in an image buffer.
"""
function scene2image(scene::Scene)
    screen = global_gl_screen(size(scene), false)
    AbstractPlotting.backend_display(screen, scene)
    AbstractPlotting.colorbuffer(screen)
end

function AbstractPlotting.backend_show(::GLBackend, io::IO, m::MIME"image/png", scene::Scene)
    img = scene2image(scene)
    FileIO.save(FileIO.Stream(FileIO.format"PNG", io), img)
end

function AbstractPlotting.backend_show(::GLBackend, io::IO, m::MIME"image/jpeg", scene::Scene)
    img = scene2image(scene)
    FileIO.save(FileIO.Stream(FileIO.format"JPEG", io), img)
end
