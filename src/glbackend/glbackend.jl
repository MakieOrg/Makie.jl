using GLAbstraction, GLVisualize, GLFW
import GLWindow
using ModernGL

include("screen.jl")
include("rendering.jl")
include("events.jl")
include("drawing_primitives.jl")

function to_glvisualize_key(k)
    k == :rotations && return :rotation
    k == :markersize && return :scale
    k == :glowwidth && return :glow_width
    k == :glowcolor && return :glow_color
    k == :strokewidth && return :stroke_width
    k == :strokecolor && return :stroke_color
    k == :positions && return :position
    k
end
