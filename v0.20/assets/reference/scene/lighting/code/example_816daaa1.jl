# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using FileIO, GeometryBasics, LinearAlgebra, GLMakie

# Create mesh from RectLight parameters
function to_mesh(l::RectLight)
    n = -normalize(cross(l.u1[], l.u2[]))
    p = l.position[] - 0.5 * l.u1[] - 0.5 * l.u2[]
    positions = [p, p + l.u1[], p + l.u2[], p + l.u1[] + l.u2[]]
    faces = GLTriangleFace[(1,2,3), (2,3,4)]
    normals = [n,n,n,n]
    return GeometryBasics.Mesh(meta(positions, normals = normals), faces)
end

fig = Figure(backgroundcolor = :black)

# Prepare lights
lights = Makie.AbstractLight[
    AmbientLight(RGBf(0.1, 0.1, 0.1)),
    RectLight(RGBf(0.9, 1, 0.8), Rect2f(-1.9, -1.9, 1.8, 1.8)),
    RectLight(RGBf(0.9, 1, 0.8), Rect2f(-1.9,  0.1, 1.8, 1.8)),
    RectLight(RGBf(0.9, 1, 0.8), Rect2f( 0.1,  0.1, 1.8, 1.8)),
    RectLight(RGBf(0.9, 1, 0.8), Rect2f( 0.1, -1.9, 1.8, 1.8)),
]

for l in lights
    if l isa RectLight
        angle = pi/4
        p = l.position[]
        Makie.rotate!(l, Vec3f(0, 1, 0), angle)

        p = 3 * Vec3f(1+sin(angle), 0, cos(angle)) +
            p[1] * normalize(l.u1[]) +
            p[2] * normalize(l.u2[])
        translate!(l, p)
    end
end

# Set scene
scene = LScene(
    fig[1, 1], show_axis = false,
    scenekw=(lights = lights, backgroundcolor = :black, center = false),
)

# floor
msh = mesh!(scene, Rect3f(Point3f(-10, -10, 0.01), Vec3f(20, 20, 0.02)), color = :white)
translate!(msh, 0, 0, -5)

# Cat
cat_mesh = FileIO.load(Makie.assetpath("cat.obj"))
cat_texture = FileIO.load(Makie.assetpath("diffusemap.png"))
p2 = mesh!(scene, cat_mesh, color = cat_texture)
Makie.rotate!(p2, Vec3f(1,0,0), pi/2)
translate!(p2, -2, 2, -5)
scale!(p2, Vec3f(4))

# Window/light source markers
for l in lights
    if l isa RectLight
        mesh!(to_mesh(l), color = :white, backlight = 1)
    end
end

# place camera
update_cam!(scene.scene, Vec3f(1.5, -13, 2), Vec3f(1, -2, 0), Vec3f(0, 0, 1))

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_816daaa1_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_816daaa1.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide