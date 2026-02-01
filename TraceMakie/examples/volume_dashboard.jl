# Interactive Volume Rendering Dashboard
# Demonstrates CloudVolume rendering with real-time parameter controls
# Uses BOMEX LES cloud data and Hikari's Whitted integrator

using GLMakie
using Hikari
using Raycore
using GeometryBasics
using FileIO
using Colors
using LinearAlgebra: normalize

# =============================================================================
# Load BOMEX Cloud Data
# =============================================================================

using Oceananigans
const FieldTimeSeries = Oceananigans.FieldTimeSeries

# Load cloud data (adjust path as needed)
const BOMEX_PATH = joinpath(@__DIR__, "..", "..", "..", "bomex_3d.jld2")

function load_bomex_data(path=BOMEX_PATH)
    qlt = FieldTimeSeries(path, "qˡ")  # unicode superscript l
    grid_extent = (2.0, 2.0, size(qlt)[3] / size(qlt)[1] * 2.0)
    return qlt, grid_extent
end

# Find frames with cloud data
function find_cloud_frames(qlt)
    frames = Int[]
    for i in 1:size(qlt, 4)
        if maximum(interior(qlt[i])) > 0
            push!(frames, i)
        end
    end
    return frames
end

# =============================================================================
# Hikari Scene Creation
# =============================================================================

function create_cloud_volume(qlt, frame_idx, grid_extent;
                             extinction_scale=10000f0,
                             asymmetry_g=0.85f0,
                             single_scatter_albedo=0.99f0)
    Hikari.CloudVolume(
        Float32.(interior(qlt[frame_idx]));
        origin=Point3f(-1, -1, 0),
        extent=Vec3f(2, 2, Float32(grid_extent[3])),
        extinction_scale=extinction_scale,
        asymmetry_g=asymmetry_g,
        single_scatter_albedo=single_scatter_albedo
    )
end

function create_hikari_scene(cloud::Hikari.CloudVolume, sun_direction, sun_intensity, turbidity, ground_albedo)
    # Cloud box geometry - convert to TriangleMesh
    cloud_box_geo = Rect3f(cloud.origin, cloud.extent)
    cloud_box_mesh = Raycore.TriangleMesh(normal_mesh(cloud_box_geo))

    mat_scene = Hikari.MaterialScene([
        (cloud_box_mesh, cloud),
    ])

    sun_dir = normalize(Vec3f(sun_direction...))
    sun_sky = Hikari.SunSkyLight(
        sun_dir,
        Hikari.RGBSpectrum(Float32(sun_intensity));
        turbidity=Float32(turbidity),
        ground_albedo=Hikari.RGBSpectrum(Float32.(ground_albedo)...)
    )

    Hikari.Scene((sun_sky,), mat_scene)
end

function create_camera_and_film(cam_pos, look_at_pt, fov; width=800, height=600)
    resolution = Point2f(width, height)
    film = Hikari.Film(resolution; filter=Hikari.LanczosSincFilter(Point2f(2, 2), 3f0))

    crop_bounds = Raycore.Bounds2(Point2f(0, 0), Point2f(1, 1))
    up = Vec3f(0, 0, 1)
    cam_to_world = Raycore.look_at(Point3f(cam_pos...), Point3f(look_at_pt...), up)

    camera = Hikari.PerspectiveCamera(
        cam_to_world, crop_bounds,
        0f0, 1f0, 0f0, 1f6,
        Float32(fov), film
    )

    film, camera
end

# =============================================================================
# Render Function
# =============================================================================

