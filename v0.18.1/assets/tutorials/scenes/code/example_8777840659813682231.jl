# This file was generated, do not modify it. # hide
__result = begin # hide
    using MeshIO, FileIO, GeometryBasics

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
    "arm_right" => Vec3f(0.0000, -0.9828, 0.1848),
    "arm_left" => Vec3f(0.0000, 0.9828, 0.1848),
    "leg_right" => Vec3f(0, -1, 0),
    "leg_left" => Vec3f(0, 1, 0),
)

function plot_part!(scene, parent, name::String)
    # load the model file
    m = load(assetpath("lego_figure_" * name * ".stl"))
    # look up color
    color = colors[split(name, "_")[1]]
    # Create a child transformation from the parent
    child = Transformation(parent)
    # get the transformation of the parent
    ptrans = Makie.transformation(parent)
    # get the origin if available
    origin = get(origins, name, nothing)
    # center the mesh to its origin, if we have one
    if !isnothing(origin)
        centered = m.position .- origin
        m = GeometryBasics.Mesh(meta(centered; normals=m.normals), faces(m))
        translate!(child, origin)
    else
        # if we don't have an origin, we need to correct for the parents translation
        translate!(child, -ptrans.translation[])
    end
    # plot the part with transformation & color
    return mesh!(scene, m; color=color, transformation=child)
end

function plot_lego_figure(s, floor=true)
    # Plot hierarchical mesh and put all parts into a dictionary
    figure = Dict()
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
    floor && mesh!(s, Rect3f(Vec3f(-400, -400, -2), Vec3f(800, 800, 2)), color=:white)
    return figure
end
App() do session
    s = Scene(resolution=(500, 500))
    cam3d!(s)
    figure = plot_lego_figure(s, false)
    bodies = [
        "arm_left", "arm_right",
        "leg_left", "leg_right"]
    sliders = map(bodies) do name
        slider = if occursin("arm", name)
            JSServe.Slider(-60:4:60)
        else
            JSServe.Slider(-30:4:30)
        end
        rotvec = rotation_axes[name]
        bodymesh = figure[name]
        on(slider) do val
            rotate!(bodymesh, rotvec, deg2rad(val))
        end
        DOM.div(name, slider)
    end
    center!(s)
    JSServe.record_states(session, DOM.div(sliders..., s))
end
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide