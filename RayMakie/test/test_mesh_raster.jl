# RASTER mode draws `mesh` through the port of GLMakie's mesh shader
# (src/overlay/mesh.jl). Before it, a raster mesh was one flat colour per vertex
# worked out on the CPU: unlit, no stroke, and a colormapped `color = values`
# came out as a single colour while the tracer mapped it.
#
# The strongest check is the original: with the film mapping switched off
# (`tonemap = nothing, gamma = nothing`), GLMakie and RASTER mode must draw the
# same picture of the same scene. `plane_scene` fills the frame, so the ambient
# term is compared on every pixel.

using Test, Makie, RayMakie, Hikari, GeometryBasics, Colors
import GLMakie
# Loading GLMakie activates it, and every later file's `getscreen` would then look
# for a GLMakie screen. The comparisons below name their backend.
RayMakie.activate!()
using Makie: Scene, cam3d!, cam2d!, mesh!, surface!, cameracontrols, update_cam!, Point2f, Point3f,
             Vec3f, Sphere, RGBf, Rect2f, PointLight, AmbientLight, DirectionalLight,
             EnvironmentLight, NoShading

raster_screen(scene; kw...) =
    RayMakie.Screen(scene; samples = 1, max_depth = 1, hw_accel = false,
                    rasterize = true, kw...)

lum(c) = 0.2126f0 * red(c) + 0.7152f0 * green(c) + 0.0722f0 * blue(c)
backdrop(c) = green(c) > 0.9 && red(c) < 0.1 && blue(c) < 0.1   # the scenes' pure green

function sphere_scene(; lights, color, size = (96, 96), kw...)
    sc = Scene(; size, lights, backgroundcolor = RGBf(0, 1, 0))
    cam3d!(sc)
    msh = GeometryBasics.normal_mesh(Sphere(Point3f(0), 1f0))
    c = color === :height ? [p[3] for p in GeometryBasics.coordinates(msh)] : color
    mesh!(sc, msh; color = c, fxaa = false, kw...)
    cam = cameracontrols(sc)
    cam.eyeposition[] = Vec3f(0, -6, 3)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 45
    update_cam!(sc, cam)
    return sc
end

function plane_scene(; lights, size = (96, 96))
    sc = Scene(; size, lights, backgroundcolor = RGBf(0, 1, 0))
    cam3d!(sc)
    ps = [Point3f(-50, -50, 0), Point3f(50, -50, 0), Point3f(50, 50, 0), Point3f(-50, 50, 0)]
    msh = GeometryBasics.Mesh(ps, [GLTriangleFace(1, 2, 3), GLTriangleFace(1, 3, 4)];
                              normal = fill(Vec3f(0, 0, 1), 4))
    mesh!(sc, msh; color = :orange, fxaa = false)
    cam = cameracontrols(sc)
    cam.eyeposition[] = Vec3f(0, -3, 3)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 45
    update_cam!(sc, cam)
    return sc
end

function quads_scene(; strokewidth, size = (120, 80))
    sc = Scene(; size, backgroundcolor = :white)
    cam2d!(sc)
    ps = [Point2f(x, y) for y in 0:1 for x in 0:2]
    quads = [QuadFace{Int}(1, 2, 5, 4), QuadFace{Int}(2, 3, 6, 5)]
    mesh!(sc, GeometryBasics.Mesh(ps, quads); color = :lightblue, shading = NoShading,
          strokewidth, strokecolor = :black, strokeedges = :all, fxaa = false)
    update_cam!(sc, Rect2f(-0.2, -0.2, 2.4, 1.4))
    return sc
end

# A surface in RASTER mode is Makie's `surface_as_mesh` through the same shader.
# It had a flat, unlit pipeline of its own until 2026-09-25. A colour matrix of
# the grid's size pins the half-texel shift GLMakie's surface.vert applies: without
# it every colour smears half a cell towards the far edge, which a checkerboard
# shows on 11% of the pixels and a smooth gradient hides.
function surface_scene(; lights, size = (96, 96), kw...)
    sc = Scene(; size, lights, backgroundcolor = RGBf(0, 1, 0))
    cam3d!(sc)
    zs = [Float32(0.6 * sin(i * 0.8) * cos(j * 0.6)) for i in 1:8, j in 1:6]
    surface!(sc, range(-1, 1, length = 8), range(-1, 1, length = 6), zs; fxaa = false, kw...)
    cam = cameracontrols(sc)
    cam.eyeposition[] = Vec3f(2.5, -3, 2.5)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 45
    update_cam!(sc, cam)
    return sc
