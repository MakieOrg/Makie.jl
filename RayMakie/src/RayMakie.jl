module RayMakie

using Makie, Hikari, Colors, LinearAlgebra, GeometryBasics, Raycore, KernelAbstractions
using GeometryBasics: SVector
using Makie: Observable, on, colorbuffer, to_value
using Makie: Quaternionf
using GeometryBasics: VecTypes
using Colors: N0f8, Colorant
using ImageCore: RGBA, RGB, clamp01nan
import Makie.Observables
# Two packages, split by what each name IS.
#
# `Lava` is the SPIR-V compiler: the shader-stage intrinsics a shader body calls,
# the enums a pipeline is DESCRIBED with, and the device-side array. None of it
# needs a device to exist.
#
# `Mantle` is the runtime: the pipeline that gets built, the framebuffer it draws
# into, the textures, the queue, the host array. All of it needs one.
#
# It was all `Lava` until 2026-08-27, when the runtime moved out of the compiler.
import Lava
import Lava: Premultiplied, TriangleList, NoCull, DepthOff,
             vertex_index, instance_index, set_position!, set_point_size!,
             frag_coord_x, frag_coord_y, gfx_output, gfx_input,
             gfx_output_flat, gfx_input_flat,
             dFdx, dFdy,
             emit_vertex!, end_primitive!, primitive_id_in,
             sample_texture_2d, LavaDeviceArray, GeometryConfig,
             LineListAdjacency, LineStripAdjacency, LineList, TriangleStrip, PointList,
             GfxTexture2D,
             geom_input, geom_input_position
import Mantle
import Mantle: GraphicsPipeline, LavaFramebuffer, OffscreenTarget,
               LavaTexture2D, LavaSampler, SampledTexture, bind_textures,
               vk_context, ensure_active_batch!, transition_image!,
               LavaArray, LavaBackend, BatchQueue, allocate_batch_queue!
# `VK` is Mantle's alias for the Vulkan package. This file used to say
# `import Lava.Vulkan` and the call sites said `Vulkan.FORMAT_…`; the split
# replaced the import with this line and left the 18 call sites naming a module
# RayMakie no longer has, so the package did not load at all. Reached through
# Mantle rather than depended on directly: RayMakie describes what to draw, and
# the Vulkan handle types it still touches — viewport, scissor, format — belong
# to the runtime that owns the command buffer.
import Mantle: VK
using Adapt
using Makie.ComputePipeline: register_computation!

# LavaArray overloads for Makie's conversion + bounds path
include("lava_arrays.jl")

# Overlay rasterization (included directly, no submodule)
include("overlay/Overlay.jl")


# =============================================================================
# RayMakieState
# =============================================================================

mutable struct RayMakieState
    makie_scene::Makie.Scene
    film::Hikari.Film
    camera::Union{Observable, Nothing}
    hikari_scene::Union{Hikari.AbstractScene, Nothing}
    needs_film_clear::Bool
    # `depth_flipped` used to sit here — a 1x1 device allocation for an overlay
    # path that flips the index in the kernel instead. Its own comment said it
    # was unused; it existed to be allocated in two constructors and finalized
    # in `cleanup!`.
    # Per-scene integrator state (e.g. VolPathState) — each scene accumulates independently
    integrator_state::Any
    # True for 2D scenes: only overlay rendering, no ray tracing
    overlay_only::Bool
    # Lifecycle: true after close(screen) — prevents operations on freed GPU resources
    closed::Bool
    # Trace-path rebuild accounting. A rebuild whose only dirty geometry input is
    # `positions_transformed_f32c` and/or `normals` is one a BLAS refit could
    # have avoided; anything else (faces, mesh, uv) changed topology or layout
    # and needs a new BVH regardless. Only that distinction is counted, because
    # it is the only one that decides whether refit is worth having — a plain
    # "updates vs rebuilds" ratio reads best on a scene where nothing changed at
    # all and the compute node never re-ran.
    refit_eligible_rebuilds::Int
    topology_rebuilds::Int
end

# Helper to get TLAS from state
get_tlas(state::RayMakieState) = state.hikari_scene.accel

