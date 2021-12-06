using NCDatasets, ColorSchemes, RPRMakie
using ImageShow

# Taken from https://lazarusa.github.io/BeautifulMakie/GeoPlots/topography/
cmap = dataset = Dataset(joinpath(@__DIR__, "ETOPO1_halfdegree.nc"))
lon = dataset["lon"][:]
lat = dataset["lat"][:]
data = Float32.(dataset["ETOPO1avg"][:, :])

function setup_material!(material, matsys, data_norm)
    material.reflection_weight = Vec4f(1)
    material.reflection_color = Vec3f(0.5, 0.5, 1.0)
    material.reflection_metalness = Vec3f(0)
    material.reflection_ior = Vec3f(1.4)
    material.diffuse_weight = Vec4f(1)
    emission_weight = map(data_norm) do i
        c = i < 0.7 ? 0.0 : i
        return RGBf(c, c, c)
    end
    material.emission_weight = RPR.Texture(matsys, emission_weight')
    emission_color = map(data_norm) do i
        em = i * 2
        return RGBf(em * 2.0, em * 0.4, em * 0.3)
    end
    material.emission_color = RPR.Texture(matsys, emission_color')
    return
end

image = begin
    fig = Figure(; resolution=(2000, 800))
    radiance = 30000
    lights = [EnvironmentLight(1.0, load(RPR.assetpath("studio026.exr"))),
              PointLight(Vec3f(0, 100, 100), RGBf(radiance, radiance, radiance))]

    ax = LScene(fig[1, 1]; show_axis=false, scenekw=(lights=lights,))
    screen = RPRScreen(ax.scene; plugin=RPR.Northstar, iterations=400)

    ctx = screen.context
    matsys = screen.matsys

    mini, maxi = extrema(data)
    data_norm = ((data .- mini) ./ (maxi - mini))
    material = RPR.UberMaterial(matsys)
    setup_material!(material, matsys, data_norm)
    # Makie overwrites e.g. color property, so we need to set color=nothing
    pltobj = surface!(ax, lon, lat, data_norm .* 20; material=material, colormap=[:black, :white, :brown],
                      colorrange=(0.2, 0.8) .* 20)

    cam = cameracontrols(ax.scene)
    cam.eyeposition[] = Vec3f(3, -300, 300)
    cam.lookat[] = Vec3f(0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 23
    colorbuffer(screen)
end

save("topographie.png", image)
