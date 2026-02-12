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
* `backend`: KernelAbstractions backend for rendering (default: `KA.CPU()`)
  - `Raycore.KA.CPU()` - CPU rendering
  - `AMDGPU.ROCBackend()` - AMD GPU via AMDGPU.jl
  - `CUDA.CUDABackend()` - NVIDIA GPU via CUDA.jl
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
    backend::Any  # KA backend: KA.CPU(), ROCBackend(), CUDABackend()
    denoise::Bool
    denoise_config::Union{Hikari.DenoiseConfig, Nothing}

    function ScreenConfig(integrator, exposure, tonemap, gamma, sensor, backend=Raycore.KA.CPU(), denoise=false, denoise_config=nothing)
        actual_integrator = integrator isa Makie.Automatic ? Whitted() : integrator
        actual_exposure = Float32(exposure)
        actual_gamma = isnothing(gamma) ? nothing : Float32(gamma)
        actual_backend = backend isa Makie.Automatic ? Raycore.KA.CPU() : backend
        return new(actual_integrator, actual_exposure, tonemap, actual_gamma, sensor, actual_backend, denoise, denoise_config)
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
    scene_states::Vector{TraceMakieState}
    output_buffer::Union{Nothing, AbstractMatrix{RGB{Float32}}}
    config::ScreenConfig

    function Screen(scene, state, config)
        new(scene, state, TraceMakieState[], nothing, config)
    end
end

function Base.show(io::IO, screen::Screen)
    scene_str = isnothing(screen.scene) ? "nothing" : "Scene(\$(size(screen.scene)))"
    backend_name = nameof(typeof(screen.config.backend))
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
    println(io, "  Backend: ", nameof(typeof(screen.config.backend)))
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
    Hikari.free!(state.film)
    return nothing
end

"""
    Base.close(screen::Screen)

Release all GPU resources held by the screen, including the integrator state,
film, and preserved GPU arrays. Call this when done rendering to free GPU memory.
"""
function Base.close(screen::Screen)
    for ss in screen.scene_states
        cleanup!(ss)
    end
    empty!(screen.scene_states)
    screen.state = nothing

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

    screen.config = config
    return screen
end
Base.empty!(::Screen) = nothing

# =============================================================================
# Rendering
# =============================================================================

function render!(screen::Screen)
    state = screen.state
    isnothing(state) && error("Screen not set up - call display first")
    integrator = screen.config.integrator

    # Poll compute graph for updates on this scene's plots
    poll_all_plots(screen, state.makie_scene)
    tlas = get_tlas(state)
    Raycore.sync!(tlas)
    Raycore.refit_tlas!(tlas)

    # Load per-scene integrator state (each scene accumulates independently)
    if integrator isa Hikari.VolPath
        integrator.state = state.integrator_state
    end

    # Clear film and integrator if data changed
    if state.needs_film_clear
        Hikari.clear!(state.film)
        Hikari.clear!(integrator)
        state.needs_film_clear = false
    end

    camera = state.camera[]

    # Fill auxiliary buffers if denoising is enabled (before main render)
    if screen.config.denoise
        adapted_scene = Adapt.adapt(screen.config.backend, state.hikari_scene)
        Hikari.fill_aux_buffers!(state.film, adapted_scene, camera)
    end

    # Render one sample (incremental — accumulates across calls)
    Hikari.render!(integrator, state.hikari_scene, state.film, camera)

    # Save back integrator state (may have been newly created)
    if integrator isa Hikari.VolPath
        state.integrator_state = integrator.state
    end

    return state.film
end