# =============================================================================
# Legacy Overlay Render Objects (kept for backward compat during transition)
# All new draw_atomic methods produce LavaRenderObject instead.
# =============================================================================

abstract type OverlayRenderObject end

# =============================================================================
# Plot conversion helpers (shared across plot types)
# =============================================================================

include("plots/common.jl")

# =============================================================================
# Raytrace vs overlay dispatch
# =============================================================================

"""
    should_raytrace(camera_controls) -> Bool

Determine from the camera type whether a scene should be raytraced.
3D cameras → true, 2D/pixel cameras → false.
"""
should_raytrace(::Makie.AbstractCamera3D) = true
should_raytrace(::Makie.Camera3D) = true
should_raytrace(::Makie.Axis3Camera) = true
should_raytrace(::Makie.OldCamera3D) = true
should_raytrace(::Any) = false  # Camera2D, PixelCamera, RelativeCamera, EmptyCamera

"""
    should_raytrace(plot::Makie.Plot) -> Bool

Determine from the plot type whether it should be raytraced.
3D geometry → true, 2D overlays → false.
"""
should_raytrace(::Makie.Plot{Makie.mesh}) = true
should_raytrace(::Makie.Plot{Makie.meshscatter}) = true
should_raytrace(::Makie.Plot{Makie.surface}) = true
should_raytrace(::Makie.Plot{Makie.volume}) = true
should_raytrace(::Makie.Plot) = false  # scatter, lines, text, image, heatmap → overlay

"""
    should_raytrace(scene, plot) -> Bool

A plot should be raytraced only if BOTH its scene has a 3D camera AND the
plot type is a raytraceable primitive.
"""
should_raytrace(scene::Makie.Scene, plot::Makie.Plot) =
    should_raytrace(scene.camera_controls) && should_raytrace(plot)

# =============================================================================
# Scene initialization and polling
# =============================================================================

function has_atomic_plots(scene::Makie.Scene)
    found = Ref(false)
    Makie.for_each_atomic_plot(scene) do _
        found[] = true
    end
    return found[]
end

# Check if target is the same scene or a descendant of parent
function scene_contains(parent::Makie.Scene, target::Makie.Scene)
    parent === target && return true
    for child in parent.children
        scene_contains(child, target) && return true
    end
    return false
end

"""
    build_materials_tuple(materials_list::Vector) -> Tuple

Group materials by type into a tuple of vectors for MaterialScene.
"""
function build_materials_tuple(materials_list::Vector)
    if isempty(materials_list)
        return (Hikari.Diffuse[],)
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
is_spectral_integrator(::Hikari.VolPath) = true
is_spectral_integrator(::Hikari.Integrator) = false

function to_trace_light(light::Makie.AmbientLight, integrator)
    color = light.color isa Observable ? light.color[] : light.color
    rgb = RGB{Float32}(RGBf(color))
    if is_spectral_integrator(integrator)
        return Hikari.AmbientLight(rgb)
    else
        return Hikari.AmbientLight(Hikari.RGBSpectrum(rgb.r, rgb.g, rgb.b))
    end
end

function to_trace_light(light::Makie.PointLight, integrator)
    c = RGBf(light.color)
    if is_spectral_integrator(integrator)
        # Spectral path: PointLight(RGB{Float32}, position) creates RGBIlluminantSpectrum
        # with photometric normalization (scale = 1/spectrum_to_photometric), matching pbrt-v4
        return Hikari.PointLight(RGB{Float32}(c.r, c.g, c.b), Vec3f(light.position))
    else
        # RGB path: direct RGBSpectrum intensity
        i = Hikari.RGBSpectrum(c.r, c.g, c.b)
        return Hikari.PointLight(Raycore.translate(Vec3f(light.position)), i, 1f0)
    end
end

function to_trace_light(light::Makie.SunSkyLight, integrator)
    ground_albedo = Hikari.RGBSpectrum(light.ground_albedo.r, light.ground_albedo.g, light.ground_albedo.b)
    # Pre-bake Hosek-Wilkie sky to EnvironmentLight + separate SunLight (pbrt-v4 approach).
    # Returns a tuple — caller handles pushing both lights.
    return Hikari.sunsky_to_envlight(
        direction=Vec3f(light.direction),
        intensity=Float32(light.intensity),
        turbidity=light.turbidity,
        ground_albedo=ground_albedo,
        ground_enabled=light.ground_enabled,
    )
