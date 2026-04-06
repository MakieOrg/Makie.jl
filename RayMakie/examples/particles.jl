using Makie, RayMakie
using GeometryBasics
using LinearAlgebra
using Colors
using Hikari
using AMDGPU

# ==============================================================================
# Particle System
# ==============================================================================

struct Particle
    position::Point3f
    velocity::Vec3f
    radius::Float32
end

mutable struct ParticleSystem
    particles::Vector{Particle}
    bounds_min::Point3f
    bounds_max::Point3f
    gravity::Vec3f
    damping::Float32
end

"""Create a particle system with random initial positions and velocities."""
function ParticleSystem(n_particles::Int;
        bounds_min=Point3f(-40, -40, 0),
        bounds_max=Point3f(40, 40, 80),
        radius_range=(0.5f0, 0.5f0))

    particles = Particle[]

    for _ in 1:n_particles
        pos = Point3f(
            bounds_min[1] + rand(Float32) * (bounds_max[1] - bounds_min[1]),
            bounds_min[2] + rand(Float32) * (bounds_max[2] - bounds_min[2]),
            bounds_min[3] + rand(Float32) * (bounds_max[3] - bounds_min[3])
        )
        vel = Vec3f(
            (rand(Float32) - 0.5f0) * 20,
            (rand(Float32) - 0.5f0) * 20,
            rand(Float32) * 30 + 10
        )
        r = radius_range[1] + rand(Float32) * (radius_range[2] - radius_range[1])
        push!(particles, Particle(pos, vel, r))
    end

    ParticleSystem(particles, bounds_min, bounds_max, Vec3f(0, 0, -30), 0.98f0)
end

"""Step the particle simulation forward by dt seconds."""
function step!(ps::ParticleSystem, dt::Float32)
    for i in eachindex(ps.particles)
        p = ps.particles[i]
        pos = Vec3f(p.position...)
        vel = p.velocity
        r = p.radius

        # Apply gravity and damping
        new_vel = (vel + ps.gravity * dt) * ps.damping

        # Update position
        new_pos = pos + new_vel * dt

        # Bounce off boundaries
        bmin, bmax = ps.bounds_min, ps.bounds_max

        # X axis
        if new_pos[1] - r < bmin[1]
            new_pos = Vec3f(bmin[1] + r, new_pos[2], new_pos[3])
            new_vel = Vec3f(-new_vel[1] * 0.8f0, new_vel[2], new_vel[3])
        elseif new_pos[1] + r > bmax[1]
            new_pos = Vec3f(bmax[1] - r, new_pos[2], new_pos[3])
            new_vel = Vec3f(-new_vel[1] * 0.8f0, new_vel[2], new_vel[3])
        end

        # Y axis
        if new_pos[2] - r < bmin[2]
            new_pos = Vec3f(new_pos[1], bmin[2] + r, new_pos[3])
            new_vel = Vec3f(new_vel[1], -new_vel[2] * 0.8f0, new_vel[3])
        elseif new_pos[2] + r > bmax[2]
            new_pos = Vec3f(new_pos[1], bmax[2] - r, new_pos[3])
            new_vel = Vec3f(new_vel[1], -new_vel[2] * 0.8f0, new_vel[3])
        end

        # Z axis
        if new_pos[3] - r < bmin[3]
            new_pos = Vec3f(new_pos[1], new_pos[2], bmin[3] + r)
            new_vel = Vec3f(new_vel[1], new_vel[2], -new_vel[3] * 0.8f0)
        elseif new_pos[3] + r > bmax[3]
            new_pos = Vec3f(new_pos[1], new_pos[2], bmax[3] - r)
            new_vel = Vec3f(new_vel[1], new_vel[2], -new_vel[3] * 0.8f0)
        end

        ps.particles[i] = Particle(Point3f(new_pos...), new_vel, r)
    end
end

"""Get positions from particle system."""
get_positions(ps::ParticleSystem) = [p.position for p in ps.particles]

"""Get sizes (radii) from particle system."""
get_sizes(ps::ParticleSystem) = [Vec3f(p.radius) for p in ps.particles]

"""Map velocity magnitude to a heat color (blue -> cyan -> green -> yellow -> red -> white)."""
function velocity_to_color(speed::Float32, max_speed::Float32=50.0f0)
    t = clamp(speed / max_speed, 0.0f0, 1.0f0)

    if t < 0.25f0
        # Blue to cyan
        s = t / 0.25f0
        RGBf(0.1f0, 0.2f0 + 0.5f0 * s, 0.8f0)
    elseif t < 0.5f0
        # Cyan to green-yellow
        s = (t - 0.25f0) / 0.25f0
        RGBf(0.1f0 + 0.6f0 * s, 0.7f0, 0.8f0 - 0.6f0 * s)
    elseif t < 0.75f0
        # Yellow to orange-red
        s = (t - 0.5f0) / 0.25f0
        RGBf(0.7f0 + 0.3f0 * s, 0.7f0 - 0.4f0 * s, 0.2f0 - 0.1f0 * s)
    else
        # Red to bright white-yellow (hot!)
        s = (t - 0.75f0) / 0.25f0
        RGBf(1.0f0, 0.3f0 + 0.7f0 * s, 0.1f0 + 0.9f0 * s)
    end
