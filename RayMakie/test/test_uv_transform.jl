# `uv_transform` means the same on both paths.
#
# Makie samples a mesh's texture at `uv_transform * (u, v, 1)`; the raster path
# reads it as a uniform. The tracer ignored it, so a texture animated by moving
# `uv_transform` over a sheet of cells — a face picking its expression — showed
# the whole sheet when traced. It now bakes the transform into the uvs it is
# given (`traced_uvs`), and the default transform leaves them alone.

using Test, RayMakie, Makie
using Makie.GeometryBasics: GLTriangleFace, Mat

@testset "uv_transform picks the same cell raster and traced" begin
    C = Makie.Colors
    # A 2x2 sheet, row 1 at the top: red green / blue yellow.
    sheet = fill(C.RGBA{C.N0f8}(1, 0, 0, 1), 64, 64)
    sheet[1:32, 33:64] .= C.RGBA{C.N0f8}(0, 1, 0, 1)
    sheet[33:64, 1:32] .= C.RGBA{C.N0f8}(0, 0, 1, 1)
    sheet[33:64, 33:64] .= C.RGBA{C.N0f8}(1, 1, 0, 1)
    quad = Makie.GeometryBasics.Mesh(
        [Point3f(0, 0, 0), Point3f(1, 0, 0), Point3f(1, 1, 0), Point3f(0, 1, 0)],
        [GLTriangleFace(1, 2, 3), GLTriangleFace(1, 3, 4)];
        normal = fill(Vec3f(0, 0, 1), 4), uv = [Vec2f(0, 0), Vec2f(1, 0), Vec2f(1, 1), Vec2f(0, 1)])
    # Cell (r, c): the first component runs down the rows, the second along the columns.
    cell(r, c) = Mat{2, 3, Float32}(0, 1 / 2, -1 / 2, 0, r / 2, (c - 1) / 2)
    function scene(t)
        sc = Scene(; size = (64, 64), lights = [AmbientLight(RGBf(1, 1, 1))], backgroundcolor = RGBf(0, 0, 0))
        cam3d!(sc)
        mesh!(sc, quad; color = sheet, uv_transform = t, shading = NoShading)
        update_cam!(sc, Vec3f(0.5, 0.5, 2.2), Vec3f(0.5, 0.5, 0), Vec3f(0, 1, 0))
        return sc
    end
    # Which channels dominate the middle of the picture.
    function hue(img)
        px = img[28:36, 28:36]
        m = (sum(C.red, px), sum(C.green, px), sum(C.blue, px)) ./ length(px)
        return m .> 0.5 * maximum(m)
    end
    for ((r, c), want) in (((1, 1), (true, false, false)), ((1, 2), (false, true, false)),
                           ((2, 1), (false, false, true)), ((2, 2), (true, true, false)))
        raster = hue(Makie.colorbuffer(scene(cell(r, c)); backend = RayMakie, rasterize = true))
        traced = hue(Makie.colorbuffer(scene(cell(r, c)); backend = RayMakie, rasterize = false,
                                       samples = 16, max_depth = 1))
        @test raster == want
        @test traced == want
    end
end
