# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## CairoMakie Backend

CairoMakie is a Cairo.jl-based backend for Makie, providing high-quality 2D vector graphics and publication-quality plots. It's CPU-based (no GPU required) and focuses on pixel-perfect rendering for static outputs.

## Architecture

### Rendering Pipeline
1. Scene traversal and plot collection with z-order sorting
2. Transformation to Cairo coordinates (y-flipped)
3. Primitive drawing with Cairo API
4. Selective rasterization for complex plots
5. Output to various formats (SVG, PDF, EPS, PNG)

### Key Components

#### Main Rendering (src/)
- **plot-primitives.jl**: Core drawing functions (`draw_atomic` for each plot type)
- **cairo-extension.jl**: Cairo API extensions (fonts, matrices, glyphs)
- **screen.jl**: Screen types and configuration for different outputs
- **display.jl**: Backend show methods for different MIME types
- **scatter.jl**: Text and scatter rendering with glyph support
- **lines.jl**: Line drawing with patterns and styles
- **mesh.jl**: Mesh and polygon rendering
- **image-hmap.jl**: Image and heatmap rendering
- **utils.jl**: Helper functions and conversions
- **overrides.jl**: Backend-specific plot modifications

## Output Formats

### Raster Formats
```julia
save("plot.png", fig; px_per_unit=2)  # Control resolution
# px_per_unit controls the pixel density (default: 2.0)
```

### Vector Formats
```julia
save("plot.pdf", fig; pdf_version="1.4")  # Restrict PDF version
save("plot.svg", fig)  # SVG with CSS pixels (pt_per_unit / 0.75)
save("plot.eps", fig)  # Encapsulated PostScript
```

## Configuration and Activation

```julia
using CairoMakie
CairoMakie.activate!(
    type = "png",           # or "svg" for inline display
    px_per_unit = 2.0,      # Resolution for raster output (png, jpeg, etc.)
    pt_per_unit = 0.75,     # Points per unit for vector output (pdf, svg, eps)
    antialias = :best,      # :best, :good, :subpixel, :none
    visible = false,        # Open viewer after rendering
    pdf_version = "1.4"     # Restrict PDF version (1.4, 1.5, 1.6, 1.7)
)
```

## Selective Rasterization

For complex plots in vector outputs, use selective rasterization to reduce file size:

```julia
# Rasterize at default resolution
scatter(..., rasterize = true)

# Rasterize with custom scaling factor
heatmap(..., rasterize = 10)  # 10x resolution

# Disable rasterization
plot.rasterize = false
```

## Font and Text Rendering

### Font Support
```julia
# CairoMakie uses FreeType for font rendering
# Supports system fonts via Fontconfig
text(..., font = "Arial")
text(..., font = "Times New Roman")

# Use Makie's font aliases
text(..., font = :bold)
text(..., font = :italic)
```

### Glyph Rendering
- Direct glyph rendering for precise text placement
- Per-glyph color, rotation, and scaling support
- Stroke and fill for text outlines

## Z-Order and 3D Limitations

CairoMakie is a 2D engine with limited 3D support:
- No z-clipping (all 3D content is flattened)
- Z-ordering by sorting plots before drawing
- Use `translate!(plot, 0, 0, z)` to control layering

## Performance Optimization
- Use `rasterize` attribute for complex scenes in PDFs/SVGs
- Batch similar drawing operations
- Minimize transparency layers
- Pre-calculate transformations
- Consider GLMakie for animations or interactive plots

## Coordinate Systems

CairoMakie handles multiple coordinate transforms:
1. **Data space**: Original plot coordinates
2. **Scene space**: After plot transformations  
3. **Markerspace**: For text and scatter positioning
4. **Screen space**: Device-independent pixel coordinates
5. **Cairo space**: Cairo's coordinate system (y-flipped from Makie)

## Drawing Implementation

### Core Drawing Functions
```julia
# Each plot type has a draw_atomic method
draw_atomic(scene::Scene, screen::Screen, plot::Scatter)
draw_atomic(scene::Scene, screen::Screen, plot::Lines)
draw_atomic(scene::Scene, screen::Screen, plot::Text)
```

### Cairo Context Management
- Heavy use of `Cairo.save()` and `Cairo.restore()`
- Proper clipping to scene viewports
- Transform matrix management for rotations/scaling

### Specialized Implementations
- **Text**: FreeType font rendering with glyph-level control
- **Scatter**: Optimized marker drawing with char support
- **Lines**: Pattern support and miter limits
- **Mesh**: Gradient mesh patterns for smooth shading
- **Image/Heatmap**: Direct ARGB surface rendering

## Backend-Specific Features

1. **Publication Quality**: Designed for high-quality static outputs
2. **True Vector Graphics**: Perfect scaling for PDFs/SVGs
3. **Selective Rasterization**: Mix vector and raster in same plot
4. **No GPU Required**: Works on any system with Cairo
5. **Font Flexibility**: System fonts via FreeType/Fontconfig
6. **Pattern Support**: Hatching and custom Cairo patterns
7. **PDF Version Control**: Restrict output to specific PDF versions
8. **Antialiasing Control**: Fine-grained control over rendering quality

## Common Issues and Solutions

### Font Issues
```julia
# Missing fonts - install system-wide or use fallbacks
text(..., font = Makie.defaultfont())

# Font sizing - use pt_per_unit for consistent sizing
CairoMakie.activate!(pt_per_unit = 0.75)
```

### Large File Sizes
```julia
# Rasterize complex elements
scatter(randn(10000), randn(10000), rasterize = true)

# Or with custom resolution
mesh(..., rasterize = 5)  # 5x resolution
```

### Performance
- CairoMakie is CPU-based and single-threaded
- For animations/interactivity use GLMakie
- Batch operations when possible
- Use `px_per_unit=1` for faster previews

### 3D Rendering
- Limited to orthographic projection
- No true 3D occlusion or depth testing
- Objects sorted by z-value for layering
- Use GLMakie for true 3D visualization

## Testing

```julia
]test CairoMakie

# Run with reference images
include("test/runtests.jl")
```

### Test Structure
- Integration with ReferenceTests.jl
- Visual regression testing
- Backend-specific test cases

## Development Tips

1. **Debugging**: Check Cairo context state with `Cairo.status()`
2. **Transforms**: Use `Cairo.get_matrix()` to debug transformations
3. **Clipping**: Verify clip regions with `Cairo.clip_extents()`
4. **Memory**: Cairo surfaces are garbage collected, but can be manually freed