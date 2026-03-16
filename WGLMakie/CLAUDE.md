# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## WGLMakie Backend

WGLMakie is the WebGL-based backend for Makie, enabling interactive 2D and 3D visualizations in web browsers. It uses Three.js for rendering and Bonito.jl for HTML/JavaScript generation.

!!! warning
    WGLMakie is considered experimental - the JavaScript API isn't stable yet and notebook integration has some limitations.

## Architecture

### Components
1. **Julia Side**: Serialization, server management, and plot conversion
2. **JavaScript Side**: Three.js-based rendering with custom shaders
3. **Communication**: WebSocket/HTTP via Bonito.jl for Julia↔JS interaction

### Key Technologies
- **Three.js**: 3D graphics library for WebGL rendering
- **Bonito.jl**: Web app framework handling HTML/JS generation and communication
- **WebGL**: Browser-based GPU rendering (requires WebGL 2.0 for full features)

## Project Structure

### Julia Code (src/)
- **WGLMakie.jl**: Main module and activation
- **serialization.jl**: Convert Julia objects to JS-compatible format
- **three_plot.jl**: Three.js scene setup and plot management
- **display.jl**: Screen management and browser/notebook display
- **picking.jl**: Interactive picking and tooltip support
- **shader-abstractions.jl**: WebGL shader context
- **plot-primitives.jl**: Individual plot type implementations

### JavaScript Code (assets/)
- **wglmakie.js**: Bundled JS output
- **volume.vert/frag**: Volume rendering shaders
- **particles.vert/frag**: Point/scatter shaders
- Source files in development (ES modules)

## Common Tasks

### Development Setup
```julia
using WGLMakie
WGLMakie.activate!()  # Opens browser window

# Configuration options
WGLMakie.activate!(
    framerate = 30,  # FPS for animations
    resize_to = :parent,  # or :body, nothing, or (:width, :height)
    px_per_unit = nothing,  # Use browser's devicePixelRatio
    scalefactor = nothing   # Additional scaling
)
```

### Notebook Integration

#### IJulia/Jupyter
```julia
# Works with IJulia connection, no extra setup for local instances
using WGLMakie
WGLMakie.activate!()

# For remote JupyterHub/Binder (requires jupyter-server-proxy)
using Bonito
Page(; listen_port=9091, proxy_url="<instance>.com/user/<username>/proxy/9091")
```

#### Pluto.jl
```julia
# Basic usage
using WGLMakie
WGLMakie.activate!()

# For remote servers (using Bonito.Page)
using Bonito
Page(listen_url="0.0.0.0", listen_port=8080)
```

!!! note
    Page reload requires re-executing all cells. Static HTML export not fully supported yet.

#### VSCode
Works out of the box in plot pane and JuliaHub VSCode.

### Building JavaScript
```bash
cd WGLMakie
npm install
npm run build  # Creates assets/wglmakie.js
```

### Adding New Plot Type
1. Implement serialization in `serialization.jl`
2. Add `create_shader` function in plot type file
3. Register with `create_wgl_renderobject`
4. Add JavaScript handling if needed

## JavaScript Integration

### Direct JS Manipulation
```julia
using Bonito

App() do session
    fig, ax, splot = scatter(1:4)
    
    onjs(session, slider.value, js"""function(value) {
        $(splot).then(plots => {
            const scatter = plots[0]
            // Access uniforms and attributes
            scatter.material.uniforms.markersize.value.x = value
            scatter.geometry.attributes.pos.array[0] = value
            scatter.geometry.attributes.pos.needsUpdate = true
        })
    }""")
end
```

### Three.js Object Structure
- `plot.material.uniforms`: Shader uniforms (colors, sizes, etc.)
- `plot.geometry.attributes`: Vertex attributes (positions, colors)
- Arrays are flat in JS (e.g., positions: [x1,y1,z1,x2,y2,z2,...])

### Offline Tooltips
```julia
App() do session
    f, ax, pl = scatter(1:4)
    
    callback = js"""(plot, index) => {
        const {pos, color} = plot.geometry.attributes
        const x = pos.array[index*2]
        const y = pos.array[index*2+1]
        return "Point: <" + x + ", " + y + ">"
    }"""
    
    tooltip = WGLMakie.ToolTip(f, callback; plots=pl)
    return DOM.div(f, tooltip)
end
```

## Browser Support & Limitations

### WebGL Version
- **WebGL 2.0**: Required for volume rendering and contour(volume)
- **WebGL 1.0**: Basic plotting works, but missing advanced features
- Check support at [caniuse.com/webgl2](https://www.lambdatest.com/web-technologies/webgl2)

### Browser Compatibility
- **Chrome/Edge**: Best performance, full WebGL 2.0 support
- **Firefox**: Good support, WebGL 2.0 enabled
- **Safari**: May need to [enable WebGL](https://discussions.apple.com/thread/8655829)
- **Mobile**: Basic support, limited interactivity

### Current Limitations
1. **Static Interactivity**: Limited without running Julia server
   - 3D rotation/zoom works offline
   - 2D interactions require server connection
2. **Missing Features**:
   - Order Independent Transparency
   - Some complex 3D features
3. **Notebook Limitations**:
   - Page reload loses state
   - Pluto static export incomplete

## Deployment Options

### Static HTML Export
```julia
using WGLMakie

# Activate WGLMakie
WGLMakie.activate!()

# Save standalone HTML
save("plot.html", figure)

# Or embed in custom HTML
open("index.html", "w") do io
    println(io, "<html><body>")
    show(io, MIME"text/html"(), figure)
    println(io, "</body></html>")
end

# Note: For advanced offline/exportable configurations, consult Bonito.jl documentation
# as Page options may vary with Bonito.jl versions
```

### Interactive Web Apps
```julia
using Bonito, WGLMakie

app = App() do session
    fig = Figure()
    # ... create interactive plot
    return fig
end

server = Bonito.Server(app, "127.0.0.1", 8082)
```

### State Recording (for sliders)
```julia
App() do session
    slider = Slider(1:10)
    # ... create plot with slider
    return Bonito.record_states(session, DOM.div(slider, fig))
end
```

## Performance Optimization

### Screen Configuration
```julia
WGLMakie.activate!(
    framerate = 60,  # Higher for smooth animation
    px_per_unit = 2.0,  # Higher for retina displays
)
```

### Data Transfer
- Use Float32 instead of Float64 when possible
- Limit update frequency for streaming data
- Batch updates to minimize communication

### Rendering
- Reduce mesh complexity for better performance
- Use simpler shaders when possible
- Consider LOD (Level of Detail) for complex scenes

## Testing & Debugging

### JavaScript Console
- Open browser DevTools (Ctrl+Shift+I)
- Check for WebGL errors and Three.js warnings
- Use `console.log(plot)` to inspect plot objects

### Common Issues

#### Blank or Missing Plots
```julia
# Check WebGL support
evaljs(session, js"console.log('WebGL2:', !!window.WebGL2RenderingContext)")

# Verify plot initialization
on(screen.plot_initialized) do success
    success || error("Plot initialization failed")
end
```

#### Performance Issues
- Profile with browser DevTools
- Check data serialization size
- Monitor WebSocket traffic

#### Deployment Issues
- CORS headers for external resources
- Proxy configuration for notebooks
- WebSocket connection through firewalls

## Important Implementation Details

### Plot UUID System
Each plot has a unique ID accessed via `js_uuid(plot)` for JS-side identification.

### Shader Context
WGLMakie uses a custom `WebGL` context type for shader generation compatible with ShaderAbstractions.jl.

### Display Priority
The display system uses `Bonito.browser_display()` as fallback when no HTML display is available.

### JupyterLab Integration
Special attributes prevent keyboard shortcut conflicts:
- `dataLmSuppressShortcuts = true`
- `dataJpSuppressContextMenu = nothing`