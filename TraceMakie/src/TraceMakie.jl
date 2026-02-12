module TraceMakie

using Makie, Hikari, Colors, LinearAlgebra, GeometryBasics, Raycore, KernelAbstractions
using Makie: Observable, on, colorbuffer, to_value
using Makie: Quaternionf
using GeometryBasics: VecTypes
using Colors: N0f8
using ImageCore: RGBA, RGB, clamp01nan
import Makie.Observables
using Adapt
using Makie.ComputePipeline: register_computation!

# Include Overlay rasterization module
include("overlay/Overlay.jl")
using .Overlay

# Debug: capture overlay buffer for inspection
const DEBUG_OVERLAY = Ref{Any}(nothing)

# =============================================================================
# TraceMakieState
# =============================================================================

mutable struct TraceMakieState
    makie_scene::Makie.Scene
    film::Hikari.Film
    camera::Observable
    hikari_scene::Hikari.AbstractScene
    needs_film_clear::Bool
    # Pre-allocated buffer for clamp01nan in colorbuffer (avoids per-frame GPU alloc)
    colorbuffer_tmp::AbstractMatrix{RGB{Float32}}
    # Overlay system for lines, scatter, text (on KA backend)
    overlay_buffer::AbstractMatrix{RGBA{Float32}}
    # Pre-allocated flipped depth buffer for overlay rendering
    depth_flipped::AbstractMatrix{Float32}
    # Per-scene integrator state (e.g. VolPathState) — each scene accumulates independently
    integrator_state::Any
end

# Helper to get TLAS from state
get_tlas(state::TraceMakieState) = state.hikari_scene.accel

# =============================================================================
# Plot conversion helpers (shared across plot types)
# =============================================================================

include("plots/common.jl")

# =============================================================================
# Scene initialization and polling
# =============================================================================

"""
    collect_renderable_scenes(scene::Makie.Scene) -> Vector{Makie.Scene}

Walk the scene tree and return all scenes that have a 3D camera (not PixelCamera
or EmptyCamera) and contain at least one atomic plot in their subtree.
Each returned scene gets its own ray-tracing state (Film, TLAS, camera).
"""
function collect_renderable_scenes(scene::Makie.Scene)
    result = Makie.Scene[]
    _collect_renderable!(result, scene)
    return result
end

function _is_3d_camera(cc)
    return !(cc isa Makie.PixelCamera || cc isa Makie.EmptyCamera)
end

function _has_atomic_plots(scene::Makie.Scene)
    found = Ref(false)
    Makie.for_each_atomic_plot(scene) do _
        found[] = true
    end
    return found[]
end

function _collect_renderable!(result, scene::Makie.Scene)
    if _is_3d_camera(scene.camera_controls) && _has_atomic_plots(scene)
        push!(result, scene)
        # Don't recurse into children — they're covered by for_each_atomic_plot
        return
    end
    for child in scene.children
        _collect_renderable!(result, child)
    end
end

# Check if target is the same scene or a descendant of parent
function _scene_contains(parent::Makie.Scene, target::Makie.Scene)
    parent === target && return true
    for child in parent.children
        _scene_contains(child, target) && return true
    end
    return false
end

"""
    build_materials_tuple(materials_list::Vector) -> Tuple

Group materials by type into a tuple of vectors for MaterialScene.
"""
function build_materials_tuple(materials_list::Vector)
    if isempty(materials_list)
        return (Hikari.MatteMaterial[],)
    end

    type_to_materials = Dict{DataType, Vector}()
    type_order = DataType[]

    for mat in materials_list
        T = typeof(mat)
        if !haskey(type_to_materials, T)
            type_to_materials[T] = T[]
            push!(type_order, T)
        end
        push!(type_to_materials[T], mat)
    end

    return Tuple([type_to_materials[T] for T in type_order])
end

# =============================================================================
# Light conversion
# =============================================================================

# Whether an integrator uses spectral light transport (needs photometric normalization)
_is_spectral_integrator(::Hikari.VolPath) = true
_is_spectral_integrator(::Hikari.Integrator) = false

function to_trace_light(light::Makie.AmbientLight, integrator)
    color = light.color isa Observable ? light.color[] : light.color
    rgb = RGB{Float32}(RGBf(color))
    if _is_spectral_integrator(integrator)
        return Hikari.AmbientLight(rgb)
    else
        return Hikari.AmbientLight(Hikari.RGBSpectrum(rgb.r, rgb.g, rgb.b))
    end
end

function to_trace_light(light::Makie.PointLight, integrator)
    c = RGBf(light.color)
    if _is_spectral_integrator(integrator)
        # Spectral path: PointLight(RGB{Float32}, position) creates RGBIlluminantSpectrum
        # with photometric normalization (scale = 1/spectrum_to_photometric), matching pbrt-v4
        return Hikari.PointLight(RGB{Float32}(c.r, c.g, c.b), Vec3f(light.position))
    else
        # RGB path: direct RGBSpectrum intensity for Whitted/SPPM/FastWavefront
        i = Hikari.RGBSpectrum(c.r, c.g, c.b)
        return Hikari.PointLight(Raycore.translate(Vec3f(light.position)), i, 1f0)
    end
end

function to_trace_light(light::Makie.SunSkyLight, integrator)
    ground_albedo = Hikari.RGBSpectrum(light.ground_albedo.r, light.ground_albedo.g, light.ground_albedo.b)
    if _is_spectral_integrator(integrator)
        # Spectral path: pre-bake sky to EnvironmentLight + separate SunLight (pbrt-v4 approach).
        # Returns a tuple — caller handles pushing both lights.
        return Hikari.sunsky_to_envlight(
            direction=Vec3f(light.direction),
            intensity=Float32(light.intensity),
            turbidity=light.turbidity,
            ground_albedo=ground_albedo,
            ground_enabled=light.ground_enabled,
        )
    else
        # Non-spectral path: keep as SunSkyLight for Whitted/FastWavefront
        sun_intensity = Hikari.RGBSpectrum(light.intensity)
        return Hikari.SunSkyLight(
            Vec3f(light.direction),
            sun_intensity;
            turbidity=light.turbidity,
            ground_albedo=ground_albedo,
            ground_enabled=light.ground_enabled,
        )
    end
end

function to_trace_light(light::Makie.DirectionalLight, integrator)
    c = RGBf(light.color)
    i = Hikari.RGBSpectrum(c.r, c.g, c.b)
    return Hikari.DirectionalLight(Raycore.Transformation(Mat4f(I)), i, Vec3f(light.direction), 1f0)
end

function to_trace_light(light::Makie.EnvironmentLight, integrator)
    data = map(c -> Hikari.RGBSpectrum(c.r, c.g, c.b), light.image)
    rotation = Hikari.rotation_matrix(light.rotation_angle, light.rotation_axis)
    env_map = Hikari.EnvironmentMap(data, rotation)
    photometric_scale = light.intensity / Hikari.D65_PHOTOMETRIC
    return Hikari.EnvironmentLight(env_map, Hikari.RGBSpectrum(photometric_scale))
end

function to_trace_light(light, integrator)
    return nothing
end

# =============================================================================
# Camera conversion
# =============================================================================

function to_trace_camera(scene::Makie.Scene, film; screen_window=nothing)
    cc = scene.camera_controls
    # Camera3D (LScene) has eyeposition/lookat/fov on camera_controls
    if hasproperty(cc, :eyeposition) && hasproperty(cc, :lookat) && hasproperty(cc, :fov)
        aspect = film.resolution[1] / film.resolution[2]
        sw = isnothing(screen_window) ? Hikari.Bounds2(Point2f(-aspect, -1.0f0), Point2f(aspect, 1.0f0)) : screen_window
        return lift(scene, cc.eyeposition, cc.lookat, cc.upvector, cc.fov) do eyeposition, lookat, upvector, fov
            view = Hikari.look_at(
                Point3f(eyeposition), Point3f(lookat), Vec3f(upvector),
            )
            return Hikari.PerspectiveCamera(
                view, sw,
                0.0f0, 1.0f0, 0.0f0, 1.0f6, Float32(fov),
                film
            )
        end
    else
        # Fallback: use scene.camera view/projection matrices (works with Axis3, etc.)
        # The model matrix is NOT folded into the view — it is already baked into
        # meshscatter/mesh instance transforms via plot[:model]. Folding it here
        # would double-apply the transform, making geometry appear too small.
        cam = scene.camera
        resolution = Point2f(film.resolution)
        sw = screen_window  # may be nothing (full viewport) or Bounds2 (cropped)
        return lift(scene, cam.view, cam.projection) do view, proj
            if isnothing(sw)
                return Hikari.MatrixCamera(Mat4f(view), Mat4f(proj), resolution)
            else
                return Hikari.MatrixCamera(Mat4f(view), Mat4f(proj), resolution, sw)
            end
        end
    end
end

# =============================================================================
# Overlay rendering
# =============================================================================

include("overlay_rendering.jl")

# =============================================================================
# Screen (must come after overlay_rendering.jl, before plot draw_atomic)
# =============================================================================

include("screen.jl")

# =============================================================================
# draw_atomic: per-plot-type conversion via compute graph
# (must come after screen.jl since they reference Screen type)
# =============================================================================

# Fallback: no-op for unsupported plot types
function draw_atomic(screen, scene, plot::Makie.AbstractPlot)
    return nothing
end

include("plots/mesh.jl")
include("plots/meshscatter.jl")
include("plots/surface.jl")
include("plots/volume.jl")
include("plots/lines.jl")
include("plots/scatter_overlay.jl")
include("plots/text_overlay.jl")

# =============================================================================
# init_scene! — create Hikari scene from Makie scene, call draw_atomic per plot
# =============================================================================

function _init_lights!(hikari_scene, rscene, integrator)
    makie_lights = Makie.get_lights(rscene)
    for light in makie_lights
        l = to_trace_light(light, integrator)
        if l isa Tuple
            for li in l
                push!(hikari_scene.lights, li)
            end
        elseif !isnothing(l)
            push!(hikari_scene.lights, l)
        end
    end

    # Add ambient light if present, but skip if we already have SunSkyLight or EnvironmentLight
    has_infinite = any(T -> T <: Hikari.SunSkyLight || T <: Hikari.EnvironmentLight, hikari_scene.lights.data_order)
    if !has_infinite && haskey(rscene.compute, :ambient_color)
        ambient_color = rscene.compute[:ambient_color][]
        if ambient_color != RGBf(0, 0, 0)
            ambient_rgb = RGB{Float32}(ambient_color)
            ambient_light = if _is_spectral_integrator(integrator)
                Hikari.AmbientLight(ambient_rgb)
            else
                Hikari.AmbientLight(Hikari.RGBSpectrum(ambient_rgb.r, ambient_rgb.g, ambient_rgb.b))
            end
            push!(hikari_scene.lights, ambient_light)
        end
    end

    if isempty(hikari_scene.lights)
        error("Must have at least one light in scene")
    end
end

function _create_scene_state(rscene::Makie.Scene, screen, root_scene::Makie.Scene)
    ka_backend = screen.config.backend
    integrator = screen.config.integrator

    # Compute visible portion of viewport within figure bounds.
    # Axis3 may request large viewports (e.g. 1000x1000) that extend beyond the
    # figure. We only render the visible sub-region for efficiency.
    vp = Makie.viewport(rscene)[]
    vp_w, vp_h = Makie.widths(vp)
    root_w, root_h = size(root_scene)
    vx, vy = vp.origin

    # Visible pixel range within the viewport
    vis_x0 = max(0f0, -vx)
    vis_y0 = max(0f0, -vy)
    vis_x1 = min(vp_w, Float32(root_w) - vx)
    vis_y1 = min(vp_h, Float32(root_h) - vy)

    visible_w = max(1f0, vis_x1 - vis_x0)
    visible_h = max(1f0, vis_y1 - vis_y0)
    resolution = Point2f(visible_w, visible_h)

    # Compute NDC screen window for the visible sub-region.
    # Full viewport maps [0..vp_w] → NDC [-1..1]. The visible sub-region
    # [vis_x0..vis_x1] maps to a sub-range of NDC.
    ndc_x0 = -1f0 + 2f0 * vis_x0 / vp_w
    ndc_y0 = -1f0 + 2f0 * vis_y0 / vp_h
    ndc_x1 = -1f0 + 2f0 * vis_x1 / vp_w
    ndc_y1 = -1f0 + 2f0 * vis_y1 / vp_h
    screen_window = (vis_x0 == 0f0 && vis_y0 == 0f0 && vis_x1 == vp_w && vis_y1 == vp_h) ?
        nothing :  # Full viewport, no crop needed
        Hikari.Bounds2(Point2f(ndc_x0, ndc_y0), Point2f(ndc_x1, ndc_y1))

    film = Hikari.Film(
        resolution;
        filter=Hikari.LanczosSincFilter(Point2f(1.0f0), 3.0f0),
        crop_bounds=Hikari.Bounds2(Point2f(0.0f0), Point2f(1.0f0)),
        diagonal=1.0f0, scale=1.0f0,
    )

    hikari_scene = Hikari.Scene(backend=ka_backend)
    _init_lights!(hikari_scene, rscene, integrator)

    # Convert film to GPU if backend is not Array
    film = Raycore.Adapt.adapt(ka_backend, film)

    # Create camera with screen_window for the visible sub-region
    camera = to_trace_camera(rscene, film; screen_window)

    # Clear film when Makie camera changes (rotation, zoom, pan)
    # Pre-allocate buffers
    colorbuffer_tmp = similar(film.postprocess)
    film_size = size(film.framebuffer)
    overlay_buffer = Overlay.create_overlay_buffer(ka_backend, film_size)
    # depth_flipped is unused (kernels flip index instead), but struct field still exists
    depth_flipped = KernelAbstractions.allocate(ka_backend, Float32, 1, 1)

    state = TraceMakieState(rscene, film, camera, hikari_scene, false, colorbuffer_tmp, overlay_buffer, depth_flipped, nothing)
    on(rscene, rscene.camera.projectionview) do _
        state.needs_film_clear = true
    end
    return state
