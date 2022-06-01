# TODO
# find a better way to handle this
# enable_SSAO and FXAA adjust the rendering pipeline and are currently per screen
const enable_SSAO = Ref(false)
const enable_FXAA = Ref(true)
# This adjusts a factor in the rendering shaders for order independent
# transparency. This should be the same for all of them (within one rendering
# pipeline) otherwise depth "order" will be broken.
const transparency_weight_scale = Ref(1000f0)

try
    using GLFW
catch e
    @warn("""
        OpenGL/GLFW wasn't loaded correctly or couldn't be initialized.
        This likely means, you're on a headless server without having OpenGL support setup correctly.
        Have a look at the troubleshooting section in the readme:
        https://github.com/JuliaPlots/Makie.jl/tree/master/GLMakie#troubleshooting-opengl.
    """)
    rethrow(e)
end

include("GLAbstraction/GLAbstraction.jl")

using .GLAbstraction

const atlas_texture_cache = Dict{Any, Tuple{Texture{Float16, 2}, Function}}()

function get_texture!(atlas)
    # clean up dead context!
    filter!(atlas_texture_cache) do (ctx, tex_func)
        if GLAbstraction.context_alive(ctx)
            return true
        else
            Makie.remove_font_render_callback!(tex_func[2])
            return false
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
                mipmap = true
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
        Makie.font_render_callback!(callback)
        return (tex, callback)
    end
    return tex
end

include("glshaders/visualize_interface.jl")
include("glshaders/lines.jl")
include("glshaders/image_like.jl")
include("glshaders/mesh.jl")
include("glshaders/particles.jl")
include("glshaders/surface.jl")

include("glwindow.jl")
include("postprocessing.jl")
include("screen.jl")
include("rendering.jl")
include("events.jl")
include("drawing_primitives.jl")
include("display.jl")

Base.@deprecate_binding GLVisualize GLMakie true "The module `GLVisualize` has been removed and integrated into GLMakie, so simply replace all usage of `GLVisualize` with `GLMakie`."
