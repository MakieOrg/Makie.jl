try
    using GLFW
catch e
    @warn("""
        OpenGL/GLFW wasn't loaded correctly or couldn't be initialized.
        This likely means, you're on a headless server without having OpenGL support setup correctly.
        Have a look at the troubleshooting section in the readme:
        https://github.com/MakieOrg/Makie.jl/tree/master/GLMakie#troubleshooting-opengl.
    """)
    rethrow(e)
end

include("GLAbstraction/GLAbstraction.jl")

using .GLAbstraction

const atlas_texture_cache = Dict{Any, Tuple{Texture{Float16, 2}, Function}}()

function cleanup_texture_atlas!(context, called_from_finalizer = false)
    to_delete = filter(atlas_ctx -> atlas_ctx[2] == context, keys(atlas_texture_cache))
    called_from_finalizer || require_context(context)
    for (atlas, ctx) in to_delete
        tex, func = pop!(atlas_texture_cache, (atlas, ctx))
        Makie.remove_font_render_callback!(atlas, func)
        GLAbstraction.free(tex, called_from_finalizer)
    end
    return
end

function get_texture!(context, atlas::Makie.TextureAtlas, called_from_finalizer = false)
    # clean up dead context!
    filter!(atlas_texture_cache) do ((ptr, ctx), tex_func)
        if GLAbstraction.context_alive(ctx)
            return true
        else
            if !called_from_finalizer
                @error("Cached atlas textures should be removed explicitly! $ctx")
                println("Reason:", GLFW.is_initialized() ? "" : " not initialized", was_destroyed(ctx) ? " destroyed" : "")
                Base.show_backtrace(stderr, Base.catch_backtrace())
            else
                Threads.@spawn println(stderr, "Cached atlas textures did not get cleaned up for context ", ctx)
            end
            tex_func[1].id = 0 # Should get cleaned up when OpenGL context gets destroyed
            Makie.remove_font_render_callback!(atlas, tex_func[2])
            return false
        end
    end

    if haskey(atlas_texture_cache, (atlas, context))
        return atlas_texture_cache[(atlas, context)][1]
    elseif called_from_finalizer
        return nothing
    else
        require_context(context)
        tex = Texture(
            context, atlas.data,
            minfilter = :linear,
            magfilter = :linear,
            # TODO: Consider alternatives to using the builtin anisotropic
            # samplers for signed distance fields; the anisotropic
            # filtering should happen *after* the SDF thresholding, but
            # with the builtin sampler it happens before.
            anisotropic = 16f0,
            mipmap = true
        )

        function callback(distance_field, rectangle)
            ctx = tex.context
            if GLAbstraction.context_alive(ctx)
                prev_ctx = GLAbstraction.current_context()
                ShaderAbstractions.switch_context!(ctx)
                tex[rectangle] = distance_field
                ShaderAbstractions.switch_context!(prev_ctx)
            end
        end
        Makie.font_render_callback!(callback, atlas)
        atlas_texture_cache[(atlas, context)] = (tex, callback)
        return tex
    end
end

include("glwindow.jl")
include("postprocessing.jl")
include("screen.jl")
include("glshaders/visualize_interface.jl")
include("glshaders/lines.jl")
include("glshaders/image_like.jl")
include("glshaders/mesh.jl")
include("glshaders/particles.jl")
include("glshaders/surface.jl")
include("glshaders/voxel.jl")

include("picking.jl")
include("rendering.jl")
include("events.jl")
include("drawing_primitives.jl")
include("display.jl")
