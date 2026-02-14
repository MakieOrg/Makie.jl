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

* `integrator`: The integrator to use for rendering (default: `VolPath()`)
  - `VolPath(; samples_per_pixel=64, max_depth=8)` - Volumetric path tracing
  - `FastWavefront(; samples=4)` - GPU-optimized wavefront path tracing
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
        actual_integrator = integrator isa Makie.Automatic ? VolPath() : integrator
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

function Base.resize!(screen::Screen, w::Int, h::Int)
    (w > 0 && h > 0) || return nothing
    isnothing(screen.scene) && return nothing
    isempty(screen.scene_states) && return nothing

    ka_backend = screen.config.backend

    for state in screen.scene_states
        cleanup!(state)

        if state.overlay_only || state.makie_scene === screen.scene
            # Overlay or scene IS the root — use full size, no viewport clipping
            resolution = Point2f(Float32(w), Float32(h))
            screen_window = nothing
        else
            resolution, screen_window = _compute_scene_resolution(state.makie_scene, w, h)
        end

        film = Hikari.Film(resolution;
            filter=Hikari.LanczosSincFilter(Point2f(1.0f0), 3.0f0),
            crop_bounds=Hikari.Bounds2(Point2f(0.0f0), Point2f(1.0f0)),
            diagonal=1.0f0, scale=1.0f0)
        film = Raycore.Adapt.adapt(ka_backend, film)

        state.film = film
        state.colorbuffer_tmp = similar(film.postprocess)
        state.overlay_buffer = Overlay.create_overlay_buffer(ka_backend, size(film.framebuffer))

        if !state.overlay_only && !isnothing(state.camera)
            state.camera = to_trace_camera(state.makie_scene, film; screen_window)
        end

        state.integrator_state = nothing
        state.needs_film_clear = true
    end

    screen.output_buffer = KernelAbstractions.allocate(ka_backend, RGB{Float32}, h, w)
    return nothing
end

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

    # Skip ray tracing for overlay-only states
    state.overlay_only && return state.film

    integrator = screen.config.integrator

    # Poll compute graph for updates on this scene's plots
    poll_all_plots(screen, state.makie_scene)
    tlas = get_tlas(state)
    Raycore.sync!(tlas)

    # Skip ray tracing if TLAS has no geometry (e.g. scene with only overlay plots)
    if isempty(tlas.instances)
        return state.film
    end

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
    config = screen.config

    if scene_state.overlay_only
        # Overlay-only: fill postprocess with scene background color, set depth to max
        bg = scene_state.makie_scene.backgroundcolor[]
        bg_rgb = RGB{Float32}(bg)
        fill!(film.postprocess, bg_rgb)
        fill!(film.depth, Float32(1e30))  # all overlays pass depth test

        # Poll compute graph for overlay data
        poll_all_plots(screen, scene_state.makie_scene)

        # Render overlay plots
        render_overlays!(screen)

        # Copy to CPU
        map!(clamp01nan, scene_state.colorbuffer_tmp, film.postprocess)
        return
    end

    camera = scene_state.camera[]

    # Convert pixel samples to framebuffer
    if !(config.integrator isa Hikari.VolPath)
        Hikari.to_framebuffer!(film)
    end

    # Fill depth buffer for overlay depth testing (skip if no geometry)
    tlas = scene_state.hikari_scene.accel
    if !isempty(tlas.instances)
        lights = scene_state.hikari_scene.lights
        has_inf = any(T -> Hikari.is_infinite_light(T), lights.data_order)
        adapted_scene = Adapt.adapt(config.backend, scene_state.hikari_scene)
        Hikari.fill_aux_buffers!(film, adapted_scene, camera; has_infinite_lights=has_inf)
    else
        fill!(film.depth, Float32(1e30))  # all overlays pass depth test
    end

    # Apply denoising if enabled
    if config.denoise
        denoise_cfg = something(config.denoise_config, Hikari.DenoiseConfig())
        Hikari.denoise!(film; config=denoise_cfg)
        copyto!(film.framebuffer, film.postprocess)
    end

    # Postprocess (tonemap, gamma, exposure)
    # Mask escaped rays with root scene background color so compositor shows through
    root_bg = screen.scene.backgroundcolor[]
    bg_rgb = RGB{Float32}(red(root_bg), green(root_bg), blue(root_bg))
    Hikari.postprocess!(film;
        exposure = config.exposure,
        tonemap = config.tonemap,
        gamma = config.gamma,
        sensor = config.sensor,
        background = bg_rgb,
    )

    # Render overlay plots (lines, scatter, text) via KA kernels
    render_overlays!(screen)

    # Copy to CPU, clamping to [0,1]
    map!(clamp01nan, scene_state.colorbuffer_tmp, film.postprocess)
end

# Postprocess all scenes and composite into output buffer — shared by
# colorbuffer() and interactive_window().
function _postprocess_and_composite!(screen::Screen)
    bg = screen.scene.backgroundcolor[]
    fill!(screen.output_buffer, RGB{Float32}(red(bg), green(bg), blue(bg)))
    for scene_state in screen.scene_states
        _postprocess_scene_state!(screen, scene_state)
        _composite_scene!(screen.output_buffer, scene_state, screen.scene)
    end

    # Render overlays for scenes not covered by any renderable scene state
    # (e.g. Axis3 blockscene decorations: ticks, labels, grid lines).
    renderable = [s.makie_scene for s in screen.scene_states if !s.overlay_only]
    if !isempty(renderable)
        uncovered = _find_uncovered_overlay_scenes(screen.scene, renderable)
        if !isempty(uncovered)
            _render_uncovered_overlays!(screen, uncovered)
        end
    end

    return Array(screen.output_buffer)
