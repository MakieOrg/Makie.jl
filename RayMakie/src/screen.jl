# =============================================================================
# ScreenConfig
# =============================================================================

# Re-export integrators from Hikari for convenience
const FastWavefront = Hikari.FastWavefront
const VolPath = Hikari.VolPath

"""
    ScreenConfig

Configuration for RayMakie rendering.

* `integrator`: The integrator to use for rendering (default: `VolPath()`)
  - `VolPath(; samples=64, max_depth=8)` - Volumetric path tracing
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
* `device`: KernelAbstractions backend for rendering (default: `KA.CPU()`)
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
    device::Any  # KA backend: KA.CPU(), ROCBackend(), CUDABackend()
    denoise::Bool
    denoise_config::Union{Hikari.DenoiseConfig, Nothing}

    function ScreenConfig(integrator, exposure, tonemap, gamma, sensor, device=Raycore.KA.CPU(), denoise=false, denoise_config=nothing)
        actual_integrator = integrator isa Makie.Automatic ? VolPath(; hw_accel=true) : integrator
        actual_exposure = Float32(exposure)
        actual_gamma = isnothing(gamma) ? nothing : Float32(gamma)
        actual_device = device isa Makie.Automatic ? Lava.LavaBackend() : device
        return new(actual_integrator, actual_exposure, tonemap, actual_gamma, sensor, actual_device, denoise, denoise_config)
    end
end

# =============================================================================
# Screen
# =============================================================================

"""
    Screen <: Makie.MakieScreen

RayMakie screen for ray-traced rendering.

# Constructors

    Screen(scene::Scene; screen_config...)
    Screen(scene::Scene, config::ScreenConfig)

# Configuration options (via screen_config or ScreenConfig):

\$(Base.doc(ScreenConfig))
"""
mutable struct Screen <: Makie.MakieScreen
    scene::Union{Nothing, Scene}
    state::Union{Nothing, RayMakieState}
    scene_states::Vector{RayMakieState}
    output_buffer::Union{Nothing, AbstractMatrix{RGBA{Float32}}}
    config::ScreenConfig
    # Render loop (vulkan_viewer)
    window::Any                 # Nothing or Lava.RenderWindow
    rendertask::Union{Nothing, Task}
    stop_renderloop::Threads.Atomic{Bool}
    last_colorbuffer::Union{Nothing, Matrix{RGB{N0f8}}}
    # Cached state for uncovered overlay rendering
    uncovered_state::Union{Nothing, RayMakieState}
    # Per-screen overlay caches
    cached_atlas::Any
    cached_atlas_size::Int
    overlay_fb::Any
    overlay_fb_size::Tuple{Int,Int}
    gfx_atlas_tex::Any
    gfx_atlas_sampler::Any
    gfx_atlas_bindings::Any
    gfx_atlas_size::Int
    fb_readback_buf::Any
    # Per-screen graphics BatchQueue — isolated from compute/transfer
    gfx_bq::Any  # Lava.BatchQueue
    # Per-screen graphics pipeline cache (no globals!)
    gfx_pipelines::Dict{Symbol, GraphicsPipeline}

    function Screen(scene, state, config)
        s = new(scene, state, RayMakieState[], nothing, config,
                nothing, nothing, Threads.Atomic{Bool}(false), nothing,  # window, rendertask, stop, last_colorbuffer
                nothing,           # uncovered_state
                nothing, 0,        # cached_atlas
                nothing, (0, 0),   # overlay_fb
                nothing, nothing, nothing, 0,  # gfx_atlas
                nothing,           # fb_readback_buf
                nothing,           # gfx_bq
                Dict{Symbol, GraphicsPipeline}()) # gfx_pipelines
        # Only set the stop flag from the finalizer — never wait on tasks or
        # touch GLFW from GC (runs during allocation, can't yield or call C libs safely).
        finalizer(s -> (s.stop_renderloop[] = true), s)
        return s
    end
end

Base.wait(screen::Screen) = !isnothing(screen.rendertask) && wait(screen.rendertask)

"""Get or create the screen's dedicated graphics BatchQueue."""
function get_gfx_bq!(screen::Screen)
    if screen.gfx_bq === nothing
        screen.gfx_bq = Lava.allocate_batch_queue!()
    end
    return screen.gfx_bq::Lava.BatchQueue
end

function renderloop_running(screen::Screen)
    return !screen.stop_renderloop[] && !isnothing(screen.rendertask) && !istaskdone(screen.rendertask)
end

function Base.show(io::IO, screen::Screen)
    scene_str = isnothing(screen.scene) ? "nothing" : "Scene(\$(size(screen.scene)))"
    device_name = nameof(typeof(screen.config.device))
    integrator_name = nameof(typeof(screen.config.integrator))
    print(io, "Screen(\$scene_str, device=\$device_name, integrator=\$integrator_name)")
end

function Base.show(io::IO, ::MIME"text/plain", screen::Screen)
    println(io, "RayMakie.Screen")
    if !isnothing(screen.scene)
        println(io, "  Scene size: ", size(screen.scene))
    else
        println(io, "  Scene: not attached")
    end
    println(io, "  Device: ", nameof(typeof(screen.config.device)))
    println(io, "  Integrator: ", nameof(typeof(screen.config.integrator)))
    print(io, "  Exposure: ", screen.config.exposure)
end

Base.size(screen::Screen) = isnothing(screen.scene) ? (0, 0) : size(screen.scene)

function Base.resize!(screen::Screen, w::Int, h::Int)
    (w > 0 && h > 0) || return nothing
    isnothing(screen.scene) && return nothing
    isempty(screen.scene_states) && return nothing

    ka_backend = screen.config.device

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

        if !state.overlay_only && !isnothing(state.camera)
            state.camera = to_trace_camera(state.makie_scene, film; screen_window)
        end

        state.integrator_state = nothing
        state.needs_film_clear = true
    end

    screen.output_buffer = KernelAbstractions.allocate(ka_backend, RGBA{Float32}, h, w)
    return nothing
end

# Flush GPU deferred frees — Lava-specific, no-op for other backends
function flush_gpu!()
    lava = get(Base.loaded_modules, Base.PkgId(Base.UUID("dab5e104-5754-42e4-af51-5044c2e3a8e0"), "Lava"), nothing)
    lava === nothing && return
    try
        getfield(lava, :vk_flush!)()
        getfield(lava, :flush_deferred_frees!)()
    catch
    end
end

function Base.isopen(screen::Screen)
    return screen.state !== nothing
end

function cleanup!(state::RayMakieState)
    Hikari.free!(state.film)

    # Free integrator state (work queues, pixel buffers — bulk of GPU memory)
    if state.integrator_state !== nothing
        Hikari.free!(state.integrator_state)
        state.integrator_state = nothing
    end

    finalize(state.depth_flipped)

    return nothing
end

"""
    Base.close(screen::Screen)

Release all GPU resources held by the screen, including the integrator state,
film, and preserved GPU arrays. Call this when done rendering to free GPU memory.
"""
function Base.close(screen::Screen)
    # Stop render loop if running
    screen.stop_renderloop[] = true
    if screen.rendertask !== nothing && !istaskdone(screen.rendertask)
        try wait(screen) catch end
        screen.rendertask = nothing
    end
    # Close GLFW window if open
    if screen.window !== nothing
        try
            isopen(screen.window) && close(screen.window)
        catch end
        screen.window = nothing
    end
    # Idempotent — safe to call from explicit close
    isempty(screen.scene_states) && screen.state === nothing && return nothing

    # Step 1: Mark all states as closed FIRST — prevents delete_trace_robj! from
    # resolving Observables (which triggers ComputePipeline re-evaluation on freed GPU data)
    for ss in screen.scene_states
        ss.closed = true
    end

    # Step 2: Free ALL GPU resources — both integrator/film (cleanup!) and
    # hikari scene data (TLAS, materials, lights, media via _free_state_gpu!)
    for ss in screen.scene_states
        cleanup!(ss)
        if ss.hikari_scene !== nothing
            _free_state_gpu!(ss)
        end
    end
    empty!(screen.scene_states)
    screen.state = nothing

    # Free the output buffer and cached overlay buffers
    if screen.output_buffer !== nothing
        finalize(screen.output_buffer)
        screen.output_buffer = nothing
    end
    # uncovered_overlay_buf and uncovered_depth_buf were removed from Screen struct

    close(screen.config.integrator)

    # Flush deferred frees so GPU memory is actually released now
    flush_gpu!()

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
    if screen.config.device !== config.device
        return Screen(scene, config)
    end

    old_int = screen.config.integrator
    new_int = config.integrator

    # If the integrator object changed, close the old one's caches and mark dirty
    if old_int !== new_int
        close(old_int)
        for ss in screen.scene_states
            ss.integrator_state = nothing
            ss.needs_film_clear = true
        end
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
        adapted_scene = Adapt.adapt(screen.config.device, state.hikari_scene)
        Hikari.fill_aux_buffers!(state.film, adapted_scene, camera)
    end

    # Render: VolPath uses render!() for one sample, SamplerIntegrators use functor call
    if integrator isa Hikari.VolPath
        Hikari.render!(integrator, state.hikari_scene, state.film, camera)
        # Save back integrator state (may have been newly created)
        state.integrator_state = integrator.state
    else
        integrator(state.hikari_scene, state.film, camera)
    end

    return state.film
end

function _postprocess_scene_state!(screen::Screen, scene_state::RayMakieState)
    screen.state = scene_state
    film = scene_state.film
    config = screen.config

    if scene_state.overlay_only
        # Overlay-only: fill postprocess with scene background color, set depth to max
        bg = scene_state.makie_scene.backgroundcolor[]
        fill!(film.postprocess, RGBA{Float32}(red(bg), green(bg), blue(bg), 1f0))
        fill!(film.depth, Float32(1e30))  # all overlays pass depth test

        # Poll compute graph for overlay data
        poll_all_plots(screen, scene_state.makie_scene)

        # Overlay rendering is done separately via render_overlays_to_target!
        # after the output_buffer is blitted to the window.
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
        # Use cached adapted scene from VolPath integrator (avoids re-uploading ~30 MiB per render)
        integrator = config.integrator
        cached = integrator isa Hikari.VolPath ? integrator._adapted_scene_cache : nothing
        if cached !== nothing
            adapted_scene = cached[2]
        else
            adapted_scene = Adapt.adapt(config.device, scene_state.hikari_scene)
        end
        Hikari.fill_aux_buffers!(film, adapted_scene, camera; has_infinite_lights=has_inf)
    else
        fill!(film.depth, Float32(1e30))  # all overlays pass depth test
    end

    # Apply denoising if enabled
    if config.denoise
        denoise_cfg = something(config.denoise_config, Hikari.DenoiseConfig())
        Hikari.denoise!(film; config=denoise_cfg)
        film.framebuffer .= RGB{Float32}.(film.postprocess)
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

    # NOTE: Overlay rendering for 3D renderable scenes is intentionally skipped.
    # The axis3D decorations (grid lines, spines) project through 3D perspective
    # but lack depth testing against the raytraced geometry, causing opaque bands.
    # These decorations are part of the 3D scene and render correctly via raytracing
    # wireframe. Overlay-only scenes (2D Axis) handle overlays in their own path.

    # postprocess already writes clamped RGBA{Float32} — no extra copy needed
end

# Postprocess all scenes and composite into output buffer — shared by
# colorbuffer() and interactive_window().
function _postprocess_and_composite!(screen::Screen)
    bg = screen.scene.backgroundcolor[]
    fill!(screen.output_buffer, RGBA{Float32}(red(bg), green(bg), blue(bg), 1f0))
    for scene_state in screen.scene_states
        _postprocess_scene_state!(screen, scene_state)
        _composite_scene!(screen.output_buffer, scene_state, screen.scene)
    end

    return Array(screen.output_buffer)
end

# GPU-only variant: same as _postprocess_and_composite! but skips the CPU download.
# Returns the GPU output_buffer directly (no Array() copy).
function _postprocess_and_composite_gpu!(screen::Screen)
    bg = screen.scene.backgroundcolor[]
    fill!(screen.output_buffer, RGBA{Float32}(red(bg), green(bg), blue(bg), 1f0))
    for scene_state in screen.scene_states
        _postprocess_scene_state!(screen, scene_state)
        _composite_scene!(screen.output_buffer, scene_state, screen.scene)
    end
    # Sync after postprocess+composite to keep batch sizes manageable
    KernelAbstractions.synchronize(screen.config.device)

    return screen.output_buffer
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