end

"""Get colors based on particle velocities."""
function get_colors(ps::ParticleSystem; max_speed::Float32=50.0f0)
    [velocity_to_color(norm(p.velocity), max_speed) for p in ps.particles]
end

# ==============================================================================
# Scene Setup
# ==============================================================================

function create_particle_scene(n_particles::Int=1000; size=(1920, 1080))
    # Create particle system
    ps = ParticleSystem(n_particles)

    # Create Makie scene with 3D camera and lights
    # Matching wavefront_particles.jl setup
    scene = Scene(size=size; camera=cam3d!,
        lights=[
            # Key light from above
            PointLight(RGBf(800, 780, 750), Point3f(0, 0, 120)),
            # Fill light from camera direction
            PointLight(RGBf(4000, 4000, 4000), Point3f(80, 70, 50)),
            # Rim light
            PointLight(RGBf(2000, 2050, 2200), Point3f(-60, 40, 60)),
            # Ambient
            AmbientLight(RGBf(0.15, 0.15, 0.15))
        ]
    )

    # Camera position - closer to the action
    cam = cameracontrols(scene)
    cam.eyeposition[] = Vec3f(70, 55, 45)
    cam.lookat[] = Vec3f(0, 0, 30)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 50f0

    # Floor - polished silver mirror
    floor_mesh = normal_mesh(Rect3f(Vec3f(-50, -50, -1), Vec3f(100, 100, 1)))
    mesh!(scene, floor_mesh;
        material=Hikari.Silver(roughness=0.005f0)  # Near-perfect mirror
    )

    # Back wall (at y = -50) - matte plastic
    back_mesh = normal_mesh(Rect3f(Vec3f(-50, -50, 0), Vec3f(100, 1, 90)))
    mesh!(scene, back_mesh;
        # material=Hikari.Plastic(color=(0.9, 0.95, 0.5), roughness=0.0)
    )

    # Left wall (at x = -50) - polished silver mirror
    left_mesh = normal_mesh(Rect3f(Vec3f(-50, -50, 0), Vec3f(1, 100, 90)))
    mesh!(scene, left_mesh;
        material=Hikari.Plastic(color=(0.0, 0.95, 0.5), roughness=0.0),
        color=:white
    )

    # Create particles with velocity-based colors
    positions = get_positions(ps)
    sizes = get_sizes(ps)
    colors = get_colors(ps)

    sphere_marker = Sphere(Point3f(0), 1.0f0)

    mplot = meshscatter!(scene, positions;
        material = Hikari.Gold(),
        marker=sphere_marker,
        markersize=sizes,
        color=colors
    )

    return scene, ps, mplot
end

# ==============================================================================
# Animation using record()
# ==============================================================================

"""
Record an animation of the particle simulation.

Uses Makie's record() function and update!() to efficiently update the plot.
"""
function record_particles(filename::String="particles.mp4";
        n_particles::Int=1000,
        n_frames::Int=120,
        dt::Float32=1.0f0/30.0f0,
        samples_per_pixel::Int=8,
        preset="ultrafast",
        backend=Raycore.KA.CPU(),
        integrator=Hikari.FastWavefront(samples=samples_per_pixel)
    )

    println("Creating particle scene with $n_particles particles...")
    scene, ps, mplot = create_particle_scene(n_particles)

    # Activate RayMakie backend
    RayMakie.activate!(;
        integrator=integrator,
        backend=backend,
        tonemap=:aces, exposure=2.0
    )

    println("Recording $n_frames frames to $filename...")

    record(scene, filename, 1:n_frames; framerate=30, preset=preset) do frame
        # Step physics
        step!(ps, dt)

        # Update the meshscatter plot using update!
        # Note: positions are stored as arg1 in Makie's compute graph
        new_positions = get_positions(ps)
        new_sizes = get_sizes(ps)

        update!(mplot;
            arg1=new_positions,
            markersize=new_sizes
        )
        println("  Frame $frame/$n_frames")
    end

    println("Done! Video saved to $filename")
    return scene, ps, mplot
end
using AMDGPU
record_particles("particles.mp4"; n_frames=2, samples_per_pixel=8, n_particles=2000, backend=AMDGPU.ROCBackend())
