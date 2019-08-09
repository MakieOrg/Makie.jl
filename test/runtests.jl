using WGLMakie, AbstractPlotting, JSServe
function dom_handler(session, request)
    sc = surface(0..1, 0..1, rand(4, 4));
    three, canvas = WGLMakie.three_display(session, sc)
    canvas
end
using GeometryTypes
c = Cylinder(Point3f0(0), Vec3f0(1, 0, 0), 1f0)
JSServe.with_session() do session

    dom_handler(session, nothing)
end
# app = JSServe.Application(
#     dom_handler,
#     get(ENV, "WEBIO_SERVER_HOST_URL", "127.0.0.1"),
#     parse(Int, get(ENV, "WEBIO_HTTP_PORT", "8081")),
#     verbose = false
# )

using Colors


d = JSServe.with_session() do session
    img = rand(100, 100)
    scene = Scene(resolution = (500, 500))
    heatmap!(scene, img, scale_plot = false)
    clicks = Node(zeros(Point2f0, 100))
    colors = Node(zeros(RGBAf0, 100))
    last_idx = Ref(0)
    on(scene.events.mousebuttons) do buttons
       if ispressed(scene, Mouse.left)
           pos = to_world(scene, Point2f0(scene.events.mouseposition[]))
           last_idx[] += 1
           clicks[][last_idx[]] = pos
           colors[][last_idx[]] = RGBAf0(1, 0, 0, 1)
           clicks[] = clicks[]; colors[] = colors[]
       end
       return
    end
    scatter!(scene, clicks, color = colors, marker = '+', markersize = 10);
    three, canvas = WGLMakie.three_display(session, scene)
    canvas
end

using Observables
d = JSServe.with_session() do session
    scene3d = Scene(show_axis = false)
    linesegments!(scene3d, FRect3D(Vec3f0(0), Vec3f0(1)))
    brain_data = rand(Float32, 10, 10, 10)
    volume = Node(brain_data)
    planes = (:yz, :xz, :xy)
    three = nothing
    r = LinRange(0, 1, 10)
    sliders = ntuple(3) do i
        idx = JSServe.Slider(1:size(volume[], i), value = size(volume[], i) ÷ 2)
        plane = planes[i]
        indices = ntuple(3) do j
            planes[j] == plane ? 1 : (:)
        end
        heatm = heatmap!(
            scene3d, r, r, volume[][indices...],
            colorrange = (0.0, 1.0),
            interpolate = true
        )[end]
        function transform_planes(idx, vol)
            transform!(heatm, (plane, r[idx]))
            indices = ntuple(3) do j
                planes[j] == plane ? idx : (:)
            end
            if checkbounds(Bool, vol, indices...)
                heatm[3][] = view(vol, indices...)
                three !== nothing && WGLMakie.redraw!(three)
            end
        end
        onany(transform_planes, idx, volume)
        transform_planes(idx[], volume[])
        idx
    end
    three, canvas = WGLMakie.three_display(session, scene3d)
    JSServe.div(sliders, canvas)
end



using AbstractPlotting
import AbstractPlotting: Plot, default_theme, plot!, to_value
using WGLMakie, AbstractPlotting, JSServe

struct Simulation
    grid::Vector{Point3f0}
end
# Probably worth having a macro for this!
function default_theme(scene::SceneLike, ::Type{<: Plot(Simulation)})
    Theme(
        advance = 0,
        molecule_sizes = [0.08, 0.04, 0.04],
        molecule_colors = [:maroon, :deepskyblue2, :deepskyblue2]
    )
end

# The recipe! - will get called for plot(!)(x::SimulationResult)
function AbstractPlotting.plot!(p::Plot(Simulation))
    sim = to_value(p[1]) # first argument is the SimulationResult
    # when advance changes, get new positions from the simulation
    mpos = lift(p[:advance]) do i
        sim.grid .+ rand(Point3f0, length(sim.grid)) .* 0.01f0
    end
    # size shouldn't change, so we might as well get the value instead of signal
    pos = to_value(mpos)
    N = length(pos)
    sizes = lift(p[:molecule_sizes]) do s
        repeat(s, outer = N ÷ 3)
    end
    sizes = lift(p[:molecule_sizes]) do s
        repeat(s, outer = N ÷ 3)
    end
    colors = lift(p[:molecule_colors]) do c
        repeat(c, outer = N ÷ 3)
    end
    scene = scatter!(p, mpos, markersize = sizes, color = colors)
    indices = Int[]
    for i in 1:3:N
        push!(indices, i, i + 1, i, i + 2)
    end
    meshplot = p.plots[end] # meshplot is the last plot we added to p
    # meshplot[1] -> the positions (first argument) converted to points, so
    # we don't do the conversion 2 times for linesegments!
    linesegments!(p, lift(x-> view(x, indices), meshplot[1]))
end

# To write out a video of the whole simulation
n = 5
r = range(-1, stop = 1, length = n)
grid = Point3f0.(r, reshape(r, (1, n, 1)), reshape(r, (1, 1, n)))
molecules = map(1:(n^3) * 3) do i
    i3 = ((i - 1) ÷ 3) + 1
    xy = 0.1; z = 0.08
    i % 3 == 1 && return grid[i3]
    i % 3 == 2 && return grid[i3] + Point3f0(xy, xy, z)
    i % 3 == 0 && return grid[i3] + Point3f0(-xy, xy, z)
end
result = Simulation(molecules)

scene = plot(result)
global three
d = JSServe.with_session() do session
    global three
    scene = plot(result)
    three, canvas = WGLMakie.three_display(session, scene)
    canvas
end
for i in 1:100
    scene[end].advance = i
    sleep(0.1)
    WGLMakie.redraw!(three)
    yield()
end
