# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Makie.jl is a high-performance, extensible plotting package for Julia. It's structured as a monorepo containing:
- **Makie**: Core plotting library with abstract interfaces
- **GLMakie**: OpenGL backend for interactive 3D graphics (GPU-accelerated, interactive)
- **CairoMakie**: Cairo backend for high-quality 2D vector graphics (publication-quality, static)
- **WGLMakie**: WebGL backend for browser-based visualizations
- **RPRMakie**: Radeon ProRender backend for ray-traced rendering (experimental)
- **ReferenceTests**: Visual regression testing infrastructure
- **ComputePipeline**: Internal dependency for the new compute graph system

Note: There are separate CLAUDE.md files in `docs/` and `ReferenceTests/` with specific guidance for those subsystems.

## Quick Start

```julia
# Install a backend (backend includes Makie automatically)
using Pkg
Pkg.add("GLMakie")  # or "CairoMakie", "WGLMakie"

# Basic plotting
using GLMakie
scatter(randn(100), randn(100))
```

## Development Setup

```julia
# Clone and develop all packages locally
]dev --local Makie GLMakie CairoMakie WGLMakie RPRMakie

# Also develop ReferenceTests for running tests
]dev path/to/Makie/ReferenceTests

# Activate a backend
using GLMakie
GLMakie.activate!()
# Or with configuration
GLMakie.activate!(title = "My Plot", fxaa = false)
```

## Common Commands

### Building Documentation
```bash
cd docs
julia --project makedocs.jl

# Or with xvfb for headless environments
DISPLAY=:0 xvfb-run -s '-screen 0 1024x768x24' julia --project makedocs.jl

# Serve locally (requires LiveServer.jl)
julia --project -e 'using LiveServer; serve(dir="build")'
```

The documentation uses:
- **DocumenterVitepress**: Modern documentation theme
- Custom blocks for figures, attribute docs, and short docs that execute examples during build

### Running Tests
```julia
# Test specific packages
]test Makie
]test GLMakie
]test CairoMakie

# Run specific test files
using Pkg
Pkg.activate("Makie/test")
include("Makie/test/plots/barplot.jl")

# Enable compute checks
ENV["ENABLE_COMPUTE_CHECKS"] = "true"
```

### Code Formatting
```bash
# Run formatter (uses Runic)
julia tooling/formatter/format.jl
```

### Version Bumping
```julia
# Update versions across packages
include("tooling/bump_versions.jl")
```

### Reference Test Updates
```julia
using ReferenceUpdater
# View test results from local run
ReferenceUpdater.serve_update_page_from_dir("GLMakie/test/reference_images/")
# Or from CI run
ReferenceUpdater.serve_update_page(pr = 1234)
```

### Reference Test Workflow
1. Tests generate images using `@reference_test` macro
2. Images compared against downloaded references from GitHub releases
3. Differences scored using perceptual algorithm (not pixel-perfect)
4. Results uploaded as CI artifacts
5. Review changes with ReferenceUpdater
6. References stored by version (e.g., `refimages-v0.21`)

## Architecture Overview

### Type Hierarchy
- **Transformable** → AbstractScene → Scene
- **Transformable** → AbstractPlot → Plot{PlotFunc, T}
- **Figure** contains Blocks (Axis, Colorbar, Legend, etc.) and a GridLayout
- **Scene** is the low-level canvas with camera and transformations

### Plotting Pipeline
1. User API: `plot(args...; kwargs...)`
2. Plot type determination via `plottype(args...)`
3. Argument conversion through `convert_arguments`
4. Scene integration with transformations
5. Backend-specific rendering

### Key Patterns
- **Observables**: Reactive programming for attribute updates
- **Recipe System**: `@recipe` macro for composable plot types  
- **Conversion Traits**: Type-based data conversion dispatch (PointBased, GridBased, etc.)
- **ComputeGraph**: Manages computational dependencies (new in 0.24+)
- **SpecApi**: Declarative plotting API (experimental)

### Plot Method Signatures
```julia
# Non-mutating (creates figure/axis)
scatter(args...) -> FigureAxisPlot
scatter(gridposition, args...) -> AxisPlot

# Mutating (uses current figure/axis)
scatter!(args...) -> Scatter
scatter!(axis, args...) -> Scatter
```

### Backend Interface
All backends implement:
- Screen constructors for display/saving
- Rendering methods for scene drawing
- Atomic plot drawing functions

### Important Directories
- `Makie/src/basic_recipes/`: Core plot implementations
- `Makie/src/makielayout/`: Layout system and UI blocks
- `{Backend}/src/plot-primitives.jl`: Backend-specific rendering
- `{Backend}/assets/shader/`: GLSL shaders (GLMakie)
- `docs/`: Documentation source and build scripts
  - `src/`: Markdown source files
  - `makedocs.jl`: Main documentation builder
- `ReferenceTests/`: Visual regression testing
- `docs/src/`: Documentation source
  - `explanations/`: Conceptual documentation
  - `tutorials/`: Step-by-step guides
  - `reference/`: API documentation
  - `how-to/`: Task-specific instructions

## Development Tips