end

function init_scene!(screen, mscene::Makie.Scene)
    ka_backend = screen.config.backend

    # Collect all renderable scenes (3D camera + has plots)
    renderable = collect_renderable_scenes(mscene)
    if isempty(renderable)
        error("No renderable scenes found. TraceMakie requires scenes with 3D cameras (LScene, Axis3, etc.)")
    end

    empty!(screen.scene_states)

    for rscene in renderable
        state = _create_scene_state(rscene, screen, mscene)
        push!(screen.scene_states, state)

        # Set screen.state so draw_atomic closures capture the right per-scene state
        screen.state = state

        # Register draw_atomic for each atomic plot in this scene's subtree
        # Skip plots that already have :trace_renderobject (e.g. re-init from VideoStream)
        Makie.for_each_atomic_plot(rscene) do p
            haskey(p, :trace_renderobject) || draw_atomic(screen, rscene, p)
        end

        # Resolve all registered computations to push geometry into TLAS
        poll_all_plots(screen, rscene)

        # Build TLAS BVH structure
        Raycore.sync!(state.hikari_scene.accel)
    end

    # Pre-allocate full-figure output buffer on backend (height, width — Julia image convention)
    root_w, root_h = size(mscene)
    screen.output_buffer = KernelAbstractions.allocate(ka_backend, RGB{Float32}, root_h, root_w)

    # Set primary state (used by render_interactive and single-scene paths)
    screen.state = first(screen.scene_states)

    return screen.state
end

# =============================================================================
# poll_all_plots — trigger compute graph resolution for all registered plots
# =============================================================================

function poll_all_plots(screen, mscene)
    Makie.for_each_atomic_plot(mscene) do p
        pp = Makie.parent_scene(p)
        pp.visible[] || return nothing
        if haskey(p, :trace_renderobject)
            try
                p[:trace_renderobject][]  # triggers resolution if dirty
            catch
                # Silent catch — logging (even @warn) triggers JIT compilation
                # that can crash Julia 1.12's GC during IncrementalCompact.
                Makie.ComputePipeline.mark_resolved!(p.attributes[:trace_renderobject])
            end
        end
    end
end

# =============================================================================
# delete_trace_robj! — remove a plot's render object from the TLAS
# =============================================================================

function delete_trace_robj!(screen, plot::Makie.AbstractPlot)
    haskey(plot.attributes, :trace_renderobject) || return
    robj = plot.attributes[:trace_renderobject][]
    isnothing(robj) && return

    # Find which scene state owns this plot
    pscene = Makie.parent_scene(plot)
    for ss in screen.scene_states
        if _scene_contains(ss.makie_scene, pscene)
            tlas = ss.hikari_scene.accel
            if hasproperty(robj, :handles)
                for h in robj.handles
                    delete!(tlas, h)
                end
            elseif hasproperty(robj, :handle)
                delete!(tlas, robj.handle)
            end
            ss.needs_film_clear = true
            break
        end
    end

    delete!(plot.attributes, :trace_renderobject, force=true, recursive=true)
end

# Export TraceMakie-specific types
export Screen, ScreenConfig, Whitted, activate!, colorbuffer

# Re-export DenoiseConfig from Hikari for convenience
const DenoiseConfig = Hikari.DenoiseConfig
export DenoiseConfig

# re-export Makie, including deprecated names
for name in names(Makie, all=true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

end