end

function to_trace_light(light::Makie.DirectionalLight, integrator)
    c = RGBf(light.color)
    if is_spectral_integrator(integrator)
        # Spectral path: use RGB constructor with photometric normalization (matching pbrt-v4)
        return Hikari.DirectionalLight(RGB{Float32}(c.r, c.g, c.b), Vec3f(light.direction))
    else
        i = Hikari.RGBSpectrum(c.r, c.g, c.b)
        return Hikari.DirectionalLight(Raycore.Transformation(Mat4f(I)), i, Vec3f(light.direction), 1f0)
    end
end

function to_trace_light(light::Makie.SpotLight, integrator)
    c = RGBf(light.color)
    pos = Point3f(light.position)
    dir = Vec3f(light.direction)
    target = pos + normalize(dir)
    # Makie SpotLight angles: [inner_angle, outer_angle] in radians
    falloff_start = rad2deg(light.angles[1])
    total_width = rad2deg(light.angles[2])
    if is_spectral_integrator(integrator)
        return Hikari.SpotLight(
            RGB{Float32}(c.r, c.g, c.b), pos, target,
            Float32(total_width), Float32(falloff_start))
    else
        i = Hikari.RGBSpectrum(c.r, c.g, c.b)
        return Hikari.SpotLight(pos, target, i,
            Float32(total_width), Float32(falloff_start), 1f0)
    end
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
    return to_trace_camera(scene.camera_controls, scene, film; screen_window)
end

function to_trace_camera(cc::Makie.Camera3D, scene::Makie.Scene, film; screen_window=nothing)
    aspect = film.resolution[1] / film.resolution[2]
    sw = isnothing(screen_window) ? Hikari.Bounds2(Point2f(-aspect, -1.0f0), Point2f(aspect, 1.0f0)) : screen_window
    return lift(scene, cc.eyeposition, cc.lookat, cc.upvector, cc.fov, cc.lens_radius, cc.focal_distance) do eyeposition, lookat, upvector, fov, lens_radius, focal_distance
        view = Hikari.look_at(
            Point3f(eyeposition), Point3f(lookat), Vec3f(upvector),
        )
        return Hikari.PerspectiveCamera(
            view, sw,
            0.0f0, 1.0f0, Float32(lens_radius), Float32(focal_distance), Float32(fov),
            film
        )
    end
end

# Fallback: use scene.camera view/projection matrices (works with Axis3, etc.)
# The model matrix is NOT folded into the view — it is already baked into
# meshscatter/mesh instance transforms via plot[:model]. Folding it here
# would double-apply the transform, making geometry appear too small.
function to_trace_camera(cc, scene::Makie.Scene, film; screen_window=nothing)
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
include("plots/image.jl")
include("plots/meshscatter.jl")
include("plots/surface.jl")
include("plots/volume.jl")
include("plots/lines.jl")
include("plots/scatter_overlay.jl")
include("plots/text_overlay.jl")

# =============================================================================
# init_scene! — create Hikari scene from Makie scene, call draw_atomic per plot
# =============================================================================

function init_lights!(hikari_scene, rscene, integrator)
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
    has_infinite = any(T -> T <: Hikari.EnvironmentLight, hikari_scene.lights.data_order)
    if !has_infinite && haskey(rscene.compute, :ambient_color)
        ambient_color = rscene.compute[:ambient_color][]
        if ambient_color != RGBf(0, 0, 0)
            ambient_rgb = RGB{Float32}(ambient_color)
            ambient_light = if is_spectral_integrator(integrator)
                Hikari.AmbientLight(ambient_rgb)
            else
                Hikari.AmbientLight(Hikari.RGBSpectrum(ambient_rgb.r, ambient_rgb.g, ambient_rgb.b))
            end
            push!(hikari_scene.lights, ambient_light)
        end
    end

    # Note: area lights (emissive meshes) are added later during draw_atomic,
    # so the light list may be empty here. That's OK.

end

# Compute Film resolution and NDC screen_window for a sub-scene viewport
# clipped to the root figure bounds. Axis3 may request oversized viewports
# that extend beyond the figure — we only render the visible sub-region.
function compute_scene_resolution(rscene::Makie.Scene, root_w::Int, root_h::Int)
    vp = Makie.viewport(rscene)[]
    vp_w, vp_h = Makie.widths(vp)
    vx, vy = vp.origin

    vis_x0 = max(0f0, -vx)
    vis_y0 = max(0f0, -vy)
    vis_x1 = min(vp_w, Float32(root_w) - vx)
    vis_y1 = min(vp_h, Float32(root_h) - vy)

    visible_w = max(1f0, vis_x1 - vis_x0)
    visible_h = max(1f0, vis_y1 - vis_y0)
    resolution = Point2f(visible_w, visible_h)

    # NDC screen window for the visible sub-region.
    # Full viewport maps [0..vp_w] → NDC [-1..1].
    ndc_x0 = -1f0 + 2f0 * vis_x0 / vp_w
    ndc_y0 = -1f0 + 2f0 * vis_y0 / vp_h
    ndc_x1 = -1f0 + 2f0 * vis_x1 / vp_w
    ndc_y1 = -1f0 + 2f0 * vis_y1 / vp_h
    screen_window = (vis_x0 == 0f0 && vis_y0 == 0f0 && vis_x1 == vp_w && vis_y1 == vp_h) ?
        nothing :
        Hikari.Bounds2(Point2f(ndc_x0, ndc_y0), Point2f(ndc_x1, ndc_y1))

    return resolution, screen_window
end

function create_scene_state(rscene::Makie.Scene, screen, root_scene::Makie.Scene)
    ka_backend = screen.config.device
    integrator = screen.config.integrator

    root_w, root_h = size(root_scene)
    if rscene === root_scene
        # Scene IS the root — use full size, no viewport clipping.
        # The viewport origin may be a Figure-level offset that doesn't apply here.
        resolution = Point2f(Float32(root_w), Float32(root_h))
        screen_window = nothing
    else
        resolution, screen_window = compute_scene_resolution(rscene, root_w, root_h)
    end

    film = Hikari.Film(
        resolution;
        filter=PIXEL_FILTER(),
        crop_bounds=Hikari.Bounds2(Point2f(0.0f0), Point2f(1.0f0)),
        diagonal=1.0f0, scale=1.0f0,
    )

    hw_accel = integrator isa Hikari.VolPath && integrator.hw_accel === true
    hikari_scene = Hikari.Scene(backend=ka_backend, hw_accel=hw_accel)
    init_lights!(hikari_scene, rscene, integrator)

    # Onto the backend, in memory the film owns
    film = Hikari.Film(ka_backend, film)

    # Create camera with screen_window for the visible sub-region
    camera = to_trace_camera(rscene, film; screen_window)

    # Clear film when Makie camera changes (rotation, zoom, pan)

    state = RayMakieState(rscene, film, camera, hikari_scene, false, nothing, false, false, 0, 0)
    # Guard: only clear film when the projection matrix actually changes.
    # Makie's Observable fires on every notify(), even when the value is identical.
    # Without this guard, GLMakie re-renders (triggered by overlay image updates)
    # fire spurious projectionview notifications that reset accumulation every frame.
    last_pv = Ref(copy(rscene.camera.projectionview[]))
    on(rscene, rscene.camera.projectionview) do pv
        if pv != last_pv[]
            last_pv[] = copy(pv)
            state.needs_film_clear = true
        end
    end
    return state
end

# Create a lightweight overlay-only state (no ray-tracing scene, no camera).
# Uses the ROOT scene's full viewport as the buffer — all overlay scenes render
# into the same buffer using viewport-remapped projection matrices.
function create_overlay_only_state(scene::Makie.Scene, screen)
    ka_backend = screen.config.device

    root_w, root_h = size(scene)
    resolution = Point2f(Float32(root_w), Float32(root_h))

    film = Hikari.Film(
        resolution;
        filter=PIXEL_FILTER(),
        crop_bounds=Hikari.Bounds2(Point2f(0.0f0), Point2f(1.0f0)),
        diagonal=1.0f0, scale=1.0f0,
    )
    film = Hikari.Film(ka_backend, film)

    state = RayMakieState(scene, film, nothing, nothing, false, nothing, true, false, 0, 0)
    return state
end

"""
    collect_overlay_scenes(scene) -> Vector{Scene}

Walk the scene tree and return all visible scenes that contain overlay-eligible plots.
"""
function collect_overlay_scenes(scene::Makie.Scene)
    result = Makie.Scene[]
    collect_overlay_scenes!(result, scene)
    return result
end

function collect_overlay_scenes!(result, scene::Makie.Scene)
    scene.visible[] || return
    if has_overlay_plots(scene)
        push!(result, scene)
    end
    for child in scene.children
        collect_overlay_scenes!(result, child)
    end
end

function has_overlay_plots(scene::Makie.Scene)
    found = false
    for p in scene.plots
        Makie.for_each_atomic_plot(p) do ap
            if !should_raytrace(ap) || !should_raytrace(scene.camera_controls)
                found = true
            end
        end
    end
    return found
end

"""
Collect ALL scenes in the tree that have atomic plots, regardless of camera type.
"""
function collect_all_scenes_with_plots(scene::Makie.Scene)
    result = Makie.Scene[]
    collect_all_with_plots!(result, scene)
    return result
end

function collect_all_with_plots!(result, scene::Makie.Scene)
    # Only collect scenes that directly own plots (not via children).
    # A scene "directly owns" plots if scene.plots is non-empty.
    has_own_plots = !isempty(scene.plots)
    if has_own_plots
        push!(result, scene)
    end
    # Always recurse into children — each child scene (Axis3, Axis, etc.)
    # should be collected independently so it gets its own RayMakieState.
    for child in scene.children
        collect_all_with_plots!(result, child)
    end
end

function init_scene!(screen, mscene::Makie.Scene)
    ka_backend = screen.config.device

    # Collect ALL scenes with plots — both 3D (raytraced) and 2D (overlay)
    all_scenes = collect_all_scenes_with_plots(mscene)

    empty!(screen.scene_states)

    for rscene in all_scenes
        is_rt = should_raytrace(rscene.camera_controls)

        if is_rt
            state = create_scene_state(rscene, screen, mscene)
        else
            state = create_overlay_only_state(rscene, screen)
        end
        push!(screen.scene_states, state)
        screen.state = state

        # Call draw_atomic on the plots THIS scene owns — should_raytrace(scene,
        # plot) then decides RT vs overlay.
        #
        # `rscene.plots`, not `for_each_atomic_plot(rscene)`: the latter recurses
        # into `scene.children` as well, so a parent claimed its CHILDREN's
        # plots. In a `Figure` the root scene comes first, is `EmptyCamera` and
        # therefore overlay-only with `hikari_scene === nothing`, and it drew
        # every `Axis3`'s meshes against itself — where `draw_atomic` reads
        # `!should_raytrace(scene, plot) || isnothing(hikari_scene)` and takes
        # the raster path. The compute node caches that decision, and by the time
        # the axis's own state came up the plot already had a
        # `:trace_renderobject` and was skipped. Net effect: NOTHING in a Figure
        # was ever raytraced — an `Axis3` sphere came out as a flat disc of the
        # raw plot colour, with an empty TLAS and an all-zero film.
        # `collect_overlay_robjs` already walks scenes this way.
        for plot in rscene.plots
            Makie.for_each_atomic_plot(plot) do p
                haskey(p, :trace_renderobject) || draw_atomic(screen, rscene, p)
            end
        end

        poll_all_plots(screen, rscene)

        if is_rt
            Hikari.sync!(state.hikari_scene)

            # Tell the camera how big the scene is, so its clip planes enclose
            # the geometry.
            #
            # Via `bounding_sphere`, NOT `near`/`far`. Under `Camera3D`'s default
            # `clipping_mode = :adaptive` those two are FACTORS, not distances:
            # `near = view_dist * near` and
            # `far = max(radius(bounding_sphere) / tand(fov/2), view_dist) * far`.
            # Writing absolute distances into them (this used to set
            # `near = dist - 2r`, `far = dist + 2r`) multiplies them by the view
            # distance a second time, so a camera 6.7 units out got a near plane
            # at 21.9 — past everything in the scene. The raytraced path never
            # noticed, because `to_trace_camera(::Camera3D, …)` builds its
            # `PerspectiveCamera` from eye/lookat/up/fov and ignores the
            # projection matrix. The RASTER overlays use that matrix, and every
            # `lines!`, `scatter!` and `text!` in a 3D scene was clipped away by
            # it — including every part of an `Axis3`.
            #
            # `bounding_sphere` is what `:adaptive` already consults, and it only
            # ever pushes `far` outwards, so a scene larger than its view
            # distance stays visible and nothing gets clipped that was not
            # clipped before.
            #
            # Note: do NOT call Makie.center!(rscene) here — it resets the
            # camera position, overriding user-configured camera in create_scene.
            if rscene.camera_controls isa Makie.Camera3D
                cc = rscene.camera_controls
                bounds = state.hikari_scene.bounds[]
                if bounds[1].p_min[1] < bounds[1].p_max[1]
                    sphere = bounds[2]
                    cc.bounding_sphere[] = Sphere(Point3d(sphere.center), Float64(sphere.r))
                    # bounding_sphere is not one of the observables Camera3D
                    # listens on, so the matrices need rebuilding by hand. The
                    # two-argument form only recomputes them; it does not move
                    # the camera.
                    Makie.update_cam!(rscene, cc)
                end
                state.needs_film_clear = true
            end
        end
    end

    if isempty(screen.scene_states)
        error("No renderable scenes found.")
    end

    # Pre-allocate full-figure output buffer, from the pool the screen owns.
    root_w, root_h = size(mscene)
    screen.memory === nothing || Hikari.free!(screen.memory)
    screen.memory = Hikari.DeviceMemory(ka_backend)
    screen.output_buffer = Hikari.alloc!(screen.memory, RGBA{Float32}, (Int(root_h), Int(root_w)))

    screen.state = first(screen.scene_states)
    return screen.state
