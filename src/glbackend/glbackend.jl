using ModernGL, GLFW, FixedPointNumbers

include("GLAbstraction/GLAbstraction.jl")
using .GLAbstraction

const atlas_texture_cache = Dict{GLFW.Window, Tuple{Texture{Float16, 2}, Function}}()

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
                anisotropic = 16f0,
        )
        # update the texture, whenever a new font is added to the atlas
        function callback(distance_field, rectangle)
            ctx = tex.context
            if GLAbstraction.context_alive(ctx)
                prev_ctx = GLAbstraction.current_context()
                GLAbstraction.switch_context!(ctx)
                tex[rectangle] = distance_field
                GLAbstraction.switch_context!(prev_ctx)
            end
        end
        AbstractPlotting.font_render_callback!(callback)
        return (tex, callback)
    end
    tex
end


function Base.display(x::OpenGLBackend, scene::Scene)
    display(global_gl_screen(), scene)
end

include("GLVisualize/GLVisualize.jl")
using .GLVisualize

include("glwindow.jl")
include("screen.jl")
include("rendering.jl")
include("events.jl")
include("drawing_primitives.jl")
