# ============================================================================
# Overlay Rendering — Lava graphics pipeline (vertex/geometry/fragment shaders)
# ============================================================================

# Marker shape constants (matching GLMakie's distance_shape.frag)
const CIRCLE = UInt8(0)
const RECTANGLE = UInt8(1)
const ROUNDED_RECTANGLE = UInt8(2)
const DISTANCEFIELD = UInt8(3)
const TRIANGLE_SHAPE = UInt8(4)
const CROSS = UInt8(5)
const DIAMOND = UInt8(6)
const HEXAGON = UInt8(7)
const STAR = UInt8(8)

include("primitives.jl")    # SDF helpers (aastep, smoothstep) — used by fragment shaders

# Graphics pipeline infrastructure
include("gfx_pipeline.jl")  # framebuffer, atlas, screen_to_ndc
include("renderobject.jl")  # LavaRenderObject, update_robj!, construct_robj

# Shader files (each contains vert/geom/frag + pipeline + setup function)
include("lava_lines.jl")
include("lava_scatter.jl")
include("lava_mesh.jl")
include("gfx_image.jl")
