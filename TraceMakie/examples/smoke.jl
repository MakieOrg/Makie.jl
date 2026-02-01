# Smoke/Cloud Volume Example
# Single sphere with procedural Perlin noise density
using TraceMakie, Makie, Hikari, GeometryBasics
using FileIO
using AMDGPU

# Scene setup
function create_smoke_scene(; resolution=(800, 800), cloud_resolution=128)
    # Lights
    lights = [
        PointLight(RGBf(80, 80, 80), Vec3f(5, 5, 5)),
        PointLight(RGBf(30, 30, 40), Vec3f(-3, 2, 4)),
    ]

    ax = Scene(; size=resolution, lights=lights, ambient=RGBf(0.02, 0.02, 0.03))
    cam3d!(ax)

    # Generate cloud density with Perlin noise
    # scale=4.0 for detailed structure, threshold controls sparsity (negative = denser)
    cloud_density = Hikari.generate_cloud_density(cloud_resolution; scale=20.0, threshold=-0.5)

    # Cloud volume parameters
    # The sphere mesh and volume bounds must match!
    sphere_radius = 1.5f0
    sphere_center = Point3f(0, 0, 0)

    # Bounds must match the sphere's bounding box: from -radius to +radius in all axes
    bounds_min = sphere_center - Vec3f(sphere_radius)
    bounds_max = sphere_center + Vec3f(sphere_radius)

    # Create GridMedium with the procedural density
    # generate_cloud_density creates a spherical pattern in [0,1]³ which maps to these bounds
    # Note: Lower σ_s values let you see through the cloud to appreciate the noise structure
    # Higher values (10+) make it look more solid/opaque
    cloud_medium = Hikari.GridMedium(
        cloud_density;
        σ_a = Hikari.RGBSpectrum(5.01f0),   # Low absorption for bright cloud
        σ_s = Hikari.RGBSpectrum(0.0f0),    # Moderate scattering
        g = 0.6f0,                           # Forward scattering like real clouds
        bounds = Hikari.Bounds3(bounds_min, bounds_max),
        majorant_res = Vec3i(16, 16, 16)
    )

    # Transparent boundary (no refraction)
    cloud_boundary = Hikari.Dielectric(Kt=(1, 1, 1), index=1.0)
    cloud_material = Hikari.MediumInterface(cloud_boundary; inside=cloud_medium, outside=nothing)

    # Cloud sphere mesh
    cloud_mesh = normal_mesh(Sphere(sphere_center, sphere_radius))
    mesh!(ax, cloud_mesh; material=cloud_material)

    # Ground plane
    ground_material = Hikari.Diffuse(Kd=(0.4, 0.4, 0.45))
    ground_mesh = Rect3f(Vec3f(-10, -10, -sphere_radius - 0.01), Vec3f(20, 20, 0.01))
    mesh!(ax, ground_mesh; color=:white, material=ground_material)

    # Camera setup
    cam = cameracontrols(ax)
    cam.eyeposition[] = Vec3f(4, -4, 2)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 45
    update_cam!(ax, cam)

    return ax
end

# Render function
function render_smoke(;
    samples=64,
    max_depth=50,
    resolution=(800, 800),
    cloud_resolution=64,
    backend=ROCArray
)
    TraceMakie.activate!(;
        backend=backend,
        exposure=0.8f0,
        tonemap=:aces,
        gamma=2.2f0,
        sensor=Hikari.FilmSensor(iso=100, white_balance=6500)
    )

    scene = create_smoke_scene(; resolution=resolution, cloud_resolution=cloud_resolution)
    integrator = Hikari.VolPath(samples=samples, max_depth=max_depth)
    img = @time colorbuffer(scene; backend=TraceMakie, integrator=integrator)
    return img, scene
end

# Run
img, scene = render_smoke(samples=1000, max_depth=50, cloud_resolution=128, backend=ROCArray)
save(joinpath(@__DIR__, "smoke.png"), img)
img