end

# Render overlay plots from scenes not covered by any renderable scene state
# into a root-sized overlay buffer and composite onto output_buffer.
function _render_uncovered_overlays!(screen::Screen, uncovered_scenes)
    output = screen.output_buffer
    root_scene = screen.scene
    root_w, root_h = size(root_scene)
    root_res = Vec2f(Float32(root_w), Float32(root_h))
    ka_backend = screen.config.backend

    # Root-sized overlay and depth buffers
    overlay_buf = Overlay.create_overlay_buffer(ka_backend, (root_h, root_w))
    depth_buf = KernelAbstractions.allocate(ka_backend, Float32, root_h, root_w)
    fill!(depth_buf, Float32(1e30))

    # Transfer depth from each renderable scene state into root depth buffer
    # so uncovered overlays are properly occluded by ray-traced geometry.
    for scene_state in screen.scene_states
        scene_state.overlay_only && continue
        _blit_depth_to_root!(depth_buf, scene_state, root_scene, ka_backend)
    end

    has_overlay = Ref(false)
    gpu_atlas_ref = Ref{Any}(nothing)
    atlas_w_ref = Ref{Int32}(Int32(0))
    atlas_h_ref = Ref{Int32}(Int32(0))

    for uscene in uncovered_scenes
        poll_all_plots(screen, uscene)
        ctx = _create_raster_context_remapped(uscene, root_res)
        remap = _compute_viewport_remap(uscene, root_res)
        _render_scene_overlay_plots!(
            overlay_buf, depth_buf, ctx, uscene, remap,
            gpu_atlas_ref, atlas_w_ref, atlas_h_ref, has_overlay,
        )
    end

    if has_overlay[]
        Overlay.composite!(output, overlay_buf)
    end
end

# Copy a renderable scene's film depth buffer into the root-sized depth buffer
# at the correct viewport position.
@kernel function _blit_depth_kernel!(dst, @Const(src),
                                     dst_r0::Int32, dst_c0::Int32,
                                     src_r0::Int32, src_c0::Int32)
    ix, iy = @index(Global, NTuple)
    dr = dst_r0 + Int32(ix) - Int32(1)
    dc = dst_c0 + Int32(iy) - Int32(1)
    sr = src_r0 + Int32(ix) - Int32(1)
    sc = src_c0 + Int32(iy) - Int32(1)
    @inbounds dst[dr, dc] = src[sr, sc]
end

function _blit_depth_to_root!(root_depth, scene_state, root_scene, backend)
    src_depth = scene_state.film.depth
    out_h, out_w = size(root_depth)
    vh, vw = size(src_depth)

    if scene_state.makie_scene === root_scene
        col_start = 1
        row_start = 1
    else
        vp = Makie.viewport(scene_state.makie_scene)[]
        vx, vy = vp.origin
        fig_x = max(0f0, Float32(vx))
        fig_y = max(0f0, Float32(vy))
        col_start = Int(round(fig_x)) + 1
        row_start = out_h - Int(round(fig_y)) - vh + 1
    end

    src_row_off = max(0, 1 - row_start)
    src_col_off = max(0, 1 - col_start)
    dst_r0 = max(1, row_start)
    dst_c0 = max(1, col_start)
    dst_r1 = min(out_h, row_start + vh - 1)
    dst_c1 = min(out_w, col_start + vw - 1)

    (dst_r0 > dst_r1 || dst_c0 > dst_c1) && return

    ndrange = (dst_r1 - dst_r0 + 1, dst_c1 - dst_c0 + 1)
    _blit_depth_kernel!(backend)(
        root_depth, src_depth,
        Int32(dst_r0), Int32(dst_c0),
        Int32(src_row_off + 1), Int32(src_col_off + 1);
        ndrange=ndrange,
    )
    KernelAbstractions.synchronize(backend)
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
    out_h, out_w = size(output)
    vh, vw = size(sub_image)

    if scene_state.makie_scene === root_scene
        # Scene IS the root — no viewport offset needed
        col_start = 1
        row_start = 1
    else
        vp = Makie.viewport(scene_state.makie_scene)[]
        vx, vy = vp.origin
        fig_x = max(0f0, Float32(vx))
        fig_y = max(0f0, Float32(vy))
        col_start = Int(round(fig_x)) + 1
        row_start = out_h - Int(round(fig_y)) - vh + 1
    end

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
    imgp = image!(overlay_scene, 0..root_w, 0..root_h, dummy; visible=false, uv_transform=(:rotr90, :flip_y), overdraw=true)

    last_root_size = Ref((root_w, root_h))
    running = Threads.Atomic{Bool}(true)

    # Render thread — detects viewport changes and camera changes each frame
    Base.errormonitor(Threads.@spawn while running[]
        Makie.isclosed(root_scene) && break

        # Detect viewport resize (same pattern as GLMakie's render_frame)
        cur_w, cur_h = size(root_scene)
        if (cur_w, cur_h) != last_root_size[]
            last_root_size[] = (cur_w, cur_h)
            resize!(screen, cur_w, cur_h)
            imgp[1] = 0..cur_w
            imgp[2] = 0..cur_h
            imgp.visible = false
        end

        # Hide overlay if any scene needs clearing (camera moved, data changed)
        if any(ss -> ss.needs_film_clear, screen.scene_states)
            imgp.visible = false
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
        imgp[3] = result_cpu
        imgp.visible = true

        sleep(1/30)
    end)

    return (
        running = running,
        screen = screen,
        image = imgp,
    )
end
