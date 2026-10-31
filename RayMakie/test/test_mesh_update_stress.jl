# Stress tests for the RayMakie mesh draw_atomic compute graph.
#
# All updates use the standard Makie API. Persistent screen across frames.

using Test, Makie, RayMakie, Lava, Hikari, GeometryBasics
using Mantle: LavaArray
using GeometryBasics: Point3f, Vec3f, Rect3f, Sphere
using Makie: Mat4f

robj_of(plt) = to_value(plt.attributes[:trace_renderobject])

function make_screen(scene)
    return RayMakie.Screen(scene; integrator=Hikari.VolPath(samples=1, max_depth=1))
end

hires_sphere(divisions) = GeometryBasics.normal_mesh(
    GeometryBasics.Tesselation(Sphere(Point3f(0), 1f0), divisions))

# ---------------------------------------------------------------------------
# 1. Trace path: many color updates → in-place material updates
# ---------------------------------------------------------------------------

@testset "mesh trace — color updates, 30 frames" begin
    cube = GeometryBasics.normal_mesh(Rect3f(Vec3f(-1), Vec3f(2)))
    color = Observable(Makie.RGBAf(1, 0, 0, 1))
    scene = Scene(size=(64, 64)); cam3d!(scene)
    plt = mesh!(scene, cube; color=color)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)
    initial = robj_of(plt)
    @test hasproperty(initial, :handle)
    @test hasproperty(initial, :mat_idx)

    initial_mat_idx = initial.mat_idx
    for f in 1:30
        color[] = Makie.RGBAf(rand(), rand(), rand(), 1)
        Makie.colorbuffer(screen)
        @test robj_of(plt).mat_idx === initial_mat_idx   # reused slot — no growth
    end
    close(screen)
end

# ---------------------------------------------------------------------------
# 2. Trace path: live material swap via Observable
# ---------------------------------------------------------------------------

@testset "mesh trace — material swap, 20 frames" begin
    cube = GeometryBasics.normal_mesh(Rect3f(Vec3f(-1), Vec3f(2)))
    mk_diffuse(c) = RayMakie.create_material_with_color(c, nothing)
    material = Observable(mk_diffuse(Makie.RGBAf(1, 1, 1, 1)))
    scene = Scene(size=(64, 64)); cam3d!(scene)
    plt = mesh!(scene, cube; material=material)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)
    pinned_handle = robj_of(plt).handle

    for f in 1:20
        # Swap materials — uses in-place update_trace_material!
        material[] = mk_diffuse(Makie.RGBAf(rand(), rand(), rand(), 1))
        Makie.colorbuffer(screen)
        @test robj_of(plt).handle === pinned_handle  # NO rebuild
    end
    close(screen)
end

# ---------------------------------------------------------------------------
# 3. Trace path: large-mesh rebuild stress (different meshes each frame)
# ---------------------------------------------------------------------------

@testset "mesh trace — mesh swap stress, 30 frames" begin
    sphere = hires_sphere(40)
    cube = GeometryBasics.normal_mesh(Rect3f(Vec3f(-1), Vec3f(2)))
    mesh_obs = Observable{Any}(sphere)

    scene = Scene(size=(64, 64)); cam3d!(scene)
    plt = mesh!(scene, mesh_obs; color=:gray)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)
    pinned_mat_idx = robj_of(plt).mat_idx

    for f in 1:30
        mesh_obs[] = isodd(f) ? cube : sphere
        Makie.colorbuffer(screen)
        @test robj_of(plt).mat_idx === pinned_mat_idx   # mat slot reused
    end
    close(screen)
end

# ---------------------------------------------------------------------------
# 4. Overlay path: 2D mesh in a 2D scene
# ---------------------------------------------------------------------------

@testset "mesh overlay — 2D mesh, vertex updates 30 frames" begin
    n = 4
    positions = Observable([Point3f(0, 0, 0), Point3f(1, 0, 0),
                             Point3f(1, 1, 0), Point3f(0, 1, 0)])
    faces = [GeometryBasics.GLTriangleFace(1, 2, 3), GeometryBasics.GLTriangleFace(1, 3, 4)]

    scene = Scene(size=(64, 64))
    Makie.cam2d!(scene)
    plt = mesh!(scene, positions, faces; color=:cyan)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)
    initial = robj_of(plt)
    @test initial isa RayMakie.LavaRenderObject
    initial_vert_count = initial.vertex_count
    @test initial_vert_count == 6     # 2 triangles × 3 vertices

    for f in 1:30
        positions[] = [Point3f(rand(), 0, 0), Point3f(1+rand(), 0, 0),
                        Point3f(1+rand(), 1+rand(), 0), Point3f(rand(), 1+rand(), 0)]
        Makie.colorbuffer(screen)
        @test robj_of(plt) === initial   # buffer-update path, same robj
        @test robj_of(plt).vertex_count == 6
    end
    close(screen)
end

# ---------------------------------------------------------------------------
# 5. Overlay path: per-vertex colors update on every frame
# ---------------------------------------------------------------------------

@testset "mesh overlay — per-vertex color, 30 frames" begin
    n_verts = 4
    positions = [Point3f(0, 0, 0), Point3f(1, 0, 0), Point3f(1, 1, 0), Point3f(0, 1, 0)]
    faces = [GeometryBasics.GLTriangleFace(1, 2, 3), GeometryBasics.GLTriangleFace(1, 3, 4)]
    colors = Observable([Makie.RGBAf(1, 0, 0, 1) for _ in 1:n_verts])

    scene = Scene(size=(64, 64))
    Makie.cam2d!(scene)
    plt = mesh!(scene, positions, faces; color=colors)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)
    initial = robj_of(plt)
    @test initial isa RayMakie.LavaRenderObject

    for f in 1:30
        colors[] = [Makie.RGBAf(rand(), rand(), rand(), 1) for _ in 1:n_verts]
        Makie.colorbuffer(screen)
        @test robj_of(plt) === initial
    end
    close(screen)
end
