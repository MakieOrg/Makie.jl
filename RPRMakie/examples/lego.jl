# Example inspiration and Lego model by https://github.com/Kevin-Mattheus-Moerman
# https://twitter.com/KMMoerman/status/1417759722963415041
using MeshIO, FileIO, GeometryBasics, RPRMakie

colors = Dict(
    "eyes" => "#000",
    "belt" => "#000059",
    "arm" => "#009925",
    "leg" => "#3369E8",
    "torso" => "#D50F25",
    "head" => "yellow",
    "hand" => "yellow"
)

origins = Dict(
    "arm_right" => Point3f(0.1427, -6.2127, 5.7342),
    "arm_left" => Point3f(0.1427, 6.2127, 5.7342),
    "leg_right" => Point3f(0, -1, -8.2),
    "leg_left" => Point3f(0, 1, -8.2),
)

rotation_axes = Dict(
    "arm_right" => Vec3f(0.0, -0.9828, 0.1848),
    "arm_left" => Vec3f(0.0, 0.9828, 0.1848),
    "leg_right" => Vec3f(0, -1, 0),
    "leg_left" => Vec3f(0, 1, 0),
)

function plot_part!(scene, parent, name::String)
    m = load(assetpath("lego_figure_" * name * ".stl"))
    color = colors[split(name, "_")[1]]
    trans = Transformation(parent)
    ptrans = Makie.transformation(parent)
    origin = get(origins, name, nothing)
    if !isnothing(origin)
        centered = m.position .- origin
        m = GeometryBasics.Mesh(meta(centered; normals = m.normals), faces(m))
        translate!(trans, origin)
    else
        translate!(trans, -ptrans.translation[])
    end
    return mesh!(scene, m; color = color, transformation = trans)
end

function plot_lego_figure(s, floor = true)
    # Plot hierarchical mesh!
    figure = Dict()
    # Plot hierarchical mesh!
    figure["torso"] = plot_part!(s, s, "torso")
    figure["head"] = plot_part!(s, figure["torso"], "head")
    figure["eyes_mouth"] = plot_part!(s, figure["head"], "eyes_mouth")
    figure["arm_right"] = plot_part!(s, figure["torso"], "arm_right")
    figure["hand_right"] = plot_part!(s, figure["arm_right"], "hand_right")
    figure["arm_left"] = plot_part!(s, figure["torso"], "arm_left")
    figure["hand_left"] = plot_part!(s, figure["arm_left"], "hand_left")
    figure["belt"] = plot_part!(s, figure["torso"], "belt")
    figure["leg_right"] = plot_part!(s, figure["belt"], "leg_right")
    figure["leg_left"] = plot_part!(s, figure["belt"], "leg_left")
    # lift the little guy up
    translate!(figure["torso"], 0, 0, 20)
    # add some floor
    floor && mesh!(s, Rect3f(Vec3f(-400, -400, -2), Vec3f(800, 800, 2)), color = :white)
    return figure
end

RPRMakie.activate!(iterations = 200, plugin = RPR.Northstar)
radiance = 50000
lights = [
    EnvironmentLight(1.5, rotl90(load(assetpath("sunflowers_1k.hdr"))')),
    PointLight(Vec3f(50, 0, 200), RGBf(radiance, radiance, radiance * 1.1)),
]
s = Scene(size = (500, 500), lights = lights)

cam3d!(s)
c = cameracontrols(s)
c.near[] = 5
c.far[] = 1000
update_cam!(s, c, Vec3f(100, 30, 80), Vec3f(0, 0, -10))
figure = plot_lego_figure(s)

rot_joints_by = 0.25 * pi
total_translation = 50
animation_strides = 10

a1 = LinRange(0, rot_joints_by, animation_strides)
angles = [a1; reverse(a1[1:(end - 1)]); -a1[2:end]; reverse(-a1[1:(end - 1)]);]
nsteps = length(angles); #Number of animation steps
translations = LinRange(0, total_translation, nsteps)
s

@time Makie.record(s, "lego_walk.mp4", zip(translations, angles)) do (translation, angle)
    # Rotate right arm + hand
    for name in ["arm_left", "arm_right", "leg_left", "leg_right"]
        rotate!(figure[name], rotation_axes[name], angle)
    end
    translate!(figure["torso"], translation, 0, 20)
end