function _postprocess_scene_state!(screen::Screen, scene_state::TraceMakieState)
    screen.state = scene_state
    film = scene_state.film
    camera = scene_state.camera[]
    config = screen.config

    # Convert pixel samples to framebuffer
    if !(config.integrator isa Hikari.VolPath)
        Hikari.to_framebuffer!(film)
    end

    # Adapt scene for kernel traversal (fill_aux_buffers! needs StaticTLAS)
    adapted_scene = Adapt.adapt(config.backend, scene_state.hikari_scene)
    # Fill depth buffer for overlay depth testing
    Hikari.fill_aux_buffers!(film, adapted_scene, camera)

    # Apply denoising if enabled
    if config.denoise
        denoise_cfg = something(config.denoise_config, Hikari.DenoiseConfig())
        Hikari.denoise!(film; config=denoise_cfg)
        copyto!(film.framebuffer, film.postprocess)
    end

    # Postprocess (tonemap, gamma, exposure)
    Hikari.postprocess!(film;
        exposure = config.exposure,
        tonemap = config.tonemap,
        gamma = config.gamma,
        sensor = config.sensor
    )

    # Render overlay plots (lines, scatter, text) via KA kernels
    render_overlays!(screen)

    # Copy to CPU, clamping to [0,1]
    map!(clamp01nan, scene_state.colorbuffer_tmp, film.postprocess)
end

# Postprocess all scenes and composite into output buffer — shared by
# colorbuffer() and interactive_window().
function _postprocess_and_composite!(screen::Screen)
    fill!(screen.output_buffer, RGB{Float32}(0, 0, 0))
    for scene_state in screen.scene_states
        _postprocess_scene_state!(screen, scene_state)
        _composite_scene!(screen.output_buffer, scene_state, screen.scene)
    end
    return Array(screen.output_buffer)
end

@kernel function _composite_kernel!(output, @Const(sub_image),
                                    dst_r0::Int32, dst_c0::Int32,
                                    src_r0::Int32, src_c0::Int32)
    ix, iy = @index(Global, NTuple)
    dr = dst_r0 + Int32(ix) - Int32(1)
    dc = dst_c0 + Int32(iy) - Int32(1)
    sr = src_r0 + Int32(ix) - Int32(1)
    sc = src_c0 + Int32(iy) - Int32(1)
    @inbounds output[dr, dc] = sub_image[sr, sc]
end

function _composite_scene!(output::AbstractMatrix{RGB{Float32}}, scene_state::TraceMakieState, root_scene::Makie.Scene)
    sub_image = scene_state.colorbuffer_tmp
    vp = Makie.viewport(scene_state.makie_scene)[]
    out_h, out_w = size(output)

    vx, vy = vp.origin
    fig_x = max(0f0, vx)
    fig_y = max(0f0, vy)
    vh, vw = size(sub_image)

    col_start = Int(round(fig_x)) + 1
    row_start = out_h - Int(round(fig_y)) - vh + 1

    src_row_off = max(0, 1 - row_start)
    src_col_off = max(0, 1 - col_start)
    dst_r0 = max(1, row_start)
    dst_c0 = max(1, col_start)
    dst_r1 = min(out_h, row_start + vh - 1)
    dst_c1 = min(out_w, col_start + vw - 1)

    (dst_r0 > dst_r1 || dst_c0 > dst_c1) && return

    src_r0 = src_row_off + 1
    src_c0 = src_col_off + 1

    backend = KernelAbstractions.get_backend(output)
    ndrange = (dst_r1 - dst_r0 + 1, dst_c1 - dst_c0 + 1)
    _composite_kernel!(backend)(
        output, sub_image,
        Int32(dst_r0), Int32(dst_c0), Int32(src_r0), Int32(src_c0);
        ndrange=ndrange
    )
    KernelAbstractions.synchronize(backend)
end

function Makie.colorbuffer(screen::Screen, format::Makie.ImageStorageFormat = Makie.JuliaNative; figure = nothing)
    if isempty(screen.scene_states)
        display(screen, screen.scene; figure = figure)
    end

    # Render each scene for the configured number of samples
    for scene_state in screen.scene_states
        screen.state = scene_state
        for _ in 1:screen.config.integrator.samples_per_pixel
            render!(screen)
        end
    end

    # Postprocess + composite (shared path)
    result = _postprocess_and_composite!(screen)
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
    isempty(screen.scene_states) && return screen

    Makie.for_each_atomic_plot(plot) do p
        haskey(p, :trace_renderobject) && return
        pscene = Makie.parent_scene(p)
        for ss in screen.scene_states
            if _scene_contains(ss.makie_scene, pscene)
                screen.state = ss
                draw_atomic(screen, ss.makie_scene, p)
                break
            end
        end
    end

    # Sync all affected TLAS
    for ss in screen.scene_states
        Raycore.sync!(ss.hikari_scene.accel)
    end
    return screen
