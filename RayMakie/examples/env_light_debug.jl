# Environment Light Debug - Test env map wrapping with mirror sphere
using RayMakie, Makie, Hikari, GeometryBasics
using FileIO

# Low res for fast iteration
resolution = (200, 150)
spp = 4

# Load the sky.exr from bunny-cloud scene
sky_path = joinpath(@__DIR__, "..", "..", "..", "pbrt-v4-scenes", "bunny-cloud", "textures", "sky.exr")
sky_matrix = FileIO.load(sky_path)

# Perfect mirror material
mirror = Hikari.Conductor(
    eta = Hikari.RGBSpectrum(0.2f0),  # Low eta for high reflectance
    k = Hikari.RGBSpectrum(3.0f0),    # High k for metallic look
    roughness = 0.0f0
)

function create_mirror_sphere_scene(; cam_pos, look_at, up=Vec3f(0,0,1), rotation_angle=0f0)
    s = Scene(size=resolution; lights=Makie.AbstractLight[])
    cam3d!(s)
    update_cam!(s, cam_pos, look_at, up)
    s.camera_controls.fov[] = 60.0

    # Mirror sphere at origin
    sphere = GeometryBasics.normal_mesh(GeometryBasics.Sphere(Point3f(0, 0, 0), 1f0))
    mesh!(s, sphere; material=mirror)

    # Environment light with rotation
    env_light = Makie.EnvironmentLight(1.0f0, sky_matrix;
        rotation_angle=rotation_angle, rotation_axis=Vec3f(1, 0, 0))
    push_light!(s, env_light)

    return s
end

# Configure VolPath
volpath_config = (
    backend = Raycore.KA.CPU(),
    integrator = RayMakie.VolPath(samples=spp, max_depth=5),
    exposure = 1.0f0,
    tonemap = :aces,
    gamma = 2.2f0,
)
RayMakie.activate!(; volpath_config...)

# Test 1: Front view (looking at sphere from +Y)
println("Test 1: Front view (+Y looking at origin)")
scene1 = create_mirror_sphere_scene(cam_pos=Vec3f(0, 5, 0), look_at=Vec3f(0, 0, 0))
img1 = colorbuffer(scene1; backend=RayMakie)

# Test 2: Top view (looking down from +Z)
println("Test 2: Top view (+Z looking down)")
scene2 = create_mirror_sphere_scene(cam_pos=Vec3f(0, 0, 5), look_at=Vec3f(0, 0, 0), up=Vec3f(0, 1, 0))
img2 = colorbuffer(scene2; backend=RayMakie)

# Test 3: Side view (looking from +X)
println("Test 3: Side view (+X looking at origin)")
scene3 = create_mirror_sphere_scene(cam_pos=Vec3f(5, 0, 0), look_at=Vec3f(0, 0, 0))
img3 = colorbuffer(scene3; backend=RayMakie)

# Test 4: Same as bunny scene camera
println("Test 4: Bunny scene camera angle")
scene4 = create_mirror_sphere_scene(cam_pos=Vec3f(0, 120, 50), look_at=Vec3f(0, 0, 0))
img4 = colorbuffer(scene4; backend=RayMakie)

# Test 5: Front view with 10 degree rotation (like pbrt bunny scene)
println("Test 5: Front view with 10 deg rotation")
scene5 = create_mirror_sphere_scene(cam_pos=Vec3f(0, 5, 0), look_at=Vec3f(0, 0, 0), rotation_angle=10f0)
img5 = colorbuffer(scene5; backend=RayMakie)

# Test 6: Direct sky view (no sphere, just look at sky)
println("Test 6: Direct sky view (camera looking up)")
s6 = Scene(size=resolution; lights=Makie.AbstractLight[])
cam3d!(s6)
update_cam!(s6, Vec3f(0, 0, 0), Vec3f(0, 0, 1), Vec3f(0, 1, 0))  # Looking straight up
s6.camera_controls.fov[] = 90.0
env_light6 = Makie.EnvironmentLight(1.0f0, sky_matrix; rotation_angle=0f0, rotation_axis=Vec3f(1, 0, 0))
push_light!(s6, env_light6)
img6 = colorbuffer(s6; backend=RayMakie)

# Show results
println("\nRendering complete. Images stored in img1-img6")
println("img1: Front view (+Y)")
println("img2: Top view (+Z)")
println("img3: Side view (+X)")
println("img4: Bunny camera angle")
println("img5: Front view with 10° rotation")
println("img6: Direct sky (looking up)")

# Display in a grid

using GLMakie
fig = Figure(size=(800, 600))
ax1 = Axis(fig[1,1], title="Front (+Y)", aspect=DataAspect())
ax2 = Axis(fig[1,2], title="Top (+Z)", aspect=DataAspect())
ax3 = Axis(fig[1,3], title="Side (+X)", aspect=DataAspect())
ax4 = Axis(fig[2,1], title="Bunny cam", aspect=DataAspect())
ax5 = Axis(fig[2,2], title="Front+10°rot", aspect=DataAspect())
ax6 = Axis(fig[2,3], title="Sky (up)", aspect=DataAspect())

image!(ax1, rotr90(img1))
image!(ax2, rotr90(img2))
image!(ax3, rotr90(img3))
image!(ax4, rotr90(img4))
image!(ax5, rotr90(img5))
image!(ax6, rotr90(img6))

hidedecorations!.([ax1, ax2, ax3, ax4, ax5, ax6])

fig