end

"""Fraction of pixels differing by more than `tol` in any channel, and the mean difference."""
function disagreement(a, b; tol = 0.1)
    size(a) == size(b) || error("images differ in size: $(size(a)) vs $(size(b))")
    bad = 0; total = 0.0
    for (p, q) in zip(a, b)
        d = max(abs(Float32(red(p)) - Float32(red(q))), abs(Float32(green(p)) - Float32(green(q))),
                abs(Float32(blue(p)) - Float32(blue(q))))
        bad += d > tol
        total += d
    end
    return (fraction = bad / length(a), mean = total / length(a))
end

# A scene's lights through the same steps as its compute graph
# (`register_raster_lights!`): its sky lights, their shapes at unit intensity,
# their SH, then the SH at their intensities.
function sky_sh(lights)
    sky = RayMakie.environment_lights(lights)
    return RayMakie.environment_sh(sky, map(RayMakie.unit_sh ∘ RayMakie.unit_intensity, sky))
end

@testset "raster mesh: GLMakie's mesh shader" begin
    @testset "an environment's irradiance" begin
        # A white map of intensity 1 lights every normal to exactly 1: the
        # identity the spherical-harmonic projection has to keep.
        sh, has = sky_sh([EnvironmentLight(1f0, fill(RGBf(1, 1, 1), 64, 64))])
        @test has == 1
        for n in (Vec3f(0, 0, 1), Vec3f(1, 0, 0), Vec3f(0, -1, 0), RayMakie._unit(Vec3f(1, 1, 1)))
            @test isapprox(RayMakie.env_irradiance(sh, n), Vec3f(1, 1, 1); atol = 0.02)
        end
        # A sky and no ground: up is fully lit and down not at all, which nine
        # coefficients reproduce exactly for a hemisphere.
        n = 64
        sky = [Hikari.equal_area_square_to_sphere(Point2f((i - 0.5f0) / n, (j - 0.5f0) / n))[3] > 0 ?
               RGBf(1, 1, 1) : RGBf(0, 0, 0) for j in 1:n, i in 1:n]
        sh2, _ = sky_sh([EnvironmentLight(1f0, sky)])
        @test RayMakie.env_irradiance(sh2, Vec3f(0, 0, 1))[1] > 0.9
        @test RayMakie.env_irradiance(sh2, Vec3f(0, 0, -1))[1] < 0.1
        # No environment light, no environment term.
        @test sky_sh([PointLight(RGBf(1, 1, 1), Point3f(0))])[2] == 0
    end

    @testset "a colormapped mesh maps per vertex" begin
        # The CPU path knew colours and single colours, not values through a
        # colormap, so `color = values` drew one colour.
        sc = sphere_scene(; lights = Makie.AbstractLight[], color = :height,
                          colormap = [:blue, :red], shading = NoShading)
        px = filter(!backdrop, Makie.colorbuffer(raster_screen(sc)))
        @test count(c -> blue(c) > 0.6 && red(c) < 0.4, px) > 50
        @test count(c -> red(c) > 0.6 && blue(c) < 0.4, px) > 50
    end

    @testset "a lit mesh is shaded" begin
        # Unlit, every pixel of a uniformly coloured sphere had the same value.
        sc = sphere_scene(; lights = [PointLight(RGBf(60, 60, 60), Point3f(4, -4, 6))], color = :white)
        l = lum.(filter(!backdrop, Makie.colorbuffer(raster_screen(sc; tonemap = nothing, gamma = nothing))))
        @test length(l) > 500
        @test maximum(l) - minimum(l) > 0.3
    end

    @testset "the edge stroke" begin
        dark(c) = lum(c) < 0.2
        stroked = count(dark, Makie.colorbuffer(RayMakie.Screen(quads_scene(; strokewidth = 4))))
        plain = count(dark, Makie.colorbuffer(RayMakie.Screen(quads_scene(; strokewidth = 0))))
        @test stroked > 500
        @test plain < 20
    end

    @testset "the same picture as GLMakie" begin
        # Each scene is built twice: a plot a backend has displayed carries that
        # backend's nodes.
        sun = DirectionalLight(RGBf(0.8, 0.8, 0.8), Vec3f(-1, 1, -1))
        scenes = [
            "fast shading" => () -> sphere_scene(; color = :orange, lights = [sun]),
            "ambient" => () -> plane_scene(; lights = [AmbientLight(RGBf(0.3, 0.3, 0.3)), sun]),
            "colormapped" => () -> sphere_scene(; lights = Makie.AbstractLight[], color = :height,
                                                 shading = NoShading),
            "stroked quads" => () -> quads_scene(; strokewidth = 4),
            "lit surface" => () -> surface_scene(; lights = [AmbientLight(RGBf(0.3, 0.3, 0.3)), sun]),
            "surface, one colour per vertex" => () -> surface_scene(; lights = Makie.AbstractLight[],
                color = [isodd(i + j) ? RGBf(1, 0.2, 0) : RGBf(0, 0.2, 1) for i in 1:8, j in 1:6],
                shading = NoShading),
            "stroked surface" => () -> surface_scene(; lights = [sun], strokewidth = 2,
                                                      strokecolor = :black),
        ]
        for (label, make) in scenes
            gl = Makie.colorbuffer(make(); backend = GLMakie, px_per_unit = 1)
            rm = Makie.colorbuffer(raster_screen(make(); tonemap = nothing, gamma = nothing))
            d = disagreement(gl, rm)
            @testset "$label" begin
                @test d.fraction < 0.03
                @test d.mean < 0.02
            end
        end
    end
