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

function cleanup!(state::TraceMakieState)
    Hikari.cleanup!(state.film)
    return nothing
end

"""
    Base.close(screen::Screen)

Release all GPU resources held by the screen, including the integrator state,
film, and preserved GPU arrays. Call this when done rendering to free GPU memory.
"""
function Base.close(screen::Screen)
    if screen.state !== nothing
        cleanup!(screen.state)
        screen.state = nothing
    end

    close(screen.config.integrator)

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
    Makie.push_screen!(scene, screen)
    return screen
end

Screen(scene::Scene, config::ScreenConfig, ::IO, ::MIME) = Screen(scene, config)
Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat) = Screen(scene, config)

function Makie.apply_screen_config!(screen::Screen, config::ScreenConfig, scene::Scene, args...)
    if screen.config.backend !== config.backend
        return Screen(scene, config)
    end

    if typeof(screen.config.integrator) !== typeof(config.integrator)
        screen.state = nothing
    end

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

    # Poll compute graph for updates, then sync/refit TLAS
    poll_all_plots(screen, scene)
    tlas = get_tlas(state)
    Raycore.sync!(tlas)
    Raycore.refit_tlas!(tlas)

    # Clear film if data changed
    if state.needs_film_clear
        Hikari.clear!(state.film)
        state.needs_film_clear = false
    end

    camera = state.camera[]

    # Adapt scene for kernel traversal (TLAS → StaticTLAS, MultiTypeSet → StaticMultiTypeSet)
    backend = screen.config.backend
    ka_backend = if backend === Array
        Raycore.KA.CPU()
    else
        Raycore.KA.get_backend(backend{Float32}(undef, 1))
    end
    adapted_scene = Adapt.adapt(ka_backend, state.hikari_scene)

    # Fill auxiliary buffers if denoising is enabled (before main render)
    if screen.config.denoise
        Hikari.fill_aux_buffers!(state.film, adapted_scene, camera)
    end

    screen.config.integrator(adapted_scene, state.film, camera)
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

    # Convert pixel samples to framebuffer
    if !(screen.config.integrator isa Hikari.VolPath)
        Hikari.to_framebuffer!(film)
    end
    # Adapt scene for kernel traversal (fill_aux_buffers! needs StaticTLAS)
    ka_backend = if backend === Array
        Raycore.KA.CPU()
    else
        Raycore.KA.get_backend(backend{Float32}(undef, 1))
    end
    adapted_scene = Adapt.adapt(ka_backend, state.hikari_scene)
    # Fill depth buffer for overlay depth testing
    Hikari.fill_aux_buffers!(film, adapted_scene, camera)

    # Apply denoising if enabled (before postprocessing)
    config = screen.config
    if config.denoise
        denoise_cfg = something(config.denoise_config, Hikari.DenoiseConfig())
        Hikari.denoise!(film; config=denoise_cfg)
    end

    if config.denoise
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
        DEBUG_OVERLAY[] = copy(state.overlay_buffer)
        Overlay.composite!(film.postprocess, state.overlay_buffer)
    end

    # Copy postprocess buffer to CPU if on GPU, then convert to RGB{N0f8}
    # Flip vertically: film renders in raster convention (y=0 top),
    # Makie JuliaNative expects y=0 bottom
    result = Array(map(clamp01nan, film.postprocess))
    result = result[end:-1:begin, :]

    if format == Makie.GLNative
        return Makie.jl_to_gl_format(result)
    else # JuliaNative
        return result
    end
end

"""
    postprocess!(screen::Screen; exposure=nothing, tonemap=nothing, gamma=nothing)

Re-apply postprocessing to an already-rendered screen without re-rendering.
"""
function postprocess!(screen::Screen;
    exposure::Union{Real, Nothing} = nothing,
    tonemap::Union{Symbol, Nothing, Missing} = missing,
    gamma::Union{Real, Nothing} = nothing,
    sensor::Union{Hikari.FilmSensor, Nothing, Missing} = missing,
)
    if isnothing(screen.state)
        error("Screen has not been rendered yet. Call Makie.colorbuffer(screen) first.")
    end

    exp_val = isnothing(exposure) ? screen.config.exposure : Float32(exposure)
    tm_val = ismissing(tonemap) ? screen.config.tonemap : tonemap
    gamma_val = isnothing(gamma) ? screen.config.gamma : Float32(gamma)
    sensor_val = ismissing(sensor) ? screen.config.sensor : sensor

    Hikari.postprocess!(screen.state.film;
        exposure = exp_val,
        tonemap = tm_val,
        gamma = gamma_val,
        sensor = sensor_val
    )

    postprocess_cpu = Array(screen.state.film.postprocess)
    result = map(postprocess_cpu) do c
        RGB{N0f8}(c.r, c.g, c.b)
    end

    return result
end