@kernel function _scene_composite_kernel!(output, @Const(sub_image),
                                    dst_r0::Int32, dst_c0::Int32,
                                    src_r0::Int32, src_c0::Int32)
    ix, iy = @index(Global, NTuple)
    dr = dst_r0 + Int32(ix) - Int32(1)
    dc = dst_c0 + Int32(iy) - Int32(1)
    sr = src_r0 + Int32(ix) - Int32(1)
    sc = src_c0 + Int32(iy) - Int32(1)
    @inbounds output[dr, dc] = sub_image[sr, sc]
end

function _composite_scene!(output::AbstractMatrix{RGBA{Float32}}, scene_state::RayMakieState, root_scene::Makie.Scene)
    sub_image = scene_state.film.postprocess
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
    _scene_composite_kernel!(backend)(
        output, sub_image,
        Int32(dst_r0), Int32(dst_c0), Int32(src_r0), Int32(src_c0);
        ndrange=ndrange
    )
    KernelAbstractions.synchronize(backend)
end

function Makie.colorbuffer(screen::Screen, format::Makie.ImageStorageFormat = Makie.JuliaNative; figure = nothing, clear=true)
    if isempty(screen.scene_states)
        display(screen, screen.scene; figure = figure)
    end

    # If the render loop is running (vulkan_viewer), return the last composited frame.
    # The render loop updates screen.last_colorbuffer each frame.
    if renderloop_running(screen)
        buf = screen.last_colorbuffer
        buf !== nothing && return format == Makie.GLNative ? Makie.jl_to_gl_format(buf) : buf
        # No frame yet — fall through to render one
    end

    # Render each scene for the configured number of samples
    # VolPath uses an outer loop (each render! = 1 sample), while SamplerIntegrators
    # (Whitted etc.) handle all samples internally in a single render! call.
    integrator = screen.config.integrator
    samples = integrator.samples_per_pixel
    for scene_state in screen.scene_states
        screen.state = scene_state
        # Always clear film at the start of colorbuffer — ensures correct accumulation
        if clear
            scene_state.needs_film_clear = true
        end
        for i in 1:samples
            render!(screen)
            # Synchronize every 8 samples to prevent command buffer overflow.
            # Each sample generates ~170 dispatches; without sync, a 64-sample
            # render accumulates 11K+ dispatches → GPU timeout → DEVICE_LOST.
            if i % 8 == 0 && i < samples
                KernelAbstractions.synchronize(screen.config.device)
            end
        end
    end
    # Postprocess + composite into output_buffer
    _postprocess_and_composite_gpu!(screen)
    Lava.vk_flush!()
    Lava.Vulkan.device_wait_idle(Lava.vk_context().device)

    # Blit to a temporary window, render overlays on top, readback
    w, h = size(screen.output_buffer, 2), size(screen.output_buffer, 1)
    win = Lava.RenderWindow(w, h; title="colorbuffer", vsync=false)
    bq = get_gfx_bq!(screen)
    Lava.acquire_next_image!(win)
    Lava.blit!(bq, Lava.WindowTarget(win), screen.output_buffer; clear=false)
    for scene_state in screen.scene_states
        screen.state = scene_state
        poll_all_plots(screen, scene_state.makie_scene)
        render_overlays!(screen, bq, Lava.WindowTarget(win))
    end
    Lava.flush!(bq, Lava.vk_device())
    Lava.Vulkan.device_wait_idle(Lava.vk_context().device)

    # Readback swapchain image (BGRA bytes)
    pixels = Lava.readback_window(win)
    close(win)

    # Convert BGRA UInt8 tuples → RGBA{Float32} matrix (row-major → column-major)
    result = Matrix{RGBA{Float32}}(undef, h, w)
    for col in 1:w, row in 1:h
        p = pixels[col, row]
        result[row, col] = RGBA{Float32}(p[3]/255f0, p[2]/255f0, p[1]/255f0, p[4]/255f0)
    end

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
        Hikari.sync!(ss.hikari_scene)
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
# Guard: only tear down if the finalized scene matches the screen's current scene.
# A stale scene finalizer (e.g. the temporary Scene() from the Screen constructor)
# must not destroy the active scene state during init_scene!.
function Base.delete!(screen::Screen, scene::Scene)
    screen.scene === scene || return
    for ss in screen.scene_states
        ss.closed && continue  # Already freed by close(screen)
        ss.closed = true
        cleanup!(ss)           # Free integrator state, colorbuffer, overlay, depth
        _free_state_gpu!(ss)   # Free hikari scene (TLAS, materials, lights, media)
    end
    empty!(screen.scene_states)
    screen.state = nothing
    # Also close the integrator to free its caches
    close(screen.config.integrator)
    # Flush deferred frees so GPU memory is actually released
    # (this can be called from Scene GC finalizer via @async)
    flush_gpu!()
end

function _free_state_gpu!(state::RayMakieState)
    state.hikari_scene === nothing && return
    Raycore.free!(state.hikari_scene.accel)
    Hikari.free!(state.film)
    for set in (state.hikari_scene.lights, state.hikari_scene.materials, state.hikari_scene.media)
        set isa Raycore.MultiTypeSet || continue
        Raycore.free!(set)
    end
    finalize(state.hikari_scene.media_interfaces)
    state.hikari_scene = nothing
end

Makie.backend_showable(::Type{Screen}, ::Union{MIME"image/jpeg", MIME"image/png"}) = true

# =============================================================================
# Backend activation
# =============================================================================

"""
    RayMakie.activate!(; screen_config...)

Sets RayMakie as the currently active backend and allows setting screen configuration.

# Arguments (via screen_config):

\$(Base.doc(ScreenConfig))

# Examples

```julia
# Use default VolPath integrator
RayMakie.activate!()

# Use VolPath with custom settings
RayMakie.activate!(integrator = RayMakie.VolPath(samples=16, max_depth=8))

# Configure postprocessing
RayMakie.activate!(exposure = 1.5, tonemap = :reinhard, gamma = 2.2)
```
"""
function activate!(; screen_config...)
    if !isempty(screen_config)
        Makie.set_screen_config!(RayMakie, screen_config)
    end
    Makie.set_active_backend!(RayMakie)
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
    interactive_window(scene; integrator, exposure, tonemap, gamma, sensor, device)

Progressively ray-trace a Makie scene in the background using RayMakie,
overlaying results onto the interactive display backend (e.g. GLMakie).

The user must activate their display backend (e.g. `GLMakie.activate!()`)
before calling this function.

Returns a NamedTuple `(running, screen, image)`. Set `running[] = false` to stop.
"""
function interactive_window(fig::Makie.FigureLike; kwargs...)
    return interactive_window(Makie.get_scene(fig); kwargs...)
end

function interactive_window(
    root_scene::Makie.Scene; integrator=Hikari.VolPath(; samples=1, max_depth=5, hw_accel=true)
)
    screen = Base.display(root_scene; integrator=integrator, backend=RayMakie)
    # Create a pixel-camera overlay scene for the ray-traced image
    root_w, root_h = size(root_scene)
    overlay_scene = Makie.Scene(root_scene)
    dummy = colorbuffer(screen)
    imgp = image!(overlay_scene, -1..1, -1..1, dummy; visible=true, uv_transform=(:rotr90, :flip_y), overdraw=true)
    # translate!(imgp, 0, 0, 10000)
    last_root_size = Ref((root_w, root_h))
    running = Threads.Atomic{Bool}(true)
    # Render thread — detects viewport changes and camera changes each frame
    Base.errormonitor(Threads.@spawn while running[]
        @show Makie.isclosed(root_scene)
        Makie.isclosed(root_scene) && break
        # Detect viewport resize (same pattern as GLMakie's render_frame)
        cur_w, cur_h = size(root_scene)
        if (cur_w, cur_h) != last_root_size[]
            last_root_size[] = (cur_w, cur_h)
            resize!(screen, cur_w, cur_h)
            # imgp.visible = false
        end
        # Update screen config from reactive observables
        # Postprocess + composite (same path as colorbuffer)
        result_cpu = @time colorbuffer(screen; clear=false)
        imgp[3] = result_cpu
        imgp.visible = true
        sleep(0.001)
    end)

    return (
        running = running,
        screen = screen,
        image = imgp,
    )
end