end

# =============================================================================
# poll_all_plots — trigger compute graph resolution for all registered plots
# =============================================================================

const POLL_ERROR_LOGGED = Set{UInt64}()

function poll_all_plots(screen, mscene)
    Makie.for_each_atomic_plot(mscene) do p
        pp = Makie.parent_scene(p)
        pp.visible[] || return nothing
        if haskey(p, :trace_renderobject)
            try
                p[:trace_renderobject][]  # triggers resolution if dirty
            catch e
                oid = objectid(p)
                if oid ∉ POLL_ERROR_LOGGED
                    push!(POLL_ERROR_LOGGED, oid)
                    @error "RayMakie: failed to resolve trace_renderobject for $(typeof(p))" exception=(e, catch_backtrace())
                end
            end
        end
    end
end

# =============================================================================
# delete_trace_robj! — remove a plot's render object from the TLAS
# =============================================================================

function delete_trace_robj!(screen, plot::Makie.AbstractPlot)
    haskey(plot.attributes, :trace_renderobject) || return

    # If all scene states are closed (screen was close()'d), GPU resources are already freed.
    # Do NOT resolve the Observable — it triggers ComputePipeline re-evaluation which would
    # try to push! into freed GPU arrays. Just remove the attribute key and return.
    all_closed = all(ss -> ss.closed, screen.scene_states)
    if isempty(screen.scene_states) || all_closed
        delete!(plot.attributes, :trace_renderobject, force=true, recursive=true)
        return
    end

    # Deleting must never *create* the render object.  `computed[]` resolves the
    # edge, and an edge that never resolved builds its TypedEdge on first
    # resolve — whose constructor re-runs draw_atomic and push!es the mesh into
    # a Hikari scene whose GPU arrays may already have been freed, tripping
    # `resize!(::LavaArray): the backing DataRef was already freed`.  This bites
    # even when the screen is still open (the guard above only covers the
    # all-closed case), because `free(scene)` deletes plots one by one.
    #
    # If the edge never resolved there is no render object on the GPU, so there
    # is nothing to delete; otherwise read the cached value rather than
    # re-resolving, since what we must tear down is what actually exists.
    computed = plot.attributes[:trace_renderobject]
    if !Makie.ComputePipeline.is_resolved(computed)
        delete!(plot.attributes, :trace_renderobject, force=true, recursive=true)
        return
    end
    robj = computed[]
    isnothing(robj) && return

    # Find which scene state owns this plot
    pscene = Makie.parent_scene(plot)
    for ss in screen.scene_states
        ss.closed && continue
        ss.hikari_scene === nothing && continue
        if scene_contains(ss.makie_scene, pscene)
            tlas = ss.hikari_scene.accel
            if hasproperty(robj, :handles)
                for h in robj.handles
                    actual_h = h isa Hikari.SceneHandle ? h.geometry : h
                    delete!(tlas, actual_h)
                end
            elseif hasproperty(robj, :handle)
                h = robj.handle
                actual_h = h isa Hikari.SceneHandle ? h.geometry : h
                delete!(tlas, actual_h)
            end
            ss.needs_film_clear = true
            break
        end
    end

    delete!(plot.attributes, :trace_renderobject, force=true, recursive=true)