1. **Monorepo Workflow**: Changes across packages are coordinated
2. **Local Testing**: Develop packages with `]dev ./Package`
3. **Reference Tests**: Visual regression tests for rendering changes
4. **Performance**: Use ComputeGraph and Float32Convert
5. **Debugging GLMakie**: Set `GLMakie.DEBUG[] = true`
6. **Environment Variables**:
   - `ENABLE_COMPUTE_CHECKS=true`: Enable compute graph validation
   - `REUSE_IMAGES_TAR=1`: Skip redownloading reference images
7. **Observable Updates**: Use `Makie.update!(plot, attr=value)` or update observables directly
8. **Theming**: Use `set_theme!()`, `with_theme()`, or `update_theme!()`
9. **Layout**: Use GridLayout and GridPositions for complex layouts

## Contributing

- Use Issues for bugs/regressions
- Use Discussions for questions/features
- PRs should include tests and documentation
- Update NEWS file for user-facing changes
- One feature per PR
- Documentation is built automatically on PRs
- Visual regression tests run on all PRs

## Common Patterns

### Creating Figures with Layouts
```julia
f = Figure()
ax1 = Axis(f[1, 1])
ax2 = Axis(f[1, 2])
Colorbar(f[1, 3], ...) 
# Or using GridPositions
scatter(f[2, 1:2], data)
```

### Recipe Definition
```julia
@recipe MyPlot (x, y) begin
    color = :red
    @inherit colormap
    Makie.mixin_generic_plot_attributes()...
end

function plot!(myplot::MyPlot)
    # Implementation using other plots
end
```

### Observable Patterns
```julia
# Create observable
x = Observable(0.0)

# React to changes
on(x) do val
    println("New value: $val")
end

# Update
x[] = 5.0

# Lift to create derived observables
y = lift(x -> x^2, x)
```

## Ecosystem

- **AlgebraOfGraphics.jl**: Grammar-of-graphics style plotting
- **GeoMakie.jl**: Geographic plotting with projections
- **GraphMakie.jl**: Graph/network visualization
- **SwarmMakie.jl**: Beeswarm plots
- **Beautiful Makie**: Gallery of advanced examples

## Troubleshooting

- **Texture size errors**: Tile large heatmaps/volumes
- **Font issues**: Check `FreeTypeAbstraction.valid_fontpaths` or set `ENV["FREETYPE_ABSTRACTION_FONT_PATH"]`
- **Layout issues**: Use `tellwidth/tellheight = false` or `resize_to_layout!()`
- **Performance**: Use Float32, avoid large textures, use ComputeGraph

## Recipe System Details

### Type Recipes
Convert custom types to plot-compatible data:
```julia
# Convert all plot types
Makie.convert_arguments(P::Type{<:AbstractPlot}, x::MyType) = convert_arguments(P, rand(10))
# Convert specific plot type
Makie.convert_arguments(P::Type{<:Scatter}, x::MyType) = ...
# Set default plot type
plottype(::MyType) = Surface
```

### Full Recipes with @recipe
```julia
@recipe MyPlot (x, y, z) begin
    "Documentation for attribute"
    plot_color = :red
    colormap = @inherit colormap :viridis
    shared_attributes()...  # Include from @DocumentedAttributes
end

function Makie.plot!(myplot::MyPlot)
    # Implementation using other plots
    lines!(myplot, myplot[:x], color = myplot[:plot_color])
    plot
end

# Set preferred axis type
Makie.args_preferred_axis(::Type{<:MyPlot}, x, y, z) = Makie.LScene
```

### Conversion Traits
- `NoConversion`: Default, no special handling
- `PointBased`: Converts to `Vector{Point{D,T}}` (Scatter, Lines)
- `VertexGrid`: Grid data with vertices (Surface)
- `CellGrid`: Grid data with cells (Heatmap)
- `ImageLike`: Image-like data (Image)
- `VolumeLike`: 3D volume data (Volume)

## Observable System (Detailed)

### Basic Usage
```julia
x = Observable(0.0)
on(x) do value
    println("New value: $value")
end
x[] = 5.0  # Triggers callback

# Chaining with lift
y = lift(x -> x^2, x)
z = @lift($x + $y)  # Macro syntax
```

### Advanced Patterns
- `map_latest`: Asynchronous updates with throttling
- `on_latest`: Skip intermediate updates for expensive operations
- Manual synchronization: `obs.val = value` then `notify(obs)`
- Priority control: `on(f, obs; priority = -1)`

### Common Issues
```julia
# Synchronous update problem
xs[] = 1:11  # May error if dependent obs expects size 10
ys[] = rand(11)

# Solution: Update without triggering
xs.val = 1:11
ys[] = rand(11)  # Triggers both
```

## ComputeGraph (New in 0.24+)

The ComputeGraph is a new system that replaces loose Observable networks, solving synchronization and performance issues.