end

# ── FXAA ────────────────────────────────────────────────────────────────────
#
# The raster path had no anti-aliasing for meshes at all. GLMakie runs FXAA over
# the plots with `fxaa = true` (mesh, surface and meshscatter by default), so a
# rasterised surface came out with every edge a hard stair. Each stage now writes
# its plot's flag into a second attachment and one fullscreen pass runs the same
# FXAA 3.11 over the frame (overlay/fxaa.jl). An unlit sphere on a flat backdrop
# isolates it: the edge is the only thing FXAA can change.
function flat_sphere(; fxaa)
    sc = Scene(; size = (96, 96), lights = Makie.AbstractLight[], backgroundcolor = RGBf(0, 1, 0))
    cam3d!(sc)
    mesh!(sc, GeometryBasics.normal_mesh(Sphere(Point3f(0), 1f0)); color = :orange,
          shading = NoShading, fxaa)
    cam = cameracontrols(sc)
    cam.eyeposition[] = Vec3f(0, -6, 3)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 45
    update_cam!(sc, cam)
    return sc
end

# With `fxaa = true`, lines.frag and distance_shape.frag draw a HARD edge and
# leave it to FXAA.
function stroke_scene(kind; fxaa)
    sc = Scene(; size = (120, 80), backgroundcolor = :white)
    cam2d!(sc)
    xs = range(0, 2π, length = 40)
    if kind === :lines
        lines!(sc, xs, sin.(xs); color = :black, linewidth = 3, fxaa)
    else
        scatter!(sc, xs[1:4:end], sin.(xs[1:4:end]); color = :black, markersize = 12,
                 strokewidth = 2, strokecolor = :red, fxaa)
    end
    update_cam!(sc, Rect2f(-0.2, -1.3, 6.7, 2.6))
    return sc
end

orange_px(c) = red(c) > 0.98 && abs(green(c) - 0.647) < 0.02 && blue(c) < 0.02
blended(img) = count(c -> !backdrop(c) && !orange_px(c), img)
unmapped(sc; kw...) = Makie.colorbuffer(raster_screen(sc; tonemap = nothing, gamma = nothing, kw...))

@testset "FXAA, as GLMakie applies it" begin
    gl = Makie.colorbuffer(flat_sphere(fxaa = true); backend = GLMakie, px_per_unit = 1)
    rm = unmapped(flat_sphere(fxaa = true))
    @test blended(rm) > 50
    d = disagreement(gl, rm; tol = 0.02)
    @test d.fraction < 0.005
    # A plot that says `fxaa = false` keeps its hard edge, and so does every plot
    # on a screen that turns FXAA off.
    @test blended(unmapped(flat_sphere(fxaa = false))) == 0
    @test blended(unmapped(flat_sphere(fxaa = true); fxaa = false)) == 0

    @testset "$kind with `fxaa = true`" for kind in (:lines, :scatter)
        gl = Makie.colorbuffer(stroke_scene(kind; fxaa = true); backend = GLMakie, px_per_unit = 1)
        d = disagreement(gl, unmapped(stroke_scene(kind; fxaa = true)); tol = 0.02)
        @test d.fraction < 0.005
    end
end

# A glowing sheet with no surface (a `NullMaterial` emitting an image) over a
# lit grey one. The tracer adds the glow to what is behind it before the film
# maps the sum; the raster path maps them apart and blends. Added after the
# film, a pale green glow over grey clipped to white.
function quad(z; size = 4f0)
    h = size / 2
    GeometryBasics.Mesh(Point3f[(-h, -h, z), (h, -h, z), (h, h, z), (-h, h, z)],
                        GLTriangleFace[(1, 2, 3), (1, 3, 4)];
                        normal = fill(Vec3f(0, 0, 1), 4), uv = Vec2f[(0, 0), (1, 0), (1, 1), (0, 1)])
end

function glow_over_grey()
    sc = Scene(; size = (64, 64), backgroundcolor = RGBf(0, 0, 0), lights = [AmbientLight(RGBf(0.3, 0.3, 0.3))])
    cam3d!(sc; center = false)
    mesh!(sc, quad(0f0); material = Hikari.Diffuse(Kd = (0.5, 0.5, 0.5)))
    tint = [Hikari.RGBSpectrum(0.15f0, 0.45f0, 0.22f0, 1f0) for _ in 1:4, _ in 1:4]
    glow = Hikari.MediumInterface(Hikari.NullMaterial();
        emission = Hikari.Emissive(Le = Hikari.Texture(tint), scale = 2f0, two_sided = true))
    mesh!(sc, quad(0.01f0); material = glow)
    update_cam!(sc, cameracontrols(sc), Vec3f(0, 0, 3), Vec3f(0), Vec3f(0, 1, 0))
    return sc
end

@testset "a glow over a surface keeps its colour" begin
    raster = Makie.colorbuffer(raster_screen(glow_over_grey()))[32, 32]
    traced = Makie.colorbuffer(RayMakie.Screen(glow_over_grey(); samples = 64, max_depth = 2,
                                               hw_accel = false))[32, 32]
    # measured: raster (0.75, 0.96, 0.84), traced (0.84, 0.94, 0.88); added: white
    @test green(raster) - red(raster) > 0.15
    @test abs(red(raster) - red(traced)) < 0.12
    @test abs(green(raster) - green(traced)) < 0.12
    @test abs(blue(raster) - blue(traced)) < 0.12
end

# A glowing image drawn smaller than it is: a line one texel wide, at a slant, in
# an image four times the size of the frame. Point-sampled, a pixel sees the
# line only where its centre lands within a texel of it, and 23 of the 64 rows
# came out empty: a dotted line. Filtered over each pixel's footprint, every
# row has its piece.
function slanted_line_glow(; n = 256, px = 64)
    sc = Scene(; size = (px, px), backgroundcolor = RGBf(0, 0, 0), lights = [AmbientLight(RGBf(0, 0, 0))])
    cam3d!(sc; center = false)
    off, on = Hikari.RGBSpectrum(0f0, 0f0, 0f0, 1f0), Hikari.RGBSpectrum(0f0, 1f0, 0f0, 1f0)
    img = [j == round(Int, 0.61 * i) + 40 ? on : off for i in 1:n, j in 1:n]
    glow = Hikari.MediumInterface(Hikari.NullMaterial();
        emission = Hikari.Emissive(Le = Hikari.Texture(img), scale = 4f0, two_sided = true))
    mesh!(sc, quad(0f0); material = glow)
    cam = cameracontrols(sc)
    cam.fov[] = 45
    # The quad exactly fills the frame.
    update_cam!(sc, cam, Vec3f(0, 0, 2f0 / tand(22.5f0)), Vec3f(0), Vec3f(0, 1, 0))
    return sc
end

@testset "a minified glowing line stays a line" begin
    img = Makie.colorbuffer(raster_screen(slanted_line_glow()))
    empty_rows = count(i -> maximum(c -> green(c), img[i, :]) <= 0.05, axes(img, 1))
    @test empty_rows == 0
end
