# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## GLMakie Backend

GLMakie is the native, desktop-based backend for Makie.jl, providing GPU-powered, interactive 2D and 3D plotting in standalone GLFW windows. It requires an OpenGL enabled graphics card with OpenGL version 3.3 or higher.

## Architecture

### Rendering Pipeline
1. **GLAbstraction**: Low-level OpenGL abstraction layer
2. **Shader System**: GLSL shaders in `assets/shader/`
3. **Drawing Methods**: Specialized rendering for each plot type
4. **Screen Management**: Window and rendering context handling

### Key Components

#### Screen Configuration (src/screen.jl)
The `ScreenConfig` struct controls all window and rendering settings:

**Renderloop Options:**
- `renderloop`: Function that starts the renderloop (default: `GLMakie.renderloop`)
- `pause_renderloop`: Start with paused renderloop (default: false)
- `vsync`: Enable vertical sync (default: false)
- `render_on_demand`: Only render when scene changes (default: true)
- `framerate`: Target frames per second (default: 30.0)
- `px_per_unit`: Resolution scaling factor (default: automatic)

**Window Options:**
- `float`: Window stays on top (default: false)
- `focus_on_show`: Focus window when shown (default: false)
- `decorated`: Show window decorations (default: true)
- `title`: Window title (default: "Makie")
- `fullscreen`: Start in fullscreen (default: false)
- `visible`: Show window (default: true)
- `scalefactor`: Window DPI scaling (default: automatic)
- `monitor`: Monitor to display on (default: nothing)

**Rendering Options:**
- `oit`: Order-independent transparency (default: true)
- `fxaa`: Fast approximate anti-aliasing (default: true)
- `ssao`: Screen-space ambient occlusion (default: true)
- `transparency_weight_scale`: OIT weight factor (default: 1000f0)
- `max_lights`: Maximum number of lights for MultiLightShading (default: 64)
- `max_light_parameters`: Maximum light parameters for rendering (default: 5f0)

**Debug Options:**
- `debugging`: Enable debug mode (default: false)

#### GLAbstraction (src/GLAbstraction/)
- **GLShader.jl**: Shader compilation and management
- **GLTexture.jl**: Texture handling with automatic formats
- **GLBuffer.jl**: GPU buffer management
- **GLTypes.jl**: OpenGL type definitions including GLVertexArray and GLFramebuffer
- **GLUniforms.jl**: Uniform handling for shaders
- **GLRender.jl**: Core rendering functionality

#### Plot Rendering (src/)
- **plot-primitives.jl**: Main rendering dispatch and atomic drawing functions
- **lines.jl, mesh.jl, scatter.jl**: Specialized renderers
- **picking.jl**: Mouse interaction and object selection

#### Shader System (assets/shader/)
Core shaders:
- **mesh.vert/frag**: 3D mesh rendering with lighting
- **lines.vert/geom/frag**: Line rendering with smooth joins  
- **line_segment.vert/geom**: Line segment rendering
- **sprites.vert/geom**: Point sprite rendering
- **heatmap.vert/frag**: 2D heatmap rendering
- **volume.vert/frag**: Volume rendering
- **voxel.vert/frag**: Voxel rendering
- **dots.vert/frag**: Simple dot rendering
- **particles.vert**: Particle system rendering
- **surface.vert**: Surface rendering

Utility shaders:
- **util.vert**: Common vertex shader utilities
- **fragment_output.frag**: Standard fragment output
- **lighting.frag**: Lighting calculations
- **distance_shape.frag**: Distance field shapes

Post-processing:
- **postprocessing/fxaa.frag**: Anti-aliasing
- **postprocessing/SSAO.frag**: Ambient occlusion
- **postprocessing/SSAO_blur.frag**: SSAO blur pass
- **postprocessing/OIT_blend.frag**: Order-independent transparency
- **postprocessing/fullscreen.vert**: Fullscreen quad vertex shader
- **postprocessing/postprocess.frag**: General post-processing
- **postprocessing/copy.frag**: Texture copying

## Common Tasks

### Activation and Configuration
```julia
# Basic activation
GLMakie.activate!()

# With configuration
GLMakie.activate!(
    vsync = true,
    framerate = 60.0,
    render_on_demand = false,
    title = "My Plot"
)

# Set configuration permanently
Makie.set_theme!(GLMakie = (vsync = true, framerate = 60.0))
```

### Window Management
```julia
# Create screen with specific size
screen = GLMakie.Screen(resolution = (800, 600))

# Multiple windows (experimental)
display(GLMakie.Screen(), figure)

# Close all windows
GLMakie.closeall()

# Control renderloop
GLMakie.pause_renderloop!(screen)
GLMakie.start_renderloop!(screen)
```

### Resolution and Scaling
```julia
# Display with custom scale factor
display(fig, scalefactor = 1.5)

# Render at different resolution
display(fig, px_per_unit = 2)  # 2x resolution

# Save with specific resolution
save("hires.png", fig, px_per_unit = 2)
```

### Debugging
```julia
# Enable debug mode
GLMakie.DEBUG[] = true

# Enable OpenGL error checking
ENV["MODERNGL_DEBUGGING"] = "true"

# Check if renderloop is running
GLMakie.renderloop_running(screen)
```

### Custom Rendering
```julia
# Force immediate render
GLMakie.render_frame(screen)

# Check if update needed
GLMakie.requires_update(screen)
```

### Adding New Shader
1. Create shader files in `assets/shader/`
2. Shaders are automatically loaded via `loadshader()`
3. Use in rendering function:
```julia
shader = screen.shader_cache[shader_name]
glUseProgram(shader)
```

## Renderloop Types

GLMakie provides three renderloop implementations:

1. **vsync**: Synchronized with display refresh rate
2. **fps**: Fixed framerate using timer
3. **on_demand**: Only renders when updates are needed (default)

Custom renderloops can be provided via the `renderloop` config option.

## Embedding GLMakie

GLMakie can be embedded in custom applications by:
1. Creating a custom window type
2. Implementing required interface methods
3. Managing the framebuffer manually

See the documentation for detailed embedding instructions.

## Platform-Specific Notes

### Linux
- Requires X11 or Wayland display
- Use Xvfb for headless: `xvfb-run -s '-screen 0 1024x768x24' julia`
- May need `DISPLAY=:0` environment variable
- For dedicated GPU: `DRI_PRIME=1 julia`

### macOS
- Menu bar must be set to "Never" hide for fullscreen
- OpenGL is deprecated but still functional
- Some features may have reduced performance

### Windows
- Generally best OpenGL support
- Automatic HiDPI scaling
- May need updated graphics drivers

### WSL
- Requires X server (e.g., VcXsrv)
- Set `DISPLAY=localhost:0` or use host IP
- May need additional OpenGL libraries

## Performance Optimization

1. **Render on Demand**: Enable `render_on_demand` to avoid unnecessary renders
2. **Instanced Rendering**: Use for many similar objects
3. **Geometry Caching**: Reuse vertex buffers via RenderObject cache
4. **Shader Uniforms**: Minimize uniform updates
5. **Texture Atlases**: Combine small textures
6. **Level of Detail**: Reduce complexity for distant objects
7. **Disable Effects**: Turn off `ssao` or `fxaa` if not needed

## Important Files

- **GLMakie.jl**: Main module and exports
- **screen.jl**: Window/context management and configuration
- **events.jl**: Input event handling
- **display.jl**: Display and scene management
- **plot-primitives.jl**: Core rendering dispatch
- **precompiles.jl**: Precompilation for faster startup

## Thread Safety

⚠️ **GLMakie is not thread-safe!** Display and Observable updates from other threads may cause segmentation faults. All GLMakie operations should be performed from the main thread.