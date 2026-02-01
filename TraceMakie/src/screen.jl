# =============================================================================
# ScreenConfig
# =============================================================================

# Re-export integrators from Hikari for convenience
const Whitted = Hikari.Whitted
const SPPM = Hikari.SPPM
const FastWavefront = Hikari.FastWavefront
const VolPath = Hikari.VolPath

"""
    ScreenConfig

Configuration for TraceMakie rendering.

* `integrator`: The integrator to use for rendering (default: `Whitted()`)
  - `Whitted(; samples=8, max_depth=5)` - Fast Whitted-style ray tracing
  - `SPPM(; search_radius=0.075, max_depth=5, iterations=100)` - Stochastic progressive photon mapping
  - `FastWavefront(; samples=4)` - GPU-optimized wavefront path tracing
  - `VolPath(; samples_per_pixel=64, max_depth=8)` - Volumetric path tracing
* `exposure`: Exposure multiplier for postprocessing (default: 1.0)
* `tonemap`: Tonemapping method (default: :aces)
  - `:reinhard` - Simple Reinhard L/(1+L)
  - `:reinhard_extended` - Extended Reinhard with white point
  - `:aces` - ACES filmic (industry standard)
  - `:uncharted2` - Uncharted 2 filmic
  - `:filmic` - Hejl-Dawson filmic
  - `nothing` - No tonemapping (linear clamp)
* `gamma`: Gamma correction value (default: 2.2, use `nothing` to skip)
* `sensor`: Film sensor settings for pbrt-style image formation (default: nothing)
  - `Hikari.FilmSensor(iso=100, white_balance=0)` - ISO and white balance
  - ISO scales brightness (100 = baseline, 90 = slightly darker)
  - white_balance in Kelvin (0 = disabled, 5000 = warm, 6500 = D65)
* `backend`: Array type for rendering (default: `Array` for CPU)
  - `Array` - CPU rendering
  - `ROCArray` - AMD GPU via AMDGPU.jl
  - `CuArray` - NVIDIA GPU via CUDA.jl
* `denoise`: Enable à-trous wavelet denoising (default: false)
  - Requires auxiliary buffers (normals, depth) to be filled
  - Significantly reduces noise at low sample counts
* `denoise_config`: Configuration for the denoiser (default: sensible defaults)
  - `Hikari.DenoiseConfig(iterations=5, sigma_color=4.0, sigma_normal=128.0, sigma_depth=1.0)`
"""
struct ScreenConfig
    integrator::Hikari.Integrator
    exposure::Float32
    tonemap::Union{Symbol, Nothing}
    gamma::Union{Float32, Nothing}
    sensor::Union{Hikari.FilmSensor, Nothing}
    backend::Type  # Array type: Array for CPU, ROCArray/CuArray for GPU
    denoise::Bool
    denoise_config::Union{Hikari.DenoiseConfig, Nothing}

    function ScreenConfig(integrator, exposure, tonemap, gamma, sensor, backend=Array, denoise=false, denoise_config=nothing)
        actual_integrator = integrator isa Makie.Automatic ? Whitted() : integrator
        actual_exposure = Float32(exposure)
        actual_gamma = isnothing(gamma) ? nothing : Float32(gamma)
        return new(actual_integrator, actual_exposure, tonemap, actual_gamma, sensor, backend, denoise, denoise_config)
    end
end

# =============================================================================
# Screen
# =============================================================================

"""
    Screen <: Makie.MakieScreen

TraceMakie screen for ray-traced rendering.

# Constructors

    Screen(scene::Scene; screen_config...)
    Screen(scene::Scene, config::ScreenConfig)

# Configuration options (via screen_config or ScreenConfig):

\$(Base.doc(ScreenConfig))
"""
mutable struct Screen <: Makie.MakieScreen
    scene::Union{Nothing, Scene}
    state::Union{Nothing, TraceMakieState}
    config::ScreenConfig
end

function Base.show(io::IO, screen::Screen)
    scene_str = isnothing(screen.scene) ? "nothing" : "Scene(\$(size(screen.scene)))"
    backend_name = nameof(screen.config.backend)
    integrator_name = nameof(typeof(screen.config.integrator))
    print(io, "Screen(\$scene_str, backend=\$backend_name, integrator=\$integrator_name)")
end

function Base.show(io::IO, ::MIME"text/plain", screen::Screen)
    println(io, "TraceMakie.Screen")
    if !isnothing(screen.scene)
        println(io, "  Scene size: ", size(screen.scene))
        if !isnothing(screen.state)
            println(io, "  Plots: ", length(screen.state.plot_infos))
        end
    else
        println(io, "  Scene: not attached")
    end
    println(io, "  Backend: ", nameof(screen.config.backend))
    println(io, "  Integrator: ", nameof(typeof(screen.config.integrator)))
    print(io, "  Exposure: ", screen.config.exposure)
end

Base.size(screen::Screen) = isnothing(screen.scene) ? (0, 0) : size(screen.scene)

# Track whether screen is open for resource management
const _open_screens = Set{UInt}()

function Base.isopen(screen::Screen)
    return objectid(screen) in _open_screens || screen.state !== nothing
end

"""
    cleanup!(state::TraceMakieState)

Release GPU memory held by TraceMakieState.
"""
function cleanup!(state::TraceMakieState)
    # Cleanup film
    Hikari.cleanup!(state.film)

    # Finalize all preserved GPU arrays
    for arr in state.preserve
        finalize(arr)
    end
    empty!(state.preserve)

    return nothing
end

"""
    Base.close(screen::Screen)

Release all GPU resources held by the screen, including the integrator state,
film, and preserved GPU arrays. Call this when done rendering to free GPU memory.
"""
function Base.close(screen::Screen)
    # Cleanup TraceMakieState if present
    if screen.state !== nothing
        cleanup!(screen.state)
        screen.state = nothing
    end

    # Cleanup integrator's cached state
    close(screen.config.integrator)

    # Remove from open screens tracking
    delete!(_open_screens, objectid(screen))

    return nothing
end

function Screen(fb_size::NTuple{2, <:Integer}; screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    return Screen(fb_size, config)
end

function Screen(::NTuple{2, <:Integer}, config::ScreenConfig)
    return Screen(nothing, nothing, config)
end

function Screen(scene::Scene; screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    return Screen(scene, config)
end

function Screen(scene::Scene, config::ScreenConfig)
    screen = Screen(size(scene), config)
    screen.scene = scene
    # Register screen with scene so getscreen(scene) works
    Makie.push_screen!(scene, screen)
    return screen
end

Screen(scene::Scene, config::ScreenConfig, ::IO, ::MIME) = Screen(scene, config)
Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat) = Screen(scene, config)

function Makie.apply_screen_config!(screen::Screen, config::ScreenConfig, scene::Scene, args...)
    # Check if backend changed - if so, we need to recreate the screen entirely
    if screen.config.backend !== config.backend
        # Backend changed, need new screen with new state
        return Screen(scene, config)
    end

    # Check if integrator changed - if so, invalidate state to force re-render
    if typeof(screen.config.integrator) !== typeof(config.integrator)
        screen.state = nothing
    end

    # Update the config (postprocessing params like exposure/tonemap/gamma)
    screen.config = config
    return screen
end
Base.empty!(::Screen) = nothing

# =============================================================================
# Rendering
# =============================================================================

function render!(screen::Screen)
    state = screen.state
    scene = screen.scene
    isnothing(state) && error("Screen not set up - call display first")
    isnothing(scene) && error("No scene attached to screen")

    # Sync transforms and refit TLAS if needed
    sync_transforms!(state)

    # Clear film and render (scene/film are already CPU or GPU based on backend)
    Hikari.clear!(state.film)
    camera = state.camera[]

    # Fill auxiliary buffers if denoising is enabled (before main render)
    if screen.config.denoise
        Hikari.fill_aux_buffers!(state.film, state.hikari_scene, camera)
    end

    screen.config.integrator(state.hikari_scene, state.film, camera)
    return state.film
end

function Makie.colorbuffer(screen::Screen, format::Makie.ImageStorageFormat = Makie.JuliaNative; figure = nothing)
    if isnothing(screen.state)
        display(screen, screen.scene; figure = figure)
    end
    backend = screen.config.backend
    render!(screen)

    state = screen.state
    film = state.film
    camera = state.camera[]

    # Convert pixel samples to framebuffer (needed before denoising)
    # Note: VolPath integrator writes directly to framebuffer in its finalize kernel,
    # so we only call to_framebuffer! for other integrators (like Whitted) that use tiles
    if !(screen.config.integrator isa Hikari.VolPath)
        Hikari.to_framebuffer!(film)
    end
    scene = Adapt.adapt(backend, state.hikari_scene)
    # Fill depth buffer for overlay depth testing
    Hikari.fill_aux_buffers!(film, scene, camera)

    # Apply denoising if enabled (before postprocessing)
    config = screen.config
    if config.denoise
        denoise_cfg = something(config.denoise_config, Hikari.DenoiseConfig())
        Hikari.denoise!(film; config=denoise_cfg)
    end

    # Apply postprocessing on GPU/CPU (tonemapping, gamma, exposure, sensor)
    # Note: when denoising is enabled, postprocess! reads from postprocess buffer (denoised)
    # When denoising is disabled, postprocess! reads from framebuffer (raw)
    if config.denoise
        # Denoised result is in postprocess buffer, copy back to framebuffer for postprocess!
        copyto!(film.framebuffer, film.postprocess)
    end

    Hikari.postprocess!(film;
        exposure = config.exposure,
        tonemap = config.tonemap,
        gamma = config.gamma,
        sensor = config.sensor
    )

    # Render overlay plots (lines, scatter, text)
    if !isempty(state.overlay_plots)
        render_overlays!(state, screen.scene)
        # DEBUG: Capture overlay for inspection
        DEBUG_OVERLAY[] = copy(state.overlay_buffer)
        # Composite overlay onto postprocessed image (both use array convention)
        Overlay.composite!(film.postprocess, state.overlay_buffer)
    end

    # Copy postprocess buffer to CPU if on GPU, then convert to RGB{N0f8}
    result = Array(map(clamp01nan, film.postprocess))

    if format == Makie.GLNative
        return Makie.jl_to_gl_format(result)
    else # JuliaNative
        return result
    end
end

"""
    postprocess!(screen::Screen; exposure=nothing, tonemap=nothing, gamma=nothing)

Re-apply postprocessing to an already-rendered screen without re-rendering.

This is useful for quickly experimenting with different postprocessing settings
after a render is complete. Parameters that are not specified will use the
screen's existing config values.

# Arguments
- `screen`: A Screen that has already been rendered
- `exposure`: Exposure multiplier (default: use screen config)
- `tonemap`: Tonemapping method (:aces, :reinhard, :uncharted2, :filmic, or nothing)
- `gamma`: Gamma correction value (default: use screen config)

# Returns
The postprocessed image as `Matrix{RGB{N0f8}}`

# Example
```julia
# Render once
screen = TraceMakie.Screen(scene)
img = Makie.colorbuffer(screen)

# Try different postprocessing without re-rendering
img_bright = TraceMakie.postprocess!(screen; exposure=2.0)
img_filmic = TraceMakie.postprocess!(screen; tonemap=:filmic)
img_low_gamma = TraceMakie.postprocess!(screen; gamma=1.8)
img_sensor = TraceMakie.postprocess!(screen; sensor=Hikari.FilmSensor(iso=90, white_balance=5000))
```
"""
function postprocess!(screen::Screen;
    exposure::Union{Real, Nothing} = nothing,
    tonemap::Union{Symbol, Nothing, Missing} = missing,  # missing = use config, nothing = no tonemap
    gamma::Union{Real, Nothing} = nothing,
    sensor::Union{Hikari.FilmSensor, Nothing, Missing} = missing,  # missing = use config, nothing = no sensor
)
    if isnothing(screen.state)
        error("Screen has not been rendered yet. Call Makie.colorbuffer(screen) first.")
    end

    # Use provided values or fall back to screen config
    exp_val = isnothing(exposure) ? screen.config.exposure : Float32(exposure)
    tm_val = ismissing(tonemap) ? screen.config.tonemap : tonemap
    gamma_val = isnothing(gamma) ? screen.config.gamma : Float32(gamma)
    sensor_val = ismissing(sensor) ? screen.config.sensor : sensor

    # Apply postprocessing (works on GPU or CPU)
    Hikari.postprocess!(screen.state.film;
        exposure = exp_val,
        tonemap = tm_val,
        gamma = gamma_val,
        sensor = sensor_val
    )

    # Copy to CPU if on GPU, then convert to RGB{N0f8}
    postprocess_cpu = Array(screen.state.film.postprocess)
    result = map(postprocess_cpu) do c
        RGB{N0f8}(c.r, c.g, c.b)
    end

    return result
end

function Base.display(screen::Screen, scene::Scene; figure = nothing, display_kw...)
    screen.scene = scene
    screen.state = convert_scene_with_state(scene, screen.config.backend, screen.config.integrator)
    return screen
end

function Base.insert!(screen::Screen, scene::Scene, plot::AbstractPlot)
    # For now, rebuild the entire state when plots change
    # Future: incremental updates
    if !isnothing(screen.state)
        screen.state = convert_scene_with_state(scene, screen.config.backend, screen.config.integrator)
    end
    return screen
end

Makie.backend_showable(::Type{Screen}, ::Union{MIME"image/jpeg", MIME"image/png"}) = true

# =============================================================================
# Backend activation
# =============================================================================

"""
    TraceMakie.activate!(; screen_config...)

Sets TraceMakie as the currently active backend and allows setting screen configuration.

# Arguments (via screen_config):

\$(Base.doc(ScreenConfig))

# Examples

```julia
# Use default Whitted integrator
TraceMakie.activate!()

# Use Whitted with custom settings
TraceMakie.activate!(integrator = TraceMakie.Whitted(samples=16, max_depth=8))

# Configure postprocessing
TraceMakie.activate!(exposure = 1.5, tonemap = :reinhard, gamma = 2.2)
```
"""
function activate!(; screen_config...)
    if !isempty(screen_config)
        Makie.set_screen_config!(TraceMakie, screen_config)
    end
    Makie.set_active_backend!(TraceMakie)
    return
end

function __init__()
    # Register TraceMakie's default theme at init time (before activate)
    activate!()
    return
end

# =============================================================================
# Interactive rendering
# =============================================================================

"""
    render_interactive(mscene; backend, max_depth=5, exposure=1.0f0, tonemap=:aces, gamma=1.2f0, render_backend=Array)

Start an interactive ray-tracing render loop for a Makie scene.

The render loop continuously updates as the camera moves. Uses progressive rendering
with 1 sample per pixel per frame, accumulating samples over time for noise reduction.
When the camera moves or plot data changes, the film is cleared and accumulation restarts.

Plot data changes (volume data, material parameters, etc.) are detected via the compute graph
polling mechanism - no Observable callbacks needed.

Postprocessing parameters (exposure, tonemap, gamma) can be Observables for reactive updates.

# Arguments
- `mscene::Makie.Scene`: The Makie scene to render
- `backend`: The Makie backend to use for display (e.g., GLMakie)
- `max_depth=5`: Maximum ray bounces
- `exposure=1.0f0`: Exposure value (can be Observable)
- `tonemap=:aces`: Tonemapping method (can be Observable, options: :aces, :reinhard, :filmic, nothing)
- `gamma=1.2f0`: Gamma correction (can be Observable)
- `render_backend=Array`: Array type for rendering (Array for CPU, ROCArray/CuArray for GPU)

# Returns
A named tuple with handles for controlling the render:
- `stop`: Function to stop the render loop
"""
function render_interactive(mscene::Makie.Scene;
                            integrator=Hikari.Whitted(samples=1, max_depth=5),
                            exposure=1.0f0, tonemap=:aces, gamma=1.2f0,
                            sensor=nothing, backend=Array)
    # Wrap non-Observable parameters in Observables for uniform handling
    exposure_obs = exposure isa Observable ? exposure : Observable(exposure)
    tonemap_obs = tonemap isa Observable ? tonemap : Observable(tonemap)
    gamma_obs = gamma isa Observable ? gamma : Observable(gamma)

    # Create Screen with proper backend configuration
    config = ScreenConfig(integrator, Float32(exposure_obs[]), tonemap_obs[], gamma_obs[], sensor, backend)
    screen = Screen(nothing, nothing, config)
    # Initialize state via display
    display(screen, mscene)
    state = screen.state
    film = state.film
    camera = state.camera

    # Create overlay scene for progressive display
    imsub = Scene(mscene)
    display_buffer = film.postprocess
    imgp = image!(imsub, -1 .. 1, -1 .. 1, Array(display_buffer), uv_transform=(:rotr90, :flip_y))

    cam_start = camera[]
    loki = Threads.ReentrantLock()
    cam_rendered = camera[]
    running = Threads.Atomic{Bool}(true)

    # Main render loop using render! for progressive rendering
    root = Makie.rootparent(mscene)
    Base.errormonitor(Threads.@spawn while running[]
        Makie.isclosed(root) && break

        # Poll for plot data updates (material changes, geometry updates, etc.)
        # This triggers the compute graph to apply any pending in-place updates
        if poll_updates!(state)
            # Data changed - clear film and integrator state
            Hikari.clear!(film)
            Hikari.clear!(screen.config.integrator)
            lock(loki) do
                imgp.visible = false
            end
        end

        # Check camera change
        if cam_rendered != camera[]
            cam_rendered = camera[]
            # Clear film and integrator state to restart accumulation
            Hikari.clear!(film)
            Hikari.clear!(screen.config.integrator)
            lock(loki) do
                imgp.visible = false
            end
        end

        # Refit TLAS if transforms changed (e.g., animated objects)
        refit_if_needed!(state)

        # Render one iteration/sample using render! (allocation-free, progressive)
        Hikari.render!(screen.config.integrator, state.hikari_scene, film, camera[])

        # Apply postprocessing with current observable values
        current_tonemap = tonemap_obs[]
        tonemap_sym = current_tonemap isa Symbol ? current_tonemap : (isnothing(current_tonemap) ? nothing : Symbol(current_tonemap))

        # Get sensor from config (may be nothing)
        current_sensor = screen.config.sensor
        Hikari.postprocess!(film; exposure=Float32(exposure_obs[]), tonemap=tonemap_sym, gamma=Float32(gamma_obs[]), sensor=current_sensor)

        lock(loki) do
            imgp[3] = Array(film.postprocess)
            imgp.visible = true
        end
        sleep(1/30)  # 60 FPS update rate
    end)

    # Camera visibility thread - hides overlay when camera is moving
    Base.errormonitor(Threads.@spawn while running[] && !Makie.isclosed(root)
        lock(loki) do
            if cam_start != camera[]
                cam_start = camera[]
                imgp.visible = false
            end
        end
        sleep(1/30)
    end)

    # Return control handles
    return (
        running = running,
        screen = screen,
        image = imgp,
    )
end
