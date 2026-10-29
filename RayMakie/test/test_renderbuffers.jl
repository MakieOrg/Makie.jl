# The HDR capture (`renderbuffers`): linear radiance, guides, coverage and the
# raster overlay as device planes, x-by-y. It used to download every film and
# copy it pixel by pixel on the host, and to download and re-upload the whole
# output around the overlay pass; it is assembled on the device now and nothing
# comes to the host.

using Test, Makie, RayMakie, Hikari, GeometryBasics

function capturescene()
    root = Scene(; size = (96, 64), backgroundcolor = RGBAf(0.2, 0.3, 0.4, 0.0), camera = campixel!)
    sub = Scene(root; viewport = Rect2i(20, 8, 64, 48), backgroundcolor = RGBAf(0.1, 0.1, 0.1, 0.0),
                lights = [PointLight(RGBf(30, 30, 30), Vec3f(2, -3, 3)), AmbientLight(RGBf(0.1, 0.1, 0.1))])
    cam3d!(sub; center = false)
    mesh!(sub, Sphere(Point3f(0), 1.0f0); material = Hikari.Diffuse(color = (0.8, 0.2, 0.2)))
    update_cam!(sub, cameracontrols(sub), Vec3f(0, -4, 1), Vec3f(0), Vec3f(0, 0, 1))
    lines!(root, Point2f[(4, 4), (90, 60)]; color = :yellow, linewidth = 3)
    return root
end

@testset "the HDR capture is assembled on the device" begin
    screen = RayMakie.Screen(capturescene(); samples = 4, max_depth = 2, hw_accel = false,
                             rasterize = false, denoise = false)
    p = RayMakie.renderbuffers(screen; samples = 4)
    @test all(k -> !(getproperty(p, k) isa Array), (:color, :albedo, :normal, :depth, :coverage, :overlay))
    @test all(k -> size(getproperty(p, k)) == (96, 64), (:color, :albedo, :normal, :depth, :coverage, :overlay))
    color, coverage, depth, overlay = Array(p.color), Array(p.coverage), Array(p.depth), Array(p.overlay)
    # the traced sphere sits in the sub-scene's viewport, x 21:84 and y 9:56
    # (rows from the top: 64 - 8 - 48 + 1 = 9), covered and lit
    hit = findall(d -> !Hikari.missed(d), depth)
    @test !isempty(hit)
    @test all(I -> 21 <= I[1] <= 84 && 9 <= I[2] <= 56, hit)
    # covered where hit, fully inside the silhouette and partly at its edge (the
    # postprocess's hit fraction over 3×3 neighbours)
    @test all(I -> coverage[I] > 0, hit)
    @test count(I -> coverage[I] == 1, hit) > length(hit) ÷ 2
    @test maximum(c -> c.r, color[hit]) > 0.1
    # transparent backgrounds: nothing covers the frame outside the sphere
    @test coverage[1, 1] == 0
    # the line is in the overlay plane alone, display-referred and premultiplied
    @test count(o -> o.alpha > 0.5, overlay) > 50
    @test overlay[3, 3].alpha == 0
    # a second capture of the same films, without tracing, is the same frame
    again = RayMakie.capturebuffers(screen)
    @test Array(again.color) == color && Array(again.overlay) == overlay
    close(screen)
end
