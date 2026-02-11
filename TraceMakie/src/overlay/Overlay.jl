# ============================================================================
# Overlay Rasterization Module
# ============================================================================
# GPU-ready rasterization for Lines, Scatter, and Text primitives
# Composited with ray-traced content using depth-aware alpha blending

module Overlay

using KernelAbstractions
using GeometryBasics
using LinearAlgebra
using ImageCore: RGBA, RGB

# Marker shape constants
const CIRCLE = UInt8(0)
const RECTANGLE = UInt8(1)
const ROUNDED_RECTANGLE = UInt8(2)
const TRIANGLE = UInt8(3)
const CROSS = UInt8(4)
const DIAMOND = UInt8(5)
const HEXAGON = UInt8(6)
const STAR = UInt8(7)

# Core exports
export RasterContext, project, project_with_scale, project_positions_kernel!

# Rasterization functions
export rasterize_lines!, rasterize_linesegments!
export rasterize_scatter!
export rasterize_text!, rasterize_text_kernel!, prepare_text_glyphs, GlyphInstance
export allocate_line_buffers, allocate_scatter_buffers

# Compositing
export composite!, clear_overlay!, create_overlay_buffer, flip_depth_y!

# Shape constants
export CIRCLE, RECTANGLE, ROUNDED_RECTANGLE, TRIANGLE, CROSS, DIAMOND, HEXAGON, STAR

# SDF primitives (for custom use)
export circle_sdf, rectangle_sdf, rounded_rect_sdf, diamond_sdf
export triangle_sdf, cross_sdf, hexagon_sdf, star_sdf
export line_segment_distance, evaluate_shape_sdf
export aastep, alpha_blend, AA_RADIUS

include("primitives.jl")
include("projection.jl")
include("lines.jl")
include("scatter.jl")
include("text.jl")
include("composite.jl")

end # module Overlay
