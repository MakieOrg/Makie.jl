# Overlay Test - Compare TraceMakie overlay with GLMakie
# Tests scatter markers and lines on top of a ray-traced surface

using Revise, GLMakie, TraceMakie, FileIO, ImageShow

# Create surface data
xs = range(-2, 2, length=30)
ys = range(-2, 2, length=30)
zs = [sin(x) * cos(y) for x in xs, y in ys]

# Define corner points on the surface
corner_points = Point3f[
    (-2, -2, sin(-2)*cos(-2)),  # front-left
    (2, -2, sin(2)*cos(-2)),    # front-right
    (-2, 2, sin(-2)*cos(2)),    # back-left
    (2, 2, sin(2)*cos(2)),      # back-right
    (0, 0, 0),                   # center
]

# Line segments connecting corners (pairs of points)
line_points = Point3f[
    corner_points[1], corner_points[2],  # front edge
    corner_points[2], corner_points[4],  # right edge
    corner_points[4], corner_points[3],  # back edge
    corner_points[3], corner_points[1],  # left edge
]

function create_test_scene()
    fig = Figure(size=(600, 450))
    lscene = LScene(fig[1,1], show_axis=true)

    # Add surface
    surface!(lscene, xs, ys, zs, colormap=:viridis)

    # Add scatter markers at corners
    meshscatter!(lscene, corner_points, markersize=0.1, color=:red)

    # Add lines connecting corners
    linesegments!(lscene, line_points, linewidth=3, color=:yellow)
    # Set camera
    cam3d!(lscene.scene, eyeposition=Vec3f(5, 5, 4), lookat=Vec3f(0, 0, 0), upvector=Vec3f(0, 0, 1))

    return fig
end

# Create and save both versions
using AMDGPU
# fig, ax, pl = scatter(rand(10))
TraceMakie.activate!(integrator=TraceMakie.VolPath(samples=10), backend=AMDGPU.ROCBackend())
colorbuffer(fig; backend=TraceMakie)


begin
    fig = create_test_scene()
    surface(fig[1, 2], rand(5, 5))
    TraceMakie.interactive_window(fig; backend=AMDGPU.ROCBackend())
    display(fig; backend=GLMakie)
end

using Random
colorbuffer(surface(rand(5, 5)); backend=TraceMakie)
