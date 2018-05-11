using ModernGL, GLFW, FixedPointNumbers

include("GLAbstraction/GLAbstraction.jl")
using .GLAbstraction
include("GLVisualize/GLVisualize.jl")
using .GLVisualize

include("glwindow.jl")
include("screen.jl")
include("rendering.jl")
include("events.jl")
include("drawing_primitives.jl")
