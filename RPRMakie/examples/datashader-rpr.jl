using DelimitedFiles, GLMakie
GLMakie.activate!() # hide
# For saving/showing/inlining into documentation we need to disable async calculation.
Makie.set_theme!(DataShader = (; async_latest = false))
airports = Point2f.(eachrow(readdlm(assetpath("airportlocations.csv"))))
(xmin, ymin), (xmax, ymax) = extrema(xx)

xx = Rect2f(points)
all(x -> x in xx, points)


canvas = Canvas(Rect2f(points))
aggregate!(canvas, points);

m = collect(Makie.get_aggregation(canvas))

(xmin, ymin), (xmax, ymax) = map(x -> x ./ widths(canvas.bounds), extrema(canvas.bounds))

xw, yw = 1 ./ size(m)
maxi = maximum(mscaled)
GLMakie.activate!()
radiance = 50
lights = [
    EnvironmentLight(0.5, load(RPR.assetpath("studio026.exr"))),
    PointLight(Vec3f(0, 0, 2), RGBf(radiance, radiance, radiance)),
]
mscaled = m ./ widths(canvas.bounds)[1]
recmesh = GeometryBasics.normal_mesh(Rect3f(Vec3f(-0.5), Vec3f(1)))
RPRMakie.activate!(plugin = RPR.Northstar, iterations = 1, resource = RPR.RPR_CREATION_FLAGS_ENABLE_GPU1)
f, ax, pl = meshscatter(
    xmin .. xmax, ymin .. ymax, mscaled;
    axis = (; type = LScene, show_axis = false, scenekw = (; lights = lights)),
    marker = recmesh,
    color = mscaled,
    colorrange = Vec2f(0.000001, maxi),
    lowclip = (:blue, 0.1),
    colormap = [:white, :red],
    material = (; type = :Microfacet, color = :gray, roughness = 0.2, ior = 1.39),
    markersize = Vec3f.(xw, yw, vec(mscaled))
)
ax.scene |> display
display(f; backend = GLMakie)
using RPRMakie, FileIO

RPRMakie.activate!(plugin = RPR.Tahoe, iterations = 1, resource = RPR.RPR_CREATION_FLAGS_ENABLE_GPU1)
RPRMakie.replace_scene_rpr!(ax.scene)


l = lights[2]

l.position[] = Vec3f(xmin + xmax / 2, ymin + ymax / 2, widths(canvas.bounds)[1])
l.radiance[] = RGBf(500, 500, 500)

pl.colorrange[] = Vec2f(0.000001, maxi)
