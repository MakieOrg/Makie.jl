using NCDatasets, ColorSchemes, RPRMakie
using ImageShow, FileIO

# Taken from https://lazarusa.github.io/BeautifulMakie/GeoPlots/topography/
cmap = dataset = Dataset(joinpath(@__DIR__, "ETOPO1_halfdegree.nc"))
lon = dataset["lon"][:]
lat = dataset["lat"][:]
data = Float32.(dataset["ETOPO1avg"][:, :])

function glow_material(data_normed)
    emission_weight = map(data_normed) do i
        return Float32(i < 0.7 ? 0.0 : i)
    end
    emission_color = map(data_normed) do i
        em = i * 2
        return RGBf(em * 2.0, em * 0.4, em * 0.3)
    end

    return (
        reflection_weight = 1,
        reflection_color = RGBf(0.5, 0.5, 1.0),
        reflection_metalness = 0,
        reflection_ior = 1.4,
        diffuse_weight = 1,
        emission_weight = emission_weight',
        emission_color = emission_color',
    )
end

RPRMakie.activate!(iterations = 32, plugin = RPR.Northstar)
fig = Figure(; size = (2000, 800))
radiance = 30000
lights = [
    EnvironmentLight(1.0, load(RPR.assetpath("studio026.exr"))),
    PointLight(Vec3f(0, 100, 100), RGBf(radiance, radiance, radiance)),
]

ax = LScene(fig[1, 1]; show_axis = false, scenekw = (lights = lights,))

mini, maxi = extrema(data)
data_normed = ((data .- mini) ./ (maxi - mini))

material = glow_material(data_normed)

pltobj = surface!(
    ax, lon, lat, data_normed .* 20;
    material = material, colormap = [:black, :white, :brown],
    colorrange = (0.2, 0.8) .* 20
)
# Set the camera to a nice angle
cam = cameracontrols(ax.scene)
cam.eyeposition[] = Vec3f(3, -300, 300)
cam.lookat[] = Vec3f(0)
cam.upvector[] = Vec3f(0, 0, 1)
cam.fov[] = 23

save("earth.png", ax.scene)
