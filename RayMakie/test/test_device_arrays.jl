# Every plot type, drawn twice: once from host arrays, once from Mantle device
# arrays. The two images have to agree.
#
# COUNTING PIXELS is the point. A plot whose computation fails to resolve is
# logged and skipped, and the figure comes back without it — so "nothing threw"
# reports success for a figure that drew nothing. That is how five of these six
# were silently broken before: `image!`, `scatter!`, `lines!` and
# `linesegments!` each drew 0 pixels from a device array while raising nothing,
# and `mesh!` failed further upstream, in Makie's `convert_arguments`.

using Test, RayMakie, Makie, Mantle, GeometryBasics, Colors, LinearAlgebra

const DEVBACK = Mantle.defaultbackend()
todevice(x) = Mantle.devicearray(DEVBACK, x)

"How many red pixels the figure drew — red because every plot below is red."
function redcount(build; screen_kw...)
    fig = Figure(size = (400, 300), backgroundcolor = :white)
    build(fig)
    screen = RayMakie.Screen(fig.scene; visible = false, screen_kw...)
    img = Makie.colorbuffer(screen)
    close(screen)
    return count(c -> red(c) > 0.6 && green(c) < 0.35 && blue(c) < 0.35, img)
end

@testset "device arrays draw the same as host arrays" begin
    linepts = [Point3f(cos(t), sin(t), 0) for t in range(0, 2pi; length = 64)]
    segpts = [Point3f(i, iseven(i) ? 0 : 1, 0) for i in 1:40]
    scatterpts = [Point3f(cos(t), sin(t), 0) for t in range(0, 2pi; length = 24)]
    img = [RGBAf(1, 0, 0, 1) for _ in 1:32, _ in 1:32]

    meshverts = [Point3f(-1, -1, 0), Point3f(1, -1, 0), Point3f(-1, 1, 0), Point3f(1, 1, 0)]
    meshfaces = [GLTriangleFace(1, 2, 3), GLTriangleFace(2, 4, 3)]

    cases = [
        ("image!", img,
         (f, d) -> image!(Axis(f[1, 1]), d; interpolate = false)),
        ("scatter!", scatterpts,
         (f, d) -> scatter!(LScene(f[1, 1]), d; color = :red, markersize = 20)),
        ("lines!", linepts,
         (f, d) -> lines!(LScene(f[1, 1]), d; color = :red, linewidth = 4)),
        ("linesegments!", segpts,
         (f, d) -> linesegments!(LScene(f[1, 1]), d; color = :red, linewidth = 4)),
        ("meshscatter!", scatterpts,
         (f, d) -> meshscatter!(LScene(f[1, 1]), d; color = :red, markersize = 0.2)),
        ("mesh!", meshverts,
         (f, d) -> mesh!(LScene(f[1, 1]), d, meshfaces; color = :red)),
    ]

    for (name, hostdata, plotit) in cases
        @testset "$name" begin
            onhost = redcount(f -> plotit(f, hostdata))
            ondevice = redcount(f -> plotit(f, todevice(hostdata)))
            # A plot that resolved but drew nothing is the failure this catches,
            # so the host count has to be non-trivial before comparing.
            @test onhost > 100
            @test ondevice == onhost
        end
    end
end

@testset "raster mode draws a mesh built on the device, from the device" begin
    # Positions, faces and normals all device arrays, the way a mesh extracted on
    # the GPU arrives. In RASTER mode this once drew nothing: the shadow-map
    # bounds iterated the positions, and the plot was logged and skipped.
    verts = [Point3f(-1, -1, 0), Point3f(1, -1, 0), Point3f(-1, 1, 0), Point3f(1, 1, 0)]
    fcs = [GLTriangleFace(1, 2, 3), GLTriangleFace(2, 4, 3)]
    nrm = fill(Vec3f(0, 0, 1), 4)
    onhost = GeometryBasics.Mesh(verts, fcs; normal = nrm)
    ondevice = GeometryBasics.Mesh(todevice(verts), todevice(fcs); normal = todevice(nrm))
    raster(m) = redcount(f -> mesh!(LScene(f[1, 1]), m; color = :red); rasterize = true)
    hostcount = raster(onhost)
    @test hostcount > 100
    @test raster(ondevice) == hostcount

    # Each step of that path stays on the device: no readback, no scalar loop.
    devfaces = todevice(fcs)
    @test GeometryBasics.decompose(GLTriangleFace, devfaces) === devfaces
    rf = RayMakie.raster_faces(devfaces)
    @test rf isa RayMakie.AbstractGPUArray
    @test Array(rf) == RayMakie.raster_faces(fcs) == UInt32[0, 1, 2, 1, 3, 2]
    @test RayMakie.vec3s(todevice(nrm)) isa RayMakie.AbstractGPUArray{Vec3f}
    @test RayMakie.local_bounds(todevice(verts)) == RayMakie.local_bounds(verts) ==
          Rect3f(Vec3f(-1, -1, 0), Vec3f(2, 2, 0))
end

@testset "raster mode draws meshscatter from device positions" begin
    # The instance bounds reduce Point3f on the device, through workgroup memory
    # holding `[1 x [3 x float]]`; Lava once emitted SPIR-V for that which
    # `spirv-val` rejected, and the plot was logged and skipped.
    pts = [Point3f(cos(t), sin(t), 0) for t in range(0, 2pi; length = 24)]
    raster(d) = redcount(f -> meshscatter!(LScene(f[1, 1]), d; color = :red, markersize = 0.2);
                         rasterize = true)
    hostcount = raster(pts)
    @test hostcount > 100
    @test raster(todevice(pts)) == hostcount
end

@testset "vertex normals on device match GeometryBasics" begin
    g = 20
    verts = [Point3f(i / g, j / g, 0.3f0 * sin(3f0 * i / g) * cos(3f0 * j / g))
             for j in 0:g for i in 0:g]
    vid(i, j) = j * (g + 1) + i + 1
    faces = GLTriangleFace[]
    for j in 0:(g - 1), i in 0:(g - 1)
        push!(faces, GLTriangleFace(vid(i, j), vid(i + 1, j), vid(i, j + 1)))
        push!(faces, GLTriangleFace(vid(i + 1, j), vid(i + 1, j + 1), vid(i, j + 1)))
    end

    hostnormals = GeometryBasics.normals(verts, faces, Vec3f)
    devnormals = Array(GeometryBasics.normals(todevice(verts), faces, Vec3f))

    # `≈`, not `==`: the device accumulation is atomic, so the summation order
    # for a vertex shared by six faces is not fixed.
    @test all(isapprox.(hostnormals, devnormals; atol = 1f-5))
    @test maximum(norm.(devnormals) .- 1f0) < 1f-5
    # An interior vertex really is shared, i.e. the contention is exercised.
    @test count(f -> vid(10, 10) in Base.to_index.(f), faces) == 6
end
