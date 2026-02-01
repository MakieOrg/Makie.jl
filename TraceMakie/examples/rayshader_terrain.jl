# Rayshader-style Terrain with Clouds Example
# Demonstrates combining real elevation data (via Tyler) with BOMEX cloud data
# Inspired by https://www.rayshader.com/
using TraceMakie
using Makie
using Colors
using GeometryBasics
using LinearAlgebra: normalize, I
using Hikari: RGBSpectrum, compute_perez_coefficients, compute_zenith_values, _compute_sky_radiance

using Tyler
using Tyler: ElevationProvider, ElevationData, PathDownloader, fetch_tile, get_downloader
using MapTiles: Tile, TileGrid, web_mercator, wgs84
using Extents: Extent

using Oceananigans: FieldTimeSeries, interior
using FileIO
using AMDGPU: ROCArray
using pocl_jll, OpenCL
using Hikari


# In-memory cache for fetched tile data
const TILE_CACHE = Dict{String, Any}()

# =============================================================================
# Fetch Elevation Data from Tyler
# =============================================================================

using MapTiles: extent as tile_extent

"""
    fetch_tiles_for_extent(lat, lon, delta; zoom=12)

Fetch elevation tiles for a geographic extent using Tyler's ElevationProvider.
Returns tile data dict, tiles list, and overall extent.
Results are cached in memory to avoid re-downloading.

# Arguments
- `lat`, `lon`: Center coordinates (WGS84)
- `delta`: Extent size in degrees
- `zoom`: Tile zoom level (higher = more detail, default: 12)
"""
function fetch_tiles_for_extent(lat, lon, delta; zoom=12)
    # Check cache first
    cache_key = "tiles_$(lat)_$(lon)_$(delta)_$(zoom)"
    if haskey(TILE_CACHE, cache_key)
        println("Using cached tiles for $cache_key")
        return TILE_CACHE[cache_key]
    end

    provider = ElevationProvider()
    downloader = get_downloader(provider)

    # Create extent in WGS84
    ext = Extent(X=(lon - delta/2, lon + delta/2), Y=(lat - delta/2, lat + delta/2))

    # Get tiles for this extent
    tiles = collect(TileGrid(ext, zoom, wgs84))

    println("Fetching $(length(tiles)) elevation tiles at zoom $zoom...")

    # Fetch all tiles
    tile_data = Dict{Tile, ElevationData}()
    for tile in tiles
        println("  Fetching tile $(tile.x), $(tile.y), z=$(tile.z)...")
        data = fetch_tile(provider, downloader, tile)
        tile_data[tile] = data
    end

    # Cache the result
    result = (tile_data, tiles, ext)
    TILE_CACHE[cache_key] = result

    return result
end

"""
    get_elevation_stats(tile_data)

Compute overall elevation statistics from tile data.
"""
function get_elevation_stats(tile_data)
    elev_min = Inf32
    elev_max = -Inf32
    for data in values(tile_data)
        mini, maxi = extrema(data.elevation)
        elev_min = min(elev_min, mini)
        elev_max = max(elev_max, maxi)
    end
    return elev_min, elev_max
end

"""
    compute_overall_extent(tiles)

Compute the overall geographic extent from a list of tiles.
"""
function compute_overall_extent(tiles)
    x_min = Inf
    x_max = -Inf
    y_min = Inf
    y_max = -Inf
    for tile in tiles
        ext = tile_extent(tile, wgs84)
        x_min = min(x_min, ext.X[1])
        x_max = max(x_max, ext.X[2])
        y_min = min(y_min, ext.Y[1])
        y_max = max(y_max, ext.Y[2])
    end
    return (X=(x_min, x_max), Y=(y_min, y_max))
end

"""
    stitch_tiles(tile_data, tiles, zoom)

Stitch tiles into combined elevation and color arrays with proper orientation.
Returns (elevation, color) where both are oriented for direct use with surface!

Key transformations discovered by edge-matching and correlation analysis:
- Elevation data needs TRANSPOSE to align edges correctly
- Color data needs VERTICAL FLIP (reverse rows) to align with elevation
- After processing: row 1 = south, row end = north, col 1 = west, col end = east
- Tile coords: X increases east, Y increases south (low Y = north)
"""
function stitch_tiles(tile_data, tiles, zoom)
    # Get tile grid dimensions
    xs_tiles = sort(unique(t.x for t in tiles))  # west to east
    ys_tiles = sort(unique(t.y for t in tiles))  # north to south (low tile.y = north)

    # Get tile sizes AFTER transpose (for elevation)
    first_data = first(values(tile_data))
    first_elev_t = permutedims(first_data.elevation, (2, 1))
    tile_h, tile_w = size(first_elev_t)  # h=rows(Y), w=cols(X)

    has_color = !isempty(first_data.color)
    if has_color
        # Color does NOT get transposed - use original size
        color_tile_h, color_tile_w = size(first_data.color)
    end

    # Combined array sizes
    n_tiles_x = length(xs_tiles)
    n_tiles_y = length(ys_tiles)

    # After transpose, we stitch:
    # - Horizontally (X): tiles share east-west edges (columns)
    # - Vertically (Y): tiles share north-south edges (rows)
    # Skip duplicate boundary row/column when stitching (elevation has 257x257 with shared edges)
    total_h = n_tiles_y * tile_h - (n_tiles_y - 1)  # subtract overlapping rows
    total_w = n_tiles_x * tile_w - (n_tiles_x - 1)  # subtract overlapping cols

    elevation = zeros(Float32, total_h, total_w)

    if has_color
        # Color tiles are 256x256, no shared edges
        color_total_h = n_tiles_y * color_tile_h
        color_total_w = n_tiles_x * color_tile_w
        color_raw = zeros(RGBf, color_total_h, color_total_w)
    end

    # Place tiles in combined array
    # After transpose: row 1 = south, row end = north
    # We want final array: row 1 = south (min lat), row end = north (max lat)
    # Tile Y: low Y = north, high Y = south
    # So iterate Y tiles from high to low (south to north) for row 1 to be south
    for (row_idx, ty) in enumerate(reverse(ys_tiles))  # south to north
        for (col_idx, tx) in enumerate(xs_tiles)  # west to east
            tile = Tile(tx, ty, zoom)
            if !haskey(tile_data, tile)
                continue
            end
            data = tile_data[tile]

            # Transpose elevation to get correct orientation
            elev_t = permutedims(Float32.(data.elevation), (2, 1))

            # Calculate destination indices, accounting for shared edges
            row_start = (row_idx - 1) * (tile_h - 1) + 1
            col_start = (col_idx - 1) * (tile_w - 1) + 1
            row_end = row_start + tile_h - 1
            col_end = col_start + tile_w - 1

            elevation[row_start:row_end, col_start:col_end] .= elev_t

            if has_color && !isempty(data.color)
                # Color needs vertical flip (reverse rows) to align with elevation
                # Discovered via correlation analysis: flipud gives 0.78 correlation
                color_data = reverse(RGBf.(data.color), dims=1)

                # Color tiles have no shared edges (256x256)
                c_row_start = (row_idx - 1) * color_tile_h + 1
                c_col_start = (col_idx - 1) * color_tile_w + 1
                c_row_end = c_row_start + color_tile_h - 1
                c_col_end = c_col_start + color_tile_w - 1

                color_raw[c_row_start:c_row_end, c_col_start:c_col_end] .= color_data
            end
        end
    end

    # Resample color to match elevation size if needed
    if has_color
        if size(color_raw) == size(elevation)
            color = color_raw
        else
            eh, ew = size(elevation)
            ch, cw = size(color_raw)
            color = Matrix{RGBf}(undef, eh, ew)
            for i in 1:eh
                for j in 1:ew
                    ci = clamp(round(Int, (i - 0.5) * ch / eh + 0.5), 1, ch)
                    cj = clamp(round(Int, (j - 0.5) * cw / ew + 0.5), 1, cw)
                    color[i, j] = color_raw[ci, cj]
                end
            end
        end
    else
        color = Matrix{RGBf}(undef, 0, 0)
    end

    return elevation, color
end

# =============================================================================
# Load BOMEX Cloud Data
# =============================================================================

const BOMEX_PATH = joinpath(@__DIR__, "..", "..", "..", "..", "RayTracing", "bomex_3d.jld2")


"""
    load_bomex_clouds(; frame=nothing)

Load BOMEX LES cloud data. Returns the cloud density field and grid extent.
If frame is not specified, uses the first frame with cloud data.
"""
function load_bomex_clouds(; frame=5)
    println("Loading BOMEX cloud data from: $BOMEX_PATH")
    qlt = FieldTimeSeries(BOMEX_PATH, "qˡ")

    # Grid extent (normalized to reasonable scale)
    grid_extent = (2.0, 2.0, size(qlt)[3] / size(qlt)[1] * 2.0)

    println("Using frame $frame, grid_extent=$grid_extent")
    cloud_data = Float32.(interior(qlt[frame]))
    return cloud_data, grid_extent
end

# =============================================================================
# Filled Sides Helper - Mesh-based approach
# =============================================================================

"""
    create_sides_mesh(xs, ys, elevation, base_z)

Create a mesh for the filled sides of a terrain block.
Returns a GeometryBasics.Mesh with quad faces for the sides and bottom.

Note: Makie's surface! uses z[row, col] -> (x[row], y[col], z)
So for matrix size (nrows, ncols): x has nrows values, y has ncols values
"""
function create_sides_mesh(xs, ys, elevation, base_z)
    nx, ny = size(elevation)
    xs_range = xs isa Tuple ? LinRange(xs[1], xs[2], nx) : xs
    ys_range = ys isa Tuple ? LinRange(ys[1], ys[2], ny) : ys

    # Collect boundary points in order (clockwise when viewed from above)
    boundary_top = Point3f[]
    boundary_bottom = Point3f[]

    # Bottom edge (row 1): x = x_min, y goes from y_min to y_max
    for j in 1:ny
        x = xs_range[1]
        y = ys_range[j]
        z = elevation[1, j]
        push!(boundary_top, Point3f(x, y, z))
        push!(boundary_bottom, Point3f(x, y, base_z))
    end

    # Right edge (col end): y = y_max, x goes from x_min to x_max
    for i in 2:nx  # skip first since it's already included
        x = xs_range[i]
        y = ys_range[end]
        z = elevation[i, end]
        push!(boundary_top, Point3f(x, y, z))
        push!(boundary_bottom, Point3f(x, y, base_z))
    end

    # Top edge (row end): x = x_max, y goes from y_max to y_min
    for j in (ny-1):-1:1  # skip last since it's already included
        x = xs_range[end]
        y = ys_range[j]
        z = elevation[end, j]
        push!(boundary_top, Point3f(x, y, z))
        push!(boundary_bottom, Point3f(x, y, base_z))
    end

    # Left edge (col 1): y = y_min, x goes from x_max to x_min
    for i in (nx-1):-1:2  # skip first and last since they're already included
        x = xs_range[i]
        y = ys_range[1]
        z = elevation[i, 1]
        push!(boundary_top, Point3f(x, y, z))
        push!(boundary_bottom, Point3f(x, y, base_z))
    end

    n_boundary = length(boundary_top)

    # Create vertices: first n_boundary are top, next n_boundary are bottom
    vertices = vcat(boundary_top, boundary_bottom)

    # Create quad faces for the sides
    # Each quad connects: top[i], top[i+1], bottom[i+1], bottom[i]
    faces = QuadFace{Int}[]
    for i in 1:n_boundary
        i_next = mod1(i + 1, n_boundary)
        # top[i] = i, top[i_next] = i_next
        # bottom[i] = i + n_boundary, bottom[i_next] = i_next + n_boundary
        push!(faces, QuadFace(i, i_next, i_next + n_boundary, i + n_boundary))
    end

    # Add bottom face corners
    n_side_verts = length(vertices)
    push!(vertices, Point3f(xs_range[1], ys_range[1], base_z))    # SW
    push!(vertices, Point3f(xs_range[end], ys_range[1], base_z))  # SE
    push!(vertices, Point3f(xs_range[end], ys_range[end], base_z)) # NE
    push!(vertices, Point3f(xs_range[1], ys_range[end], base_z))  # NW

    # Bottom face (winding for outward normal pointing down)
    push!(faces, QuadFace(n_side_verts + 1, n_side_verts + 4, n_side_verts + 3, n_side_verts + 2))

    return GeometryBasics.Mesh(vertices, faces)
end

"""
    add_filled_sides!(scene, xs, ys, elevation, base_z; color=RGBf(0.25, 0.22, 0.2))

Add filled sides to a surface using a mesh, creating a solid block appearance.
"""
function add_filled_sides!(scene, xs, ys, elevation, base_z; color=RGBf(0.25, 0.22, 0.2))
    sides_mesh = create_sides_mesh(xs, ys, elevation, base_z)
    mesh!(scene, sides_mesh; color=color)
end

# =============================================================================
# Sky Environment Map Generation (for separated sun/sky lighting)
# =============================================================================

"""
    generate_preetham_sky(sun_direction; turbidity=2.5f0, ground_albedo=RGBf(0.3), resolution=256)

Generate a Preetham sky environment map WITHOUT the sun disk.
Returns an RGBf matrix suitable for use with `Makie.EnvironmentLight`.

This is used for low-variance volumetric rendering where we want to sample
the sky and sun separately (sky via EnvironmentLight, sun via DirectionalLight).
"""
function generate_preetham_sky(
    sun_direction::Vec3f;
    turbidity::Float32 = 2.5f0,
    ground_albedo::RGBf = RGBf(0.3, 0.3, 0.3),
    ground_enabled::Bool = true,
    resolution::Int = 256,
)
    dir = normalize(sun_direction)

    # Sun elevation angle (theta_s is angle from zenith, z-up)
    theta_s = acos(clamp(dir[3], -1f0, 1f0))

    # Compute Preetham sky model coefficients
    perez_Y, perez_x, perez_y = compute_perez_coefficients(turbidity)
    zenith_Y, zenith_x, zenith_y = compute_zenith_values(turbidity, theta_s)

    # Convert ground_albedo to RGBSpectrum for the internal function
    ground_spec = RGBSpectrum(ground_albedo.r, ground_albedo.g, ground_albedo.b)

    # Render sky to equirectangular environment map (WITHOUT sun disk)
    h = resolution
    w = resolution * 2
    sky_data = Matrix{RGBf}(undef, h, w)

    for v_idx in 1:h
        # θ goes from 0 (top/+Y in env map convention) to π (bottom/-Y)
        θ = Float32(π) * (v_idx - 0.5f0) / h

        for u_idx in 1:w
            # φ goes from -π to π
            φ = 2f0 * Float32(π) * (u_idx - 0.5f0) / w - Float32(π)

            # Convert to direction (Y-up for environment map)
            sin_θ = sin(θ)
            direction_yup = Vec3f(sin_θ * cos(φ), cos(θ), sin_θ * sin(φ))

            # Convert to Z-up for sky_radiance computation
            # Y-up: (x, y, z) -> Z-up: (x, z, y)
            direction_zup = Vec3f(direction_yup[1], direction_yup[3], direction_yup[2])

            # Compute sky radiance (no sun disk!)
            sky_rad = _compute_sky_radiance(
                direction_zup, dir, perez_Y, perez_x, perez_y,
                zenith_Y, zenith_x, zenith_y, ground_spec, ground_enabled,
            )

            sky_data[v_idx, u_idx] = RGBf(sky_rad.c[1], sky_rad.c[2], sky_rad.c[3])
        end
    end

    return sky_data
end

function rayshader_scene(;
        lat=47.087441,
        lon=13.377214,
        delta=0.1,
        zoom=12,
        cloud_altitude_factor=1.5,
        sun_altitude=30.0,
        sun_azimuth=135.0,
        separate_sun_sky=true,
        sun_intensity=5.0f0,
        turbidity=2.0f0,
        figsize=(1024, 768),
    )
    # Fetch elevation tiles
    tile_data, tiles, ext = fetch_tiles_for_extent(lat, lon, delta; zoom=zoom)

    # Load BOMEX clouds
    cloud_data, cloud_grid_extent = load_bomex_clouds()

    # Compute terrain stats
    elev_min, elev_max = get_elevation_stats(tile_data)
    terrain_height = elev_max - elev_min
    println("Elevation range: $elev_min to $elev_max m ($(terrain_height)m range)")

    # Compute overall geographic extent
    overall_ext = compute_overall_extent(tiles)

    # Compute sun direction from altitude and azimuth
    alt_rad = deg2rad(sun_altitude)
    azi_rad = deg2rad(sun_azimuth)
    sun_dir = Vec3f(
        cos(alt_rad) * sin(azi_rad),
        cos(alt_rad) * cos(azi_rad),
        sin(alt_rad)
    )

    # Set up lights
    if separate_sun_sky
        # Use separated lights for low-variance volumetric rendering:
        # - EnvironmentLight: sky (importance-sampled, no sun disk)
        # - DirectionalLight: sun (samples exactly sun direction, PDF=1)
        println("Using separated sun/sky lights for low-variance volumetric rendering")
        sky_image = generate_preetham_sky(sun_dir; turbidity=turbidity, ground_enabled=false)
        lights = [
            Makie.EnvironmentLight(0.7f0, sky_image),
            Makie.DirectionalLight(RGBf(sun_intensity, sun_intensity, sun_intensity), sun_dir),
        ]
    else
        # Combined SunSkyLight - may have high variance for volumetric rendering
        lights = [
            Makie.SunSkyLight(sun_dir;
                intensity=sun_intensity,
                turbidity=turbidity,
                ground_enabled=false
            ),
        ]
    end

    # Create scene (use Makie.Scene explicitly to avoid conflict with Hikari.Scene)
    scene = Makie.Scene(; size=figsize, lights=lights)
    cam3d!(scene)

    # --- Normalize coordinates ---
    lat_to_m = 111000.0
    lon_to_m = 111000.0 * cos(deg2rad(lat))
    x_extent_m = (overall_ext.X[2] - overall_ext.X[1]) * lon_to_m
    y_extent_m = (overall_ext.Y[2] - overall_ext.Y[1]) * lat_to_m

    # Scale factor to normalize x/y to 0-2 range
    scale_xy = 2.0 / max(x_extent_m, y_extent_m)
    base_z_norm = -0.05f0

    # Helper to convert geographic coords to normalized scene coords
    function geo_to_norm(lon_val, lat_val)
        x = (lon_val - overall_ext.X[1]) * lon_to_m * scale_xy
        y = (lat_val - overall_ext.Y[1]) * lat_to_m * scale_xy
        return Float32(x), Float32(y)
    end

    # Compute final bounds in normalized coords
    x_min_norm, y_min_norm = geo_to_norm(overall_ext.X[1], overall_ext.Y[1])
    x_max_norm, y_max_norm = geo_to_norm(overall_ext.X[2], overall_ext.Y[2])

    # --- Stitch tiles and render as single surface ---
    # This ensures the surface and filled sides use the exact same boundary data
    stitched_elev, stitched_color = stitch_tiles(tile_data, tiles, zoom)
    stitched_elev_norm = (stitched_elev .- elev_min) .* Float32(scale_xy)
    max_elev_norm = maximum(stitched_elev_norm)

    # # Plot the stitched surface
    if !isempty(stitched_color)
        surface!(scene, (x_min_norm, x_max_norm), (y_min_norm, y_max_norm), stitched_elev_norm;
            color=stitched_color,
            shading=NoShading
        )
    else
        surface!(scene, (x_min_norm, x_max_norm), (y_min_norm, y_max_norm), stitched_elev_norm;
            colormap=:terrain
        )
    end

    add_filled_sides!(scene, (x_min_norm, x_max_norm), (y_min_norm, y_max_norm),
                        stitched_elev_norm, base_z_norm)

    # --- Add Cloud Volume ---
    cloud_base_norm = max_elev_norm + 0.1f0
    cloud_thickness_norm = terrain_height * Float32(scale_xy) * cloud_altitude_factor

    cloud_x = x_min_norm .. x_max_norm
    cloud_y = y_min_norm .. y_max_norm
    cloud_z = cloud_base_norm .. (cloud_base_norm + cloud_thickness_norm)

    volume!(scene, cloud_x, cloud_y, cloud_z, cloud_data;
        material=(;
            extinction_scale=50000f0,  # Increased for more visible clouds
            asymmetry_g=0.877f0,       # Disney cloud value for realistic forward scattering
            sun_direction=Vec3f(0.4, 0.5, 0.85),
            sun_intensity=25.0f0,
            max_depth=3
        ),
    )

    # --- Set Camera ---
    center_x = (x_min_norm + x_max_norm) / 2
    center_y = (y_min_norm + y_max_norm) / 2
    center_z = max_elev_norm / 2

    cam_pos = Vec3f(center_x + 2.0, center_y - 1.5, max_elev_norm + 1.5)
    look_at = Vec3f(center_x, center_y, center_z)
    update_cam!(scene, cam_pos, look_at, Vec3f(0, 0, 1))

    cc = scene.camera_controls
    cc.fov[] = 40.0

    return scene, max_elev_norm, cloud_data
end

function render_rayshader(;
        samples=16,
        max_depth=5,
        exposure=1.0f0,
        tonemap=:aces,
        gamma=2.0f0,
        backend=ROCArray,
        save_path=nothing,
        kwargs...
    )
    println("Creating rayshader scene...")
    scene, elevation, clouds = rayshader_scene(; kwargs...)

    backend_name = nameof(backend)
    println("Rendering with TraceMakie on $backend_name ($(samples) spp, max_depth=$(max_depth))...")

    integrator = TraceMakie.VolPath(samples_per_pixel=samples, max_depth=max_depth)
    sensor = Hikari.FilmSensor(iso=100, white_balance=6500)  # D65 daylight white balance
    config = TraceMakie.ScreenConfig(integrator, exposure, tonemap, gamma, sensor, backend)
    screen = TraceMakie.Screen(scene, config)

    @time result = Makie.colorbuffer(screen)

    if !isnothing(save_path)
        FileIO.save(save_path, result)
        println("Saved to: $save_path")
    end

    return result, scene, screen
end

using pocl_jll, OpenCL

# =============================================================================
# Run Example
# =============================================================================

# Austrian Alps location (Großglockner area)
result, scene, screen = render_rayshader(;
    lat=47.087441,
    lon=13.377214,
    delta=0.08,      # ~8km extent
    zoom=13,         # Good detail level
    cloud_altitude_factor=1.2,
    sun_altitude=20.0,
    sun_azimuth=135.0,
    samples=1,
    max_depth=12,
    backend=CLArray,
    exposure=0.8f0,
    figsize=(1024, 768),
)
result

# =============================================================================
# Interactive Rayshader Rendering
# =============================================================================

"""
    render_rayshader_interactive(; kwargs...)

Launch an interactive ray-traced rayshader scene with progressive rendering.

Uses `render_interactive` to continuously refine the image. The scene updates
in real-time as you move the camera or adjust parameters.

# Arguments
Same as `render_rayshader`, plus:
- `fps::Int=30`: Target frames per second for progressive updates
"""
function render_rayshader_interactive(;
    lat=47.087441,
    lon=13.377214,
    delta=0.08,
    zoom=13,
    cloud_altitude_factor=1.2,
    sun_altitude=20.0,
    sun_azimuth=135.0,
    max_depth=12,
    backend=Array,
    exposure=0.8f0,
    tonemap=:aces,
    gamma=2.2f0,
    figsize=(1024, 768),
)
    # Create the scene
    scene, elevation, clouds = rayshader_scene(;
        lat, lon, delta, zoom,
        cloud_altitude_factor,
        sun_altitude, sun_azimuth
    )
    #
    # scene.viewport[] = Makie.Rect2f(0, 0, figsize...)

    # Create integrator for progressive rendering (1 sample per iteration)
    integrator = TraceMakie.VolPath(samples=1, max_depth=max_depth)

    # Create sensor with D65 daylight white balance
    sensor = Hikari.FilmSensor(iso=100, white_balance=6500)

    # Launch interactive render
    handles = TraceMakie.render_interactive(
        scene;
        integrator=integrator,
        exposure=exposure,
        tonemap=tonemap,
        gamma=gamma,
        sensor=sensor,
        backend=backend
    )

    println("Interactive rendering started!")
    println("Move the camera to explore the scene")
    println("The image will progressively refine when the camera is still")
    println("To stop: handles.running[] = false")

    return handles, scene
end
using AMDGPU
# Uncomment to test interactive rendering:
handles, scene = render_rayshader_interactive(
    lat=47.087441,
    lon=13.377214,
    delta=0.08,
    zoom=13,
    cloud_altitude_factor=1.2,
    sun_altitude=20.0,
    sun_azimuth=135.0,
    max_depth=12,
    backend=ROCArray,
    exposure=0.8f0,
    figsize=(1024, 768),
)
using GLMakie
display(scene; backend=GLMakie)
# Hikari.postprocess!(screen.state.film;
#     exposure=0.8f0,
#     tonemap=:ace,
#     gamma=2.2f0
# )

# save("clouds.png", result)

# begin
#     scene, elevation, clouds = rayshader_scene(lat=47.087441,
#         lon=13.377214,
#         delta=0.08,      # ~8km extent
#         zoom=13,         # Good detail level
#         cloud_altitude_factor=1.2,
#         sun_altitude=20.0,
#         sun_azimuth=135.0
#     )

#     integrator = TraceMakie.VolPath(samples_per_pixel=10, max_depth=10)
#     config = TraceMakie.ScreenConfig(integrator, 1.0, :aces, 2.2f0, CLArray)
#     screen = TraceMakie.Screen(scene, config)

#     @time result = Makie.colorbuffer(screen)
# end
