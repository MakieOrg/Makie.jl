try
    using GLFW
catch e
    @warn(
        """
            OpenGL/GLFW wasn't loaded correctly or couldn't be initialized.
            This likely means, you're on a headless server without having OpenGL support setup correctly.
            Have a look at the troubleshooting section in the readme:
            https://github.com/MakieOrg/Makie.jl/tree/master/GLMakie#troubleshooting-opengl.
        """
    )
    rethrow(e)
end

include("GLAbstraction/GLAbstraction.jl")

using .GLAbstraction

const atlas_texture_cache = Dict{Any, Tuple{Texture{Float16, 2}, Function}}()
const color_atlas_texture_cache = Dict{Any, Tuple{Texture{RGBAf, 2}, Function}}()

function cleanup_texture_atlas!(context)
    to_delete = filter(atlas_ctx -> atlas_ctx[2] == context, keys(atlas_texture_cache))
    for (atlas, ctx) in to_delete
        tex, func = pop!(atlas_texture_cache, (atlas, ctx))
        Makie.remove_font_render_callback!(atlas, func)
        GLAbstraction.free(tex)
    end
    to_delete_color = filter(atlas_ctx -> atlas_ctx[2] == context, keys(color_atlas_texture_cache))
    for (atlas, ctx) in to_delete_color
        tex, func = pop!(color_atlas_texture_cache, (atlas, ctx))
        Makie.remove_color_font_render_callback!(atlas, func)
        GLAbstraction.free(tex)
    end
    GLAbstraction.require_context_no_error(context) # avoid try .. catch at call site
    return
end

function get_texture!(context, atlas::Makie.TextureAtlas)
    # clean up dead context!
    filter!(atlas_texture_cache) do ((ptr, ctx), tex_func)
        if GLAbstraction.context_alive(ctx)
            return true
        else
            tex_func[1].id = 0 # Should get cleaned up when OpenGL context gets destroyed
            Makie.remove_font_render_callback!(atlas, tex_func[2])
            return false
        end
    end

    if haskey(atlas_texture_cache, (atlas, context))
        return atlas_texture_cache[(atlas, context)][1]
    else
        require_context(context)
        # anisotropic filtering sometimes creates artifacts with aspect/distortion
        # corrected anti-aliasing radius, mipmap seems irrelevant
        tex = Texture(context, atlas.data, minfilter = :linear, magfilter = :linear)

        function callback(distance_field, rectangle)
            ctx = tex.context
            return if GLAbstraction.context_alive(ctx)
                GLAbstraction.with_context(ctx) do
                    tex[rectangle] = distance_field
                end
            end
        end
        Makie.font_render_callback!(callback, atlas)
        atlas_texture_cache[(atlas, context)] = (tex, callback)
        return tex
    end
end

function get_color_texture!(context, atlas::Makie.ColorTextureAtlas)
    # Also check tex.id != 0: the texture may have been freed (e.g. by cleanup_texture_atlas!)
    # while the context is still alive (screen reuse from pool).
    filter!(color_atlas_texture_cache) do ((ptr, ctx), tex_func)
        if GLAbstraction.context_alive(ctx) && tex_func[1].id != 0
            return true
        else
            tex_func[1].id = 0
            Makie.remove_color_font_render_callback!(atlas, tex_func[2])
            return false
        end
    end

    if haskey(color_atlas_texture_cache, (atlas, context))
        return color_atlas_texture_cache[(atlas, context)][1]
    else
        require_context(context)
        tex = Texture(context, atlas.data, minfilter = :linear, magfilter = :linear)

        function callback(color_data, rectangle)
            ctx = tex.context
            return if tex.id != 0 && GLAbstraction.context_alive(ctx)
                GLAbstraction.with_context(ctx) do
                    tex[rectangle] = color_data
                end
            end
        end
        Makie.color_font_render_callback!(callback, atlas)
        color_atlas_texture_cache[(atlas, context)] = (tex, callback)
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
include("plot-primitives.jl")
include("display.jl")