function Base.display(screen::Screen, scene::Scene; figure = nothing, display_kw...)
    screen.scene = scene
    init_scene!(screen, scene)
    return screen
end

function Base.insert!(screen::Screen, scene::Scene, plot::AbstractPlot)
    isnothing(screen.state) && return screen
    scene_3d = find_3d_scene(scene)
    isnothing(scene_3d) && return screen
    Makie.for_each_atomic_plot(plot) do p
        haskey(p, :trace_renderobject) || draw_atomic(screen, scene_3d, p)
    end
    Raycore.sync!(screen.state.hikari_scene.accel)
    return screen
end

function Base.delete!(screen::Screen, scene::Scene, plot::AbstractPlot)
    isnothing(screen.state) && return
    Makie.for_each_atomic_plot(plot) do p
        delete_trace_robj!(screen, p)
    end
    Raycore.sync!(screen.state.hikari_scene.accel)
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
    activate!()
    return
end

# =============================================================================
# Interactive rendering
# =============================================================================

"""
    render_interactive(mscene; integrator, exposure, tonemap, gamma, sensor, backend)

Start an interactive ray-tracing render loop for a Makie scene.

The render loop continuously updates as the camera moves. Uses progressive rendering
with 1 sample per pixel per frame, accumulating samples over time for noise reduction.
When the camera moves or plot data changes, the film is cleared and accumulation restarts.

Postprocessing parameters (exposure, tonemap, gamma) can be Observables for reactive updates.
"""
function render_interactive(mscene::Makie.Scene;
                            integrator=Hikari.Whitted(samples=1, max_depth=5),
                            exposure=1.0f0, tonemap=:aces, gamma=1.2f0,
                            sensor=nothing, backend=Array)
    exposure_obs = exposure isa Observable ? exposure : Observable(exposure)
    tonemap_obs = tonemap isa Observable ? tonemap : Observable(tonemap)
    gamma_obs = gamma isa Observable ? gamma : Observable(gamma)

    config = ScreenConfig(integrator, Float32(exposure_obs[]), tonemap_obs[], gamma_obs[], sensor, backend)
    screen = Screen(nothing, nothing, config)
    display(screen, mscene)
    state = screen.state
    film = state.film
    camera = state.camera

    imsub = Scene(mscene)
    display_buffer = film.postprocess
    imgp = image!(imsub, -1 .. 1, -1 .. 1, Array(display_buffer), uv_transform=(:rotr90, :flip_y))

    cam_start = camera[]
    loki = Threads.ReentrantLock()
    cam_rendered = camera[]
    running = Threads.Atomic{Bool}(true)

    # Adapt scene once for kernel traversal; re-adapt after topology changes
    ka_backend = if backend === Array
        Raycore.KA.CPU()
    else
        Raycore.KA.get_backend(backend{Float32}(undef, 1))
    end
    adapted_scene = Adapt.adapt(ka_backend, state.hikari_scene)

    root = Makie.rootparent(mscene)
    Base.errormonitor(Threads.@spawn while running[]
        Makie.isclosed(root) && break

        # Poll compute graph for plot data updates
        poll_all_plots(screen, mscene)

        # Sync and refit TLAS (no-ops when clean)
        tlas = get_tlas(state)
        Raycore.sync!(tlas)
        Raycore.refit_tlas!(tlas)

        if state.needs_film_clear
            state.needs_film_clear = false
            # Re-adapt scene after topology changes
            adapted_scene = Adapt.adapt(ka_backend, state.hikari_scene)
            Hikari.clear!(film)
            Hikari.clear!(screen.config.integrator)
            lock(loki) do
                imgp.visible = false
            end
        end

        # Check camera change
        if cam_rendered != camera[]
            cam_rendered = camera[]
            Hikari.clear!(film)
            Hikari.clear!(screen.config.integrator)
            lock(loki) do
                imgp.visible = false
            end
        end

        # Render one iteration/sample
        Hikari.render!(screen.config.integrator, adapted_scene, film, camera[])

        # Apply postprocessing with current observable values
        current_tonemap = tonemap_obs[]
        tonemap_sym = current_tonemap isa Symbol ? current_tonemap : (isnothing(current_tonemap) ? nothing : Symbol(current_tonemap))

        current_sensor = screen.config.sensor
        Hikari.postprocess!(film; exposure=Float32(exposure_obs[]), tonemap=tonemap_sym, gamma=Float32(gamma_obs[]), sensor=current_sensor)

        lock(loki) do
            imgp[3] = Array(film.postprocess)
            imgp.visible = true
        end
        sleep(1/30)
    end)

    Base.errormonitor(Threads.@spawn while running[] && !Makie.isclosed(root)
        lock(loki) do
            if cam_start != camera[]
                cam_start = camera[]
                imgp.visible = false
            end
        end
        sleep(1/30)
    end)

    return (
        running = running,
        screen = screen,
        image = imgp,
    )
end
