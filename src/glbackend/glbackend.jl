using ModernGL, GLFW, FixedPointNumbers

include("GLAbstraction/GLAbstraction.jl")
using .GLAbstraction

const atlas_texture_cache = RefValue{Texture{Float16, 2}}()

function get_texture!(atlas)
     if isassigned(atlas_texture_cache) && GLAbstraction.is_current_context(atlas_texture_cache[].context)
         atlas_texture_cache[]
     else
         tex = Texture(
             atlas.data,
             minfilter = :linear,
             magfilter = :linear,
             anisotropic = 16f0,
         )
         atlas_texture_cache[] = tex
         empty!(AbstractPlotting.font_render_callbacks)
         # update the texture, whenever a new font is added to the atlas
         AbstractPlotting.font_render_callback!() do distance_field, rectangle
             tex[rectangle] = distance_field
         end
         return tex
     end
 end


include("GLVisualize/GLVisualize.jl")
using .GLVisualize

include("glwindow.jl")
include("screen.jl")
include("rendering.jl")
include("events.jl")
include("drawing_primitives.jl")