end

# pbrt scene → Makie scene converter (for testing RayMakie against pbrt-v4 references)
include("pbrt_to_makie.jl")

# Standalone Vulkan viewer (GLFW + Lava swapchain, no GLMakie)
include("vulkan_viewer.jl")

# Export RayMakie-specific types
export Screen, ScreenConfig, activate!, colorbuffer, vulkan_viewer, wait_viewer
export pbrt_to_makie, PBRTMakieResult

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

# ── PrecompileTools workload: bake the hw_accel render path's host inference ──
# Cold startup of a ray-traced render has two independent costs. Lava's frozen
# kernel cache removes the first (GPUCompiler → LLVM → SPIR-V); this removes the
# second — Julia's own inference/codegen of colorbuffer → VolPath → Lava launch
# — by rendering a small scene during precompilation, so PrecompileTools keeps
# the inferred code in RayMakie's package image.
#
# What this can and cannot bake: the RT stages and workqueue kernels are keyed on
# the scene's whole material multi-type-set, so the material-set-specific
# specialization is only bakeable by a workload rendering that exact scene. The
# SCENE-GENERIC half (colorbuffer, screen, buffer alloc, BVH/AS build, RT
# pipeline setup, camera, integrator core) is not, and it dominates — a single
# one-Diffuse-sphere render here cut the unrelated 15-material `materials` scene's
# cold host codegen from ~45s to ~10s.
#
# `Mantle.@compile_workload` runs both halves under this kernel-cache version: the
# first precompile compiles this scene's kernels and freezes them to disk, later
# precompiles load them back instead of recompiling SPIR-V.
#
# Rendering needs a working Vulkan device, so the try/catch skips the workload
# cleanly on device-less machines (CI) rather than breaking precompilation. It is
# on by default; toggle it the standard PrecompileTools way, via Preferences:
#     using RayMakie, Preferences
#     set_preferences!(RayMakie, "precompile_workload" => false; force = true)  # disable
const PRECOMPILE_KERNELS_VERSION = "raymakie_pc"
Mantle.@setup_workload begin
    try
        dev = Mantle.LavaBackend()
        Mantle.@compile_workload PRECOMPILE_KERNELS_VERSION begin
            scene = Scene(size = (96, 72),
                          lights = [PointLight(RGBf(30, 30, 30), Vec3f(4, 5, 6))])
            cam3d!(scene)
            mesh!(scene, Sphere(Point3f(0, 0, 0), 0.9f0);
                  material = Hikari.Diffuse(Kd = (0.6, 0.6, 0.6)))
            activate!(; device = dev)
            colorbuffer(scene; backend = RayMakie,
                        integrator = Hikari.VolPath(; samples = 1, max_depth = 4, hw_accel = true))
        end
    catch e
        @warn "RayMakie GPU precompile workload skipped" exception = (e, catch_backtrace())
    end
end

end