end

function Base.delete!(screen::Screen, scene::Scene, plot::AbstractPlot)
    isempty(screen.scene_states) && return
    Makie.for_each_atomic_plot(plot) do p
        delete_trace_robj!(screen, p)
    end
    # Don't sync here — sync happens lazily before next render in render!().
    # Syncing during scene teardown would access GPU arrays that may already be freed.
end

# Called from scene finalizer — proactively free GPU resources.
function Base.delete!(screen::Screen, ::Scene)
    for ss in screen.scene_states
        _free_state_gpu!(ss)
    end
    empty!(screen.scene_states)
    screen.state = nothing
end

function _free_state_gpu!(state::TraceMakieState)
    Raycore.free!(state.hikari_scene.accel)
    Hikari.free!(state.film)
    for set in (state.hikari_scene.lights, state.hikari_scene.materials, state.hikari_scene.media)
        set isa Raycore.MultiTypeSet || continue
        Raycore.free!(set)
    end
    finalize(state.hikari_scene.media_interfaces)
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
    interactive_window(scene; integrator, exposure, tonemap, gamma, sensor, backend)

Progressively ray-trace a Makie scene in the background using TraceMakie,
overlaying results onto the interactive display backend (e.g. GLMakie).

The user must activate their display backend (e.g. `GLMakie.activate!()`)
before calling this function.

Returns a NamedTuple `(running, screen, image)`. Set `running[] = false` to stop.
"""
function interactive_window(fig::Makie.Figure; kwargs...)
    return interactive_window(Makie.get_scene(fig); kwargs...)
end

function interactive_window(ax::Makie.LScene; kwargs...)
    return interactive_window(Makie.get_scene(ax); kwargs...)
end

function interactive_window(root_scene::Makie.Scene;
                            integrator=Hikari.VolPath(samples=1, max_depth=5),
                            exposure=1.0f0, tonemap=:aces, gamma=1.2f0,
                            sensor=nothing, backend=Raycore.KA.CPU())

    exposure_obs = convert(Observable, exposure)
    tonemap_obs = convert(Observable, tonemap)
    gamma_obs = convert(Observable, gamma)

    config = ScreenConfig(integrator, Float32(exposure_obs[]), tonemap_obs[], gamma_obs[], sensor, backend)
    screen = Screen(nothing, nothing, config)
    Base.display(screen, root_scene)

    # Create a pixel-camera overlay scene for the ray-traced image
    root_w, root_h = size(root_scene)
    overlay_scene = Makie.Scene(root_scene; camera=Makie.campixel!)
    dummy = fill(RGB{Float32}(0, 0, 0), root_h, root_w)
    imgp = image!(overlay_scene, 0..root_w, 0..root_h, dummy; visible=false, uv_transform=(:rotr90, :flip_y))

    loki = Threads.ReentrantLock()
    running = Threads.Atomic{Bool}(true)

    # Render thread — camera changes are detected via needs_film_clear
    # (set by on(projectionview) callback registered in _create_scene_state)
    Base.errormonitor(Threads.@spawn while running[]
        Makie.isclosed(root_scene) && break

        # Hide overlay if any scene needs clearing (camera moved, data changed)
        if any(ss -> ss.needs_film_clear, screen.scene_states)
            lock(loki) do
                imgp.visible = false
            end
        end

        # Update screen config from reactive observables
        current_tonemap = tonemap_obs[]
        tonemap_sym = current_tonemap isa Symbol ? current_tonemap : (isnothing(current_tonemap) ? nothing : Symbol(current_tonemap))
        screen.config = ScreenConfig(
            config.integrator, Float32(exposure_obs[]),
            tonemap_sym, Float32(gamma_obs[]),
            config.sensor, config.backend, config.denoise, config.denoise_config,
        )

        # Render 1 sample per scene (each scene accumulates independently)
        for ss in screen.scene_states
            screen.state = ss
            render!(screen)
        end

        # Postprocess + composite (same path as colorbuffer)
        result_cpu = _postprocess_and_composite!(screen)

        lock(loki) do
            imgp[3] = result_cpu
            imgp.visible = true
        end

        sleep(1/30)
    end)

    return (
        running = running,
        screen = screen,
        image = imgp,
    )
end
