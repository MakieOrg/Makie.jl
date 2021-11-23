### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ 75852c20-4878-11ec-0f17-77727b908d78
using Pkg; Pkg.activate("C:\\Users\\sdani\\MakieDev")

# ╔═╡ f2f63242-e0ba-4fd6-a454-7fd0952236ad
using Revise, GLMakie

# ╔═╡ d5201580-108d-42e2-8eb5-c4489cc2ceb4
begin 
	using WGLMakie, JSServe
	wgl = WGLMakie.activate!()
	Page(offline=true, exportable=true)
end

# ╔═╡ abe526e5-6d36-4ac5-876f-ebd65ff8a05f
using RPRMakie

# ╔═╡ ba3bb4b5-73b6-44b1-ab84-f57406058479
begin
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
	    m = load(assetpath("lego_figure_" * name * ".stl"))
	    color = colors[split(name, "_")[1]]
	    trans = Transformation(parent)
	    ptrans = Makie.transformation(parent)
	    origin = get(origins, name, nothing)
	    if !isnothing(origin)
	        centered = m.position .- origin
	        m = GeometryBasics.Mesh(meta(centered; normals=m.normals), faces(m))
	        translate!(trans, origin)
	    else
	        translate!(trans, -ptrans.translation[])
	    end
	    return mesh!(scene, m; color=color, transformation=trans)
	end
	function plot_lego_figure(s, floor=true)
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
	    floor && mesh!(s, Rect3f(Vec3f(-400, -400, -2), Vec3f(800, 800, 2)), color=:white)
		return figure
	end
end

# ╔═╡ 87021c46-5fcd-4995-80fc-bb49fd194978
gl = GLMakie.activate!(); scene = Scene(;
    # clear everything behind scene
    clear = true,
    # the camera struct of the scene.
    visible = true,
    ssao = Makie.SSAO(),
    # Creates lights from theme, which right now defaults to `
	# set_theme!(lightposition=:eyeposition, ambient=RGBf(0.5, 0.5, 0.5))`
    lights = Makie.automatic,
    backgroundcolor = :gray,
	resolution = (500, 500)
)

# ╔═╡ 09fcfad7-0c3b-4910-b6ad-ba8e2f6b24f2
md"""
By default, the scenes goes from -1 to 1.
So to draw a rectangle outlining the screen, the following rectangle does the job: 
"""

# ╔═╡ 98c046a9-9a4e-4dc2-ad5a-205805064a03
lines!(scene, Rect2f(-1, -1, 2, 2), linewidth=5, color=:black); scene

# ╔═╡ 8bae338c-1041-4cda-be49-2328f0d01d9c
md"""
this is, because the projection matrix and view matrix are the identity matrix by default, and Makie's default unit space is what's called `Clip space` in the OpenGL world
"""

# ╔═╡ 5bca7128-10fa-4674-b20d-a4ebdcbf6ec6
cam = camera(scene) # this is how to access the scenes camera

# ╔═╡ 4b05f6ee-ffe3-4658-87d0-4930035ee7d9
md"""
One can change the mapping, to e.g. draw from -3 to 5:
"""

# ╔═╡ f3842cab-564b-42ca-a7a2-cbe4a8991f86
cam.projection[] = Makie.orthographicprojection(-3f0, 5f0, -3f0, 5f0, -100f0, 100f0); scene

# ╔═╡ fc346f84-9d87-4f40-9bbe-ea1592db66bb
md"""
one can also change the camera to a perspective 3d projection:
"""

# ╔═╡ 20f97b0c-b579-4bdb-82e9-a0976f015a74
begin 
	w, h = size(scene)
	cam.projection[] = Makie.perspectiveprojection(45f0, Float32(w / h), 0.1f0, 100f0)
	# Now, we also need to change the view matrix
	# to "put" the camera into some place.
	cam.view[] = Makie.lookat(Vec3f(10), Vec3f(0), Vec3f(0, 0, 1))
	scene
end

# ╔═╡ 68b06965-c4a9-4324-8ddd-1f30a1e4cf11
md"""
These are all camera transformations of the object.
In contrast, there are also scene transformations, or commonly referred to as world transformations.
To learn more about the different spaces, [learn opengl](https://learnopengl.com/Getting-started/Coordinate-Systems) offers some pretty nice explanations

The "world" transformations are implemented via the `Transformation` struct in Makie. Scenes and plots both contain these, so these types are considered as "Makie.Transformable".
The transformation of a scene will get inherited by all plots added to the scene. 
An easy way to manipulate any `Transformable` is via these 3 functions:
{{doc translate!}}
{{doc rotate!}}
{{doc scale!}}
"""

# ╔═╡ e56bea12-6c1f-4057-88b5-a1557396854c
begin 
	sphere_plot = mesh!(scene, Sphere(Point3f(0), 0.5), color=:red)
	scale!(scene, 2, 2, 2)
	rotate!(scene, Vec3f(1, 0, 0), 0.5) # 0.5 rad around the y axis
	scene
end

# ╔═╡ 8d18a5fe-ca4a-4bc7-a547-f816d634e2db
md"""
One can also transform the plot objects directly, which then adds the transformation from the plot object on top of the transformation from the scene.
One can add subscenes and interact with those dynamically.
Makie offers here what's usually referred to as a scene graph.
"""

# ╔═╡ 82e9cdd2-aa5e-451b-8af4-d181acaf9910
translate!(sphere_plot, Vec3f(0, 0, 1)); scene

