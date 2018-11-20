module GLMakie

using Makie
using ModernGL, GLFW, FixedPointNumbers, Colors, GeometryTypes
using AbstractPlotting, StaticArrays
using ..Makie
using AbstractPlotting: Scene, Lines, Text, Image, Heatmap, Scatter, @key_str, Key, broadcast_foreach
using AbstractPlotting: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using AbstractPlotting: @get_attribute, to_value, to_colormap, extrema_nan
using Base: RefValue
import Base: push!, isopen, show
using FileIO
using ImageCore
import IntervalSets
using IntervalSets: ClosedInterval, (..)
using Base.Iterators: repeated, drop
using FreeType, FreeTypeAbstraction, FixedPointNumbers

for name in names(AbstractPlotting)
    @eval import AbstractPlotting: $(name)
end

import AbstractPlotting: colorbuffer

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

include("GLVisualize/GLVisualize.jl")
using .GLVisualize

include("glwindow.jl")
include("screen.jl")
include("rendering.jl")
include("events.jl")
include("drawing_primitives.jl")

struct GLBackend <: AbstractPlotting.AbstractBackend
end
function AbstractPlotting.backend_display(x::GLBackend, scene::Scene)
    screen = global_gl_screen()
    # This should only get called if inline display false, so we display the window
    GLFW.set_visibility!(to_native(screen), true)
    display(screen, scene)
    return screen
end

colorbuffer(screen) = error("Color buffer retrieval not implemented for $(typeof(screen))")

"""
    scene2image(scene::Scene)

Buffers the `scene` in an image buffer.
"""
function scene2image(scene::Scene)
    screen = global_gl_screen()
    display(screen, scene)
    colorbuffer(screen)
end

function AbstractPlotting.backend_show(::GLBackend, io::IO, m::MIME"image/png", scene::Scene)
    img = scene2image(scene)
    GLFW.set_visibility!(to_native(global_gl_screen()), !AbstractPlotting.use_display[])
    FileIO.save(FileIO.Stream(FileIO.format"PNG", io), img)
end

function __init__()
    AbstractPlotting.register_backend!(GLBackend())
end

end
