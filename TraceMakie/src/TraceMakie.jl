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

struct OverlayPlotInfo
    plot::Makie.AbstractPlot
    plot_type::Symbol  # :lines, :linesegments, :scatter, :text
end

mutable struct TraceMakieState
    film::Hikari.Film
    camera::Observable
    hikari_scene::Hikari.AbstractScene
    needs_film_clear::Bool
    # Pre-allocated buffer for clamp01nan in colorbuffer (avoids per-frame GPU alloc)
    colorbuffer_tmp::AbstractMatrix{RGB{Float32}}
    # Overlay system for lines, scatter, text
    overlay_buffer::Matrix{RGBA{Float32}}
    overlay_plots::Vector{OverlayPlotInfo}
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
    find_3d_scene(scene::Makie.Scene) -> Union{Makie.Scene, Nothing}

Find the first scene in the tree that has a 3D camera (Camera3D).
"""
function find_3d_scene(scene::Makie.Scene)
    cc = scene.camera_controls
    if hasproperty(cc, :eyeposition)
        return scene
    end
    for child in scene.children
        result = find_3d_scene(child)
        if !isnothing(result)
            return result
        end
    end
    return nothing
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
    return Hikari.AmbientLight(rgb)
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

function to_trace_camera(scene::Makie.Scene, film)
    cc = scene.camera_controls
    aspect = film.resolution[1] / film.resolution[2]
    screen_window = Hikari.Bounds2(Point2f(-aspect, -1.0f0), Point2f(aspect, 1.0f0))

    return lift(scene, cc.eyeposition, cc.lookat, cc.upvector, cc.fov) do eyeposition, lookat, upvector, fov
        view = Hikari.look_at(
            Point3f(eyeposition), Point3f(lookat), Vec3f(upvector),
        )
        return Hikari.PerspectiveCamera(
            view, screen_window,
            0.0f0, 1.0f0, 0.0f0, 1.0f6, Float32(fov),
            film
        )
    end
    return
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

# =============================================================================
# init_scene! — create Hikari scene from Makie scene, call draw_atomic per plot
# =============================================================================

function init_scene!(screen, mscene::Makie.Scene)
    resolution = Point2f(size(mscene))
    film = Hikari.Film(
        resolution;
        filter=Hikari.LanczosSincFilter(Point2f(1.0f0), 3.0f0),
        crop_bounds=Hikari.Bounds2(Point2f(0.0f0), Point2f(1.0f0)),
        diagonal=1.0f0, scale=1.0f0,
    )

    ka_backend = screen.config.backend
    hikari_scene = Hikari.Scene(backend=ka_backend)

    # Find the 3D scene for camera and lights
    scene_3d = find_3d_scene(mscene)
    if isnothing(scene_3d)
        error("No 3D scene found in scene tree. TraceMakie requires a scene with a 3D camera (e.g., LScene or Scene with Camera3D).")
    end

    # Extract lights and push to scene
    makie_lights = Makie.get_lights(scene_3d)
    integrator = screen.config.integrator
    for light in makie_lights
        l = to_trace_light(light, integrator)
        if l isa Tuple
            # sunsky_to_envlight returns (EnvironmentLight, SunLight)
            for li in l
                push!(hikari_scene.lights, li)
            end
        elseif !isnothing(l)
            push!(hikari_scene.lights, l)
        end
    end

    # Add ambient light if present, but skip if we already have SunSkyLight or EnvironmentLight
    has_infinite = any(T -> T <: Hikari.SunSkyLight || T <: Hikari.EnvironmentLight, hikari_scene.lights.data_order)
    if !has_infinite && haskey(scene_3d.compute, :ambient_color)
        ambient_color = scene_3d.compute[:ambient_color][]
        if ambient_color != RGBf(0, 0, 0)
            push!(hikari_scene.lights, Hikari.AmbientLight(RGB{Float32}(ambient_color)))
        end
    end

    if isempty(hikari_scene.lights)
        error("Must have at least one light")
    end

    # Convert film to GPU if backend is not Array
    film = Raycore.Adapt.adapt(ka_backend, film)

    # Create camera
    camera = to_trace_camera(scene_3d, film)

    # Pre-allocate colorbuffer clamp buffer (same type/size as film.postprocess)
    colorbuffer_tmp = similar(film.postprocess)

    # Create overlay buffer matching film size
    film_size = size(film.framebuffer)
    overlay_buffer = fill(RGBA{Float32}(0f0, 0f0, 0f0, 0f0), film_size)

    # Collect overlay plots
    overlay_plots = collect_overlay_plots(mscene)

    state = TraceMakieState(film, camera, hikari_scene, false, colorbuffer_tmp, overlay_buffer, overlay_plots)
    screen.state = state

    # Call draw_atomic for each atomic plot (registers compute graph nodes)
    # Skip plots that already have :trace_renderobject (e.g. re-init from VideoStream)
    Makie.for_each_atomic_plot(mscene) do p
        haskey(p, :trace_renderobject) || draw_atomic(screen, scene_3d, p)
    end

    # Resolve all registered computations to push geometry into TLAS
    poll_all_plots(screen, mscene)

    # Build TLAS BVH structure
    Raycore.sync!(hikari_scene.accel)

    return state
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
            catch e
                @error "Failed to update trace renderobject" exception=(e, catch_backtrace())
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
    tlas = screen.state.hikari_scene.accel
    if hasproperty(robj, :handles)
        for h in robj.handles
            delete!(tlas, h)
        end
    elseif hasproperty(robj, :handle)
        delete!(tlas, robj.handle)
    end
    delete!(plot.attributes, :trace_renderobject, force=true, recursive=true)
    screen.state.needs_film_clear = true
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