# ╔═╡ e53c8b75-a44a-459d-a5f6-975dd9cc9c1b
md"""
The scene graph can be used to create rigid transformations, like for a robot arm:
"""

# ╔═╡ 7015a26c-f5a7-4e86-9c56-58432dbb0b44
begin
	gl
	parent = Scene()
	cam3d!(parent)
	camc = cameracontrols(parent)
	
	update_cam!(parent, camc, Vec3f(0, 8, 0), Vec3f(4.0, 0, 0))
	s1 = Scene(parent, camera=parent.camera)
	mesh!(s1, Rect3f(Vec3f(0, -0.1, -0.1), Vec3f(5, 0.2, 0.2)))
	s2 = Scene(s1, camera=parent.camera)
	mesh!(s2, Rect3f(Vec3f(0, -0.1, -0.1), Vec3f(5, 0.2, 0.2)), color=:red)
	translate!(s2, 5, 0, 0)
	s3 = Scene(s2, camera=parent.camera)
	mesh!(s3, Rect3f(Vec3f(-0.2), Vec3f(0.4)), color=:blue)
	translate!(s3, 5, 0, 0)
	parent
end

# ╔═╡ 032eac09-a05c-43f6-af93-4b268957d6d5
begin
	# Now, rotate the "joints"
	rotate!(s2, Vec3f(0, 1, 0), 0.5)
	rotate!(s3, Vec3f(1, 0, 0), 0.5)
	parent
end

# ╔═╡ 045c8539-6e68-40ec-bf93-889ba481e374
md"""
With this basic principle, we can even bring robots to life :) 
[Kevin Moerman](https://github.com/Kevin-Mattheus-Moerman) was so nice to supply a Lego mesh, which we're going to animate!
When the scene graph is really just about a transformation Graph, one can use the Transformation struct directly, which is what we're going to do here.
This is more efficient and easier than creating a scene for each model.
"""

# ╔═╡ fa2373db-edd0-42fa-9256-492061a35190
App() do session
	wgl
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

# ╔═╡ 3495dfd6-4a10-4178-9136-dd10a4d055b5
let
	RPRMakie.activate!(iterations=20)
	radiance = 50000
    lights = [
        # EnvironmentLight(1.5, rotl90(load(assetpath("sunflowers_1k.hdr"))')),
        PointLight(Vec3f(50, 0, 200), RGBf(radiance, radiance, radiance*1.1)),
    ]
    s = Scene(lights=lights, resolution=(500, 500))
    cam3d!(s)
    c = cameracontrols(s)
    c.near[] = 5
    c.far[] = 1000
    update_cam!(s, c, Vec3f(100, 30, 80), Vec3f(0, 0, -10))
	figure = plot_lego_figure(s)
	
    rot_joints_by = 0.25*pi
    total_translation = 50
    animation_strides = 10

    a1 = LinRange(0, rot_joints_by, animation_strides)
    angles = [a1; reverse(a1[1:end-1]); -a1[2:end]; reverse(-a1[1:end-1]);]
    nsteps = length(angles); #Number of animation steps
    translations = LinRange(0, total_translation, nsteps)
    Makie.Record(s, zip(translations[1:4], angles[1:4])) do (translation, angle)
        #Rotate right arm+hand
        for name in ["arm_left", "arm_right",
                			 "leg_left", "leg_right"]
            rotate!(figure[name], rotation_axes[name], angle)
        end
        translate!(figure["torso"], translation, 0, 20)
    end
end

# ╔═╡ 01bc92cf-6943-48be-a373-3cd328660bed


# ╔═╡ Cell order:
# ╠═75852c20-4878-11ec-0f17-77727b908d78
# ╠═f2f63242-e0ba-4fd6-a454-7fd0952236ad
# ╠═87021c46-5fcd-4995-80fc-bb49fd194978
# ╟─09fcfad7-0c3b-4910-b6ad-ba8e2f6b24f2
# ╠═98c046a9-9a4e-4dc2-ad5a-205805064a03
# ╟─8bae338c-1041-4cda-be49-2328f0d01d9c
# ╠═5bca7128-10fa-4674-b20d-a4ebdcbf6ec6
# ╟─4b05f6ee-ffe3-4658-87d0-4930035ee7d9
# ╠═f3842cab-564b-42ca-a7a2-cbe4a8991f86
# ╟─fc346f84-9d87-4f40-9bbe-ea1592db66bb
# ╠═20f97b0c-b579-4bdb-82e9-a0976f015a74
# ╟─68b06965-c4a9-4324-8ddd-1f30a1e4cf11
# ╠═e56bea12-6c1f-4057-88b5-a1557396854c
# ╟─8d18a5fe-ca4a-4bc7-a547-f816d634e2db
# ╠═82e9cdd2-aa5e-451b-8af4-d181acaf9910
# ╟─e53c8b75-a44a-459d-a5f6-975dd9cc9c1b
# ╠═7015a26c-f5a7-4e86-9c56-58432dbb0b44
# ╠═032eac09-a05c-43f6-af93-4b268957d6d5
# ╟─045c8539-6e68-40ec-bf93-889ba481e374
# ╠═ba3bb4b5-73b6-44b1-ab84-f57406058479
# ╠═d5201580-108d-42e2-8eb5-c4489cc2ceb4
# ╠═fa2373db-edd0-42fa-9256-492061a35190
# ╠═abe526e5-6d36-4ac5-876f-ebd65ff8a05f
# ╠═3495dfd6-4a10-4178-9136-dd10a4d055b5
# ╠═01bc92cf-6943-48be-a373-3cd328660bed