### Basic Usage
```julia
graph = ComputeGraph()
add_input!(graph, :input1, 1)
add_input!(conversion_func, graph, :input2, 2)

# Simple computation
map!((a, b) -> a + b, graph, [:input1, :input2], :output)

# Full control
register_computation!(graph, [:input1, :input2], [:output]) do inputs, changed, cached
    input1, input2 = inputs
    return (input1[] + input2[], )
end

# Update and retrieve
update!(graph, input1 = 5)
result = graph[:output][]
```

### Plot Integration
```julia
# Update plot attributes atomically
Makie.update!(plot, x = new_x, y = new_y)

# Register projected positions
register_projected_positions!(plot, input_name = :positions)
```

### Connecting Graphs
```julia
graph2 = ComputeGraph()
add_input!(graph2, :sum, graph[:sum])  # Connect output to input
```

## Layout System (GridLayoutBase)

### GridLayout Fundamentals
```julia
fig = Figure()
ga = GridLayout(fig[1, 1])
ax1 = Axis(ga[1, 1])
ax2 = Axis(ga[1, 2])
colgap!(ga, 10)
rowgap!(ga, 5)

# Size control
colsize!(ga, 1, Fixed(200))
rowsize!(ga, 2, Relative(0.5))
```

### Size Types
- `Fixed(size)`: Exact size in pixels
- `Relative(fraction)`: Fraction of available space
- `Auto()`: Size from content
- `Aspect(n, ratio)`: Maintain aspect ratio

### Alignment & Protrusions
- Horizontal: `:left`, `:center`, `:right`
- Vertical: `:top`, `:center`, `:bottom`
- Protrusions: Space for axis decorations (automatic)

### Layout Utilities
```julia
# Nested layouts
inner = GridLayout(ga[2, :])

# Span multiple cells
ax3 = Axis(ga[3, 1:2])

# Mix blocks and plots
Label(ga[0, :], "Title", valign = :bottom)
Colorbar(ga[:, 3], ...)
```

## Conversion Pipeline (Detailed)

### Full Pipeline Steps
1. **expand_dimensions**: Generate missing data (e.g., x,y for image)
2. **dim_convert**: Handle special types (Units, Dates, Categorical)
3. **convert_arguments**: Normalize to plot-compatible formats
4. **transform_func**: Apply non-linear transforms (e.g., log scale)
5. **model**: Linear transformations (scale, translate, rotate)
6. **view/projection**: Camera transformations
7. **Float32Convert**: Ensure GPU-safe precision

### Custom Conversions
```julia
# Type recipe
function Makie.convert_arguments(PT::PointBased, sim::MySimulation)
    return Makie.convert_arguments(PT, positions(sim))
end

# Single argument conversion
Makie.convert_single_argument(x::MyType) = process(x)

# Dimension conversions
Makie.should_dim_convert(::Type{MyType}) = true
```

### Space Attribute
- `:data`: World space with full projections
- `:pixel`: Screen pixel coordinates
- `:clip`: Normalized device coordinates (-1 to 1)
- `:relative`: Relative to scene dimensions (0 to 1)

## Performance Patterns

### ComputeGraph Benefits
- Avoids redundant updates
- Lazy evaluation (computes on-demand)
- Atomic multi-attribute updates

### Float32 Optimization
- Automatic precision handling for GPU
- Prevents numerical issues with large coordinates
- Managed by Axis automatically

### Observable Optimization
```julia
# Batch updates
begin
    x.val = new_x
    y.val = new_y
    notify(z)  # Trigger once for all
end

# Use priorities
on(expensive_func, obs; priority = 1)  # Run later
on(cheap_func, obs; priority = -1)     # Run first
```

## Documentation System

### Documentation Organization
- **index.md**: Landing page
- **explanations/**: Conceptual docs (backends, scenes, observables, etc.)
- **tutorials/**: Step-by-step guides
- **how-to/**: Task-specific instructions  
- **reference/**: API docs for plots and blocks
- **api.md**: Function reference

### Adding Documentation
1. Write content in appropriate `docs/src/` subdirectory
2. Add to `pages` array in `docs/makedocs.jl`
3. Include visual examples using custom blocks
4. Test locally with `julia --project docs/makedocs.jl`

### Documentation Deployment
- Built via GitHub Actions on every PR (preview)
- Deployed to GitHub Pages (master → dev, tags → stable)
- Available at https://docs.makie.org/

## Common Utility Functions

### Axis Utilities
```julia
# Link axes
linkxaxes!(ax1, ax2)
linkyaxes!(ax1, ax2)

# Hide decorations
hidexdecorations!(ax)
hideydecorations!(ax)
hidedecorations!(ax)
hidespines!(ax)

# Tighten layout
tight_ticklabel_spacing!(ax)
tightlimits!(ax)
```

### Plot Utilities
```julia
# Lines and spans
hlines!(ax, y_values)
vlines!(ax, x_values)
abline!(ax, intercept, slope)
hspan!(ax, y1, y2)
vspan!(ax, x1, x2)

# Cycling colors/markers
lines!(ax, x, y, color = Cycled(1))
```

### Data Limits
```julia
# Manual limits
limits!(ax, xmin, xmax, ymin, ymax)
xlims!(ax, low, high)
ylims!(ax, low, high)

# Auto limits
autolimits!(ax)
reset_limits!(ax)
```