function render_cloud(cloud, sun_direction, sun_intensity, turbidity, ground_albedo,
                      cam_pos, look_at_pt, fov,
                      samples, max_depth,
                      exposure, tonemap, gamma;
                      width=800, height=600)

    scene = create_hikari_scene(cloud, sun_direction, sun_intensity, turbidity, ground_albedo)
    film, camera = create_camera_and_film(cam_pos, look_at_pt, fov; width, height)

    integrator = Hikari.Whitted(; samples=samples, max_depth=max_depth)

    Hikari.clear!(film)
    integrator(scene, film, camera)

    # Postprocess
    tonemap_sym = tonemap == "none" ? nothing : Symbol(tonemap)
    Hikari.postprocess!(film; exposure=Float32(exposure), tonemap=tonemap_sym, gamma=Float32(gamma))

    # Return clamped framebuffer
    fb = film.postprocess
    map(c -> RGB(clamp(c.r, 0, 1), clamp(c.g, 0, 1), clamp(c.b, 0, 1)), fb)
end

# =============================================================================
# Interactive Dashboard
# =============================================================================

function volume_dashboard(;
        bomex_path=BOMEX_PATH,
        figsize=(1400, 900),
        render_width=800,
        render_height=600)

    # Load data
    println("Loading BOMEX data from: $bomex_path")
    qlt, grid_extent = load_bomex_data(bomex_path)
    cloud_frames = find_cloud_frames(qlt)
    println("Found $(length(cloud_frames)) frames with cloud data")

    if isempty(cloud_frames)
        error("No frames with cloud data found!")
    end

    # Get initial frame (cloud volume is created fresh each render)
    initial_frame = first(cloud_frames)

    # Create figure
    fig = Figure(; size=figsize)

    # === Left Panel: Controls ===
    left_panel = fig[1, 1] = GridLayout()

    # --- Frame Selection ---
    Label(left_panel[1, 1], "Frame Selection", fontsize=14, halign=:left)
    frame_grid = left_panel[2, 1] = GridLayout()
    Label(frame_grid[1, 1], "Frame:", halign=:right)
    frame_slider = Slider(frame_grid[1, 2], range=cloud_frames, startvalue=initial_frame)
    frame_label = Label(frame_grid[1, 3], @lift(string($(frame_slider.value))))

    # --- Volume Parameters ---
    Label(left_panel[3, 1], "Volume Parameters", fontsize=14, halign=:left)
    vol_grid = left_panel[4, 1] = GridLayout()

    Label(vol_grid[1, 1], "Extinction Scale:", halign=:right)
    extinction_slider = Slider(vol_grid[1, 2], range=1000:1000:50000, startvalue=10000)
    extinction_label = Label(vol_grid[1, 3], @lift(string($(extinction_slider.value))))

    Label(vol_grid[2, 1], "Asymmetry (g):", halign=:right)
    asymmetry_slider = Slider(vol_grid[2, 2], range=0.0:0.05:0.99, startvalue=0.85)
    asymmetry_label = Label(vol_grid[2, 3], @lift(string(round($(asymmetry_slider.value), digits=2))))

    Label(vol_grid[3, 1], "Albedo:", halign=:right)
    albedo_slider = Slider(vol_grid[3, 2], range=0.5:0.01:1.0, startvalue=0.99)
    albedo_label = Label(vol_grid[3, 3], @lift(string(round($(albedo_slider.value), digits=2))))

    # --- Sun Parameters ---
    Label(left_panel[5, 1], "Sun Parameters", fontsize=14, halign=:left)
    sun_grid = left_panel[6, 1] = GridLayout()

    Label(sun_grid[1, 1], "Sun Azimuth:", halign=:right)
    sun_azimuth_slider = Slider(sun_grid[1, 2], range=0:5:360, startvalue=45)
    sun_azimuth_label = Label(sun_grid[1, 3], @lift(string($(sun_azimuth_slider.value)) * "deg"))

    Label(sun_grid[2, 1], "Sun Elevation:", halign=:right)
    sun_elevation_slider = Slider(sun_grid[2, 2], range=5:5:85, startvalue=60)
    sun_elevation_label = Label(sun_grid[2, 3], @lift(string($(sun_elevation_slider.value)) * "deg"))

    Label(sun_grid[3, 1], "Intensity:", halign=:right)
    sun_intensity_slider = Slider(sun_grid[3, 2], range=5:5:100, startvalue=25)
    sun_intensity_label = Label(sun_grid[3, 3], @lift(string($(sun_intensity_slider.value))))

    Label(sun_grid[4, 1], "Turbidity:", halign=:right)
    turbidity_slider = Slider(sun_grid[4, 2], range=1.0:0.5:10.0, startvalue=2.5)
    turbidity_label = Label(sun_grid[4, 3], @lift(string(round($(turbidity_slider.value), digits=1))))

    # --- Camera Parameters ---
    Label(left_panel[7, 1], "Camera Parameters", fontsize=14, halign=:left)
    cam_grid = left_panel[8, 1] = GridLayout()

    Label(cam_grid[1, 1], "Distance:", halign=:right)
    cam_distance_slider = Slider(cam_grid[1, 2], range=1.5:0.5:8.0, startvalue=3.5)
    cam_distance_label = Label(cam_grid[1, 3], @lift(string(round($(cam_distance_slider.value), digits=1))))

    Label(cam_grid[2, 1], "Azimuth:", halign=:right)
    cam_azimuth_slider = Slider(cam_grid[2, 2], range=0:5:360, startvalue=125)
    cam_azimuth_label = Label(cam_grid[2, 3], @lift(string($(cam_azimuth_slider.value)) * "deg"))

    Label(cam_grid[3, 1], "Elevation:", halign=:right)
    cam_elevation_slider = Slider(cam_grid[3, 2], range=-30:5:60, startvalue=0)
    cam_elevation_label = Label(cam_grid[3, 3], @lift(string($(cam_elevation_slider.value)) * "deg"))

    Label(cam_grid[4, 1], "FOV:", halign=:right)
    fov_slider = Slider(cam_grid[4, 2], range=20:5:90, startvalue=45)
    fov_label = Label(cam_grid[4, 3], @lift(string($(fov_slider.value)) * "deg"))

    # --- Render Settings ---
    Label(left_panel[9, 1], "Render Settings", fontsize=14, halign=:left)
    render_grid = left_panel[10, 1] = GridLayout()

    Label(render_grid[1, 1], "Samples:", halign=:right)
    samples_slider = Slider(render_grid[1, 2], range=1:32, startvalue=8)
    samples_label = Label(render_grid[1, 3], @lift(string($(samples_slider.value))))

    Label(render_grid[2, 1], "Max Depth:", halign=:right)
    depth_slider = Slider(render_grid[2, 2], range=1:8, startvalue=3)
    depth_label = Label(render_grid[2, 3], @lift(string($(depth_slider.value))))

    # --- Postprocessing ---
    Label(left_panel[11, 1], "Postprocessing", fontsize=14, halign=:left)
    post_grid = left_panel[12, 1] = GridLayout()

    Label(post_grid[1, 1], "Exposure:", halign=:right)
    exposure_slider = Slider(post_grid[1, 2], range=0.1:0.1:3.0, startvalue=1.0)
    exposure_label = Label(post_grid[1, 3], @lift(string(round($(exposure_slider.value), digits=1))))

    Label(post_grid[2, 1], "Tonemap:", halign=:right)
    tonemap_menu = Menu(post_grid[2, 2:3], options=["aces", "reinhard", "uncharted2", "filmic", "none"], default="aces")

    Label(post_grid[3, 1], "Gamma:", halign=:right)
    gamma_slider = Slider(post_grid[3, 2], range=1.0:0.1:3.0, startvalue=1.2)
    gamma_label = Label(post_grid[3, 3], @lift(string(round($(gamma_slider.value), digits=1))))

    # --- Buttons ---
    button_grid = left_panel[13, 1] = GridLayout()
    render_btn = Button(button_grid[1, 1], label="Render", tellwidth=false)
    save_btn = Button(button_grid[1, 2], label="Save Image", tellwidth=false)

    # Status
    status_label = Label(left_panel[14, 1], "Ready - Click 'Render' to start", halign=:left)

    # === Right Panel: Rendered Image ===
    right_panel = fig[1, 2] = GridLayout()
    Label(right_panel[1, 1], "Ray Traced Cloud Volume", fontsize=16, tellwidth=false)

    render_ax = Axis(right_panel[2, 1], aspect=DataAspect())
    hidedecorations!(render_ax)

    # Placeholder image
    placeholder = zeros(RGB{Float32}, render_height, render_width)
    render_image = image!(render_ax, placeholder)

    # Set column widths
    colsize!(fig.layout, 1, Fixed(400))
    colsize!(fig.layout, 2, Auto())

    # Helper: compute sun direction from azimuth/elevation
    function compute_sun_direction(azimuth_deg, elevation_deg)
        az = deg2rad(azimuth_deg)
        el = deg2rad(elevation_deg)
        x = cos(el) * sin(az)
        y = cos(el) * cos(az)
        z = sin(el)
        return (x, y, z)
    end

    # Helper: compute camera position from spherical coords
    function compute_camera_position(distance, azimuth_deg, elevation_deg)
        az = deg2rad(azimuth_deg)
        el = deg2rad(elevation_deg)
        x = distance * cos(el) * sin(az)
        y = distance * cos(el) * cos(az)
        z = distance * sin(el)
        return (x, y, z)
    end

    # Render function
    function do_render()
        status_label.text = "Rendering..."

        try
            frame_idx = frame_slider.value[]

            # Create new CloudVolume with current parameters (CloudVolume is immutable)
            cloud_current = create_cloud_volume(
                qlt, frame_idx, grid_extent;
                extinction_scale=Float32(extinction_slider.value[]),
                asymmetry_g=Float32(asymmetry_slider.value[]),
                single_scatter_albedo=Float32(albedo_slider.value[])
            )

            # Compute sun direction
            sun_dir = compute_sun_direction(sun_azimuth_slider.value[], sun_elevation_slider.value[])

            # Compute camera position
            cam_pos = compute_camera_position(
                cam_distance_slider.value[],
                cam_azimuth_slider.value[],
                cam_elevation_slider.value[]
            )
            look_at = (0.0, 0.0, Float64(grid_extent[3]) * 0.3)  # Look at cloud center

            # Get render settings
            samples = samples_slider.value[]
            max_depth = depth_slider.value[]
            exposure = exposure_slider.value[]
            tonemap = tonemap_menu.selection[]
            gamma = gamma_slider.value[]
            fov = fov_slider.value[]

            # Render
            status_label.text = "Rendering frame $frame_idx ($samples spp)..."

            t0 = time()
            result = render_cloud(
                cloud_current, sun_dir, sun_intensity_slider.value[], turbidity_slider.value[],
                (0.8, 0.8, 0.9),  # ground albedo
                cam_pos, look_at, fov,
                samples, max_depth,
                exposure, tonemap, gamma;
                width=render_width, height=render_height
            )
            dt = time() - t0

            # Update image
            render_image[1] = result
            autolimits!(render_ax)

            status_label.text = "Done! Frame $frame_idx rendered in $(round(dt, digits=2))s"
        catch e
            status_label.text = "Error: $(sprint(showerror, e))"
            @error "Render failed" exception=(e, catch_backtrace())
        end
    end

    # Save function
    function do_save()
        img = render_image[1][]
        if all(c -> c == RGB{Float32}(0,0,0), img)
            status_label.text = "Nothing to save - render first!"
            return
        end

        filename = "cloud_render_$(frame_slider.value[]).png"
        FileIO.save(filename, img)
        status_label.text = "Saved to $filename"
    end

    # Connect buttons
    on(render_btn.clicks) do _
        @async do_render()
    end

    on(save_btn.clicks) do _
        do_save()
    end

    return fig, qlt, grid_extent
end

# =============================================================================
# Run Dashboard
# =============================================================================

if abspath(PROGRAM_FILE) == @__FILE__
    GLMakie.activate!()
    fig, qlt, grid_extent = volume_dashboard()
    display(fig)
end
