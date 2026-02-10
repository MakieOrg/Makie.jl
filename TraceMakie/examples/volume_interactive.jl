# Interactive Volume Rendering with TraceMakie
# Demonstrates CloudVolume rendering using Makie's volume() plot with render_interactive
# Uses BOMEX LES cloud data for realistic cloud visualization
# Includes sliders for time frame and postprocessing controls

using GLMakie
using TraceMakie
using Makie

# =============================================================================
# Load BOMEX Cloud Data
# =============================================================================

using Oceananigans: FieldTimeSeries, interior

# Load cloud data
BOMEX_PATH = joinpath(@__DIR__, "..", "..", "..", "bomex_3d.jld2")

println("Loading BOMEX data from: $BOMEX_PATH")
qlt = FieldTimeSeries(BOMEX_PATH, "qˡ")  # unicode superscript l
grid_extent = (2.0, 2.0, size(qlt)[3] / size(qlt)[1] * 2.0)
println("Loaded: size=$(size(qlt)), grid_extent=$grid_extent")

# Find frames with cloud data
cloud_frames = Int[]
for i in 1:size(qlt, 4)
    if maximum(interior(qlt[i])) > 0
        push!(cloud_frames, i)
    end
end
println("Frames with clouds: $cloud_frames")

# =============================================================================
# Create Interactive Scene with Controls
# =============================================================================

"""
    volume_interactive_dashboard(qlt, grid_extent, cloud_frames; kwargs...)

Create an interactive volume rendering dashboard with TraceMakie.

The dashboard includes:
- 3D LScene with ray-traced cloud volume
- Time frame slider to animate through cloud data
- Postprocessing controls (exposure, gamma, tonemapping)

# Arguments
- `qlt`: FieldTimeSeries of cloud data
- `grid_extent`: Tuple (x, y, z) of physical dimensions
- `cloud_frames`: Vector of frame indices with cloud data

# Keyword Arguments
- `extinction_scale=10000f0`: Controls optical density
- `asymmetry_g=0.85f0`: Henyey-Greenstein asymmetry (0.85 for clouds)
- `single_scatter_albedo=0.99f0`: Scattering vs absorption ratio
- `sun_direction=Vec3f(0.4, 0.5, 0.85)`: Sun direction vector
- `sun_intensity=25.0f0`: Sun intensity
- `turbidity=2.5f0`: Atmospheric turbidity
- `max_depth=3`: Maximum ray bounces
"""
function volume_interactive_dashboard(qlt, grid_extent, cloud_frames;
    extinction_scale=10000f0,
    asymmetry_g=0.85f0,
    single_scatter_albedo=0.99f0,
    sun_direction=Vec3f(0.4, 0.5, 0.85),
    sun_intensity=25.0f0,
    turbidity=2.5f0,
    max_depth=3)

    # Initial frame
    initial_frame = isempty(cloud_frames) ? 1 : cloud_frames[1]
    initial_vol_data = Float32.(interior(qlt[initial_frame]))

    # Create figure with controls panel
    fig = Figure(size=(1200, 800))

    # Left panel: Controls
    controls = fig[1, 1] = GridLayout(tellwidth=false)
    colsize!(fig.layout, 1, Fixed(280))

    # --- Time Frame Control ---
    Label(controls[1, 1:2], "Time Frame", fontsize=14, halign=:left)

    if length(cloud_frames) > 1
        frame_slider = Slider(controls[2, 1:2], range=cloud_frames, startvalue=initial_frame)
        frame_label = Label(controls[3, 1:2], @lift("Frame: $($(frame_slider.value))"), halign=:left)
    else
        frame_slider = nothing
        Label(controls[2, 1:2], "Only 1 frame available", halign=:left)
    end

    # --- Postprocessing Controls ---
    Label(controls[5, 1:2], "Postprocessing", fontsize=14, halign=:left)

    Label(controls[6, 1], "Exposure:", halign=:right)
    exposure_slider = Slider(controls[6, 2], range=0.1:0.1:3.0, startvalue=1.0)
    exposure_label = Label(controls[7, 1:2], @lift("$(round($(exposure_slider.value), digits=1))"), halign=:center)

    Label(controls[8, 1], "Gamma:", halign=:right)
    gamma_slider = Slider(controls[8, 2], range=0.5:0.1:3.0, startvalue=1.2)
    gamma_label = Label(controls[9, 1:2], @lift("$(round($(gamma_slider.value), digits=1))"), halign=:center)

    Label(controls[10, 1], "Tonemap:", halign=:right)
    tonemap_menu = Menu(controls[10, 2], options=["aces", "reinhard", "filmic", "none"], default="aces")

    # Convert menu selection to Symbol or nothing
    tonemap_obs = @lift begin
        val = $(tonemap_menu.selection)
        val == "none" ? nothing : Symbol(val)
    end

    # --- Render Info ---
    Label(controls[12, 1:2], "Render Settings", fontsize=14, halign=:left)
    Label(controls[13, 1:2], "Progressive (1 spp), Depth: $max_depth", halign=:left, fontsize=11)
    Label(controls[14, 1:2], "Rotate: drag, Zoom: scroll", halign=:left, fontsize=11)

    # Right panel: 3D Scene
    ax = LScene(fig[1, 2]; show_axis=false)

    # Set up camera to look at clouds with sky visible
    cloud_center_z = Float32(grid_extent[3]) * 0.3f0
    cam_pos = Vec3f(3.0, 3.0, cloud_center_z)
    look_at = Vec3f(0.0, 0.0, cloud_center_z)
    update_cam!(ax.scene, cam_pos, look_at, Vec3f(0, 0, 1))

    # Add volume with CloudVolume material parameters
    x_interval = -1.0 .. 1.0
    y_interval = -1.0 .. 1.0
    z_interval = 0.0 .. Float64(grid_extent[3])

    # Use Observable for volume data so it can be updated
    vol_data_obs = Observable(initial_vol_data)

    # Colormap: transparent for zero density, white for clouds
    # Use RGBAf so GLMakie renders empty areas as transparent
    cloud_cmap = [RGBAf(0, 0, 0, 0), RGBAf(1, 1, 1, 1)]

    vol_plot = volume!(ax, x_interval, y_interval, z_interval, vol_data_obs;
        material=(;
            extinction_scale=extinction_scale,
            asymmetry_g=asymmetry_g,
            single_scatter_albedo=single_scatter_albedo
        ),
        algorithm=:absorption, absorption=100f0,
        colormap=cloud_cmap,
        transparency=true
    )

    # Add SunSkyLight for physically-based sky and sun illumination
    sun_sky = Makie.SunSkyLight(sun_direction;
        intensity=sun_intensity,
        turbidity=turbidity,
        ground_enabled=false
    )
    Makie.push_light!(ax.scene, sun_sky)

    # Connect frame slider to volume data
    if !isnothing(frame_slider)
        on(frame_slider.value) do frame_idx
            vol_data_obs[] = Float32.(interior(qlt[frame_idx]))
        end
    end

    # Start interactive rendering with observable postprocessing parameters
    println("Starting interactive rendering...")
    println("  - Rotate: Click and drag")
    println("  - Zoom: Scroll wheel")
    println("  - Use sliders to adjust time and postprocessing")

    controls_handle = TraceMakie.render_interactive(ax.scene;
        max_depth=max_depth,
        exposure=exposure_slider.value,
        tonemap=tonemap_obs,
        gamma=gamma_slider.value,
    )

    return fig, ax, vol_plot, controls_handle
end

# =============================================================================
# Simple Benchmark Scene (for profiling)
# =============================================================================

"""
Create a simple volume scene for benchmarking TraceMakie rendering.
Returns a Screen that can be used with colorbuffer(screen) for timing.
"""
function create_benchmark_scene(vol_data, grid_extent;
    extinction_scale=10000f0,
    samples=1,
    max_depth=3,
    resolution=(800, 600),
    backend=Raycore.KA.CPU())

    scene = Scene(size=resolution)
    cam3d!(scene)

    # Volume bounds
    x_interval = -1.0 .. 1.0
    y_interval = -1.0 .. 1.0
    z_interval = 0.0 .. Float64(grid_extent[3])

    # Add volume with cloud material
    volume!(scene, x_interval, y_interval, z_interval, vol_data;
        material=(;
            extinction_scale=extinction_scale,
            asymmetry_g=0.85f0,
            single_scatter_albedo=0.99f0
        )
    )

    # Add SunSkyLight
    sun_sky = Makie.SunSkyLight(Vec3f(0.4, 0.5, 0.85);
        intensity=25.0f0,
        turbidity=2.5f0,
        ground_enabled=false
    )
    Makie.push_light!(scene, sun_sky)

    # Position camera
    cloud_center_z = Float32(grid_extent[3]) * 0.3f0
    update_cam!(scene, Vec3f(3.0, 3.0, cloud_center_z), Vec3f(0, 0, cloud_center_z), Vec3f(0, 0, 1))

    # Create Screen
    integrator = TraceMakie.Whitted(samples=samples, max_depth=max_depth)
    config = TraceMakie.ScreenConfig(integrator, 1.0f0, :aces, 2.2f0, backend)
    screen = TraceMakie.Screen(nothing, nothing, config)
    display(screen, scene)

    return screen, scene
end

# =============================================================================
# Run Example
# =============================================================================

GLMakie.activate!()

# Uncomment for interactive dashboard:
using WGLMakie
WGLMakie.activate!()
fig, ax, vol_plot, controls = volume_interactive_dashboard(qlt, grid_extent, cloud_frames;
    extinction_scale=10000f0,
    asymmetry_g=0.85f0,
    sun_direction=Vec3f(0.4, 0.5, 0.85),
    sun_intensity=25.0f0,
    max_depth=3
)
fig

# Benchmark example (frame 5):
vol_data = Float32.(interior(qlt[5]))
screen, scene = create_benchmark_scene(vol_data, grid_extent; samples=1, max_depth=3)

# Warmup
@time colorbuffer(screen);
@profview_allocs colorbuffer(screen);
