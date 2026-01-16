# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Makie Core Package

This is the core Makie package providing the abstract plotting interface and shared functionality for all backends.

## Key Components

### Core Types (src/types.jl)
- **Scene**: Low-level canvas with camera, plots, and events
- **AbstractPlot**: Base type for all plots
- **Attributes**: Observable-based property system
- **Transformation**: Coordinate transformation handling

### Plotting Interface (src/interfaces.jl)
- Main plotting functions: `plot`, `plot!`, `scatter`, `lines`, etc.
- Plot type determination via `plottype()`
- Argument conversion pipeline

### Basic Recipes (src/basic_recipes/)
- **axis.jl**: 2D/3D axis rendering
- **buffers.jl**: Mesh and surface generation
- **convenience_functions.jl**: High-level plotting helpers
- **text.jl**: Text rendering with rich formatting

### Layout System (src/makielayout/)
- **blocks/**: UI components (Axis, Colorbar, Legend, etc.)
- **interactions.jl**: User interaction handling
- **types.jl**: Layout type definitions

### Conversion System (src/conversions.jl)
- Trait-based conversion dispatch
- DimConversions for dates, categorical data
- Custom type conversion support

### Camera System (src/camera/)
- **camera.jl**: Abstract camera interface
- **camera2d.jl**: 2D camera with pan/zoom
- **camera3d.jl**: 3D camera with arcball rotation

## Common Tasks

### Adding a New Plot Type
```julia
@recipe(MyPlot, x, y) do scene
    Attributes(
        color = :blue,
        markersize = 10
    )
end

function plot!(plot::MyPlot)
    # Convert arguments and create atomic plots
    ...
end
```

### Extending Conversions
```julia
convert_arguments(P::Type{<:AbstractPlot}, data::MyType) = ...
```

### Working with Observables
```julia
# Attributes are automatically Observable
plot.color[] = :red  # Update color
on(plot.color) do c
    # React to color changes
end
```

## Testing

Run tests from the Makie directory:
```julia
]test Makie
# Or specific test files
include("test/plots/barplot.jl")
```

Test categories:
- `test/isolated/`: Unit tests without plotting
- `test/plots/`: Plot-specific tests
- `test/conversions/`: Conversion pipeline tests

## Important Files

- **Makie.jl**: Main module with exports
- **interfaces.jl**: Core plotting API
- **scenes.jl**: Scene management
- **figures.jl**: Figure API
- **theming.jl**: Theming system
- **stats/**: Statistical plot recipes
- **compute-plots.jl**: ComputeGraph integration for plots