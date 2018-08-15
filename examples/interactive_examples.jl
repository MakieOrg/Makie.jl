
using Makie, Colors, Images
r = range(0, stop=5pi, length=100)
scene = lines(r, sin.(r), linewidth = 3)
lineplot = scene[end]
visible = node(:visible, false)
poprect = lift(scene.events.mouseposition) do mp
    FRect((mp .+ 5), 250, 40)
end
textpos = lift(scene.events.mouseposition) do mp
    Vec3f0((mp .+ 5 .+ (250/2, 40 / 2))..., 120)
end
popup = poly!(campixel(scene), poprect, raw = true, color = :white, strokewidth = 2, strokecolor = :black, visible = visible)
rect = popup[end]
translate!(rect, Vec3f0(0, 0, 100))
text!(popup, "( 0.000,  0.000)", textsize = 30, position = textpos, color = :darkred, align = (:center, :center), raw = true, visible = visible)
text_field = popup[end]
scene


on(scene.events.mouseposition) do even
    plot, idx = Makie.mouse_selection(scene)
    if plot == lineplot
        visible[] = true
        text_field[1] = sprint(io-> print(io, round.(Float64.(Tuple(lineplot[1][][idx])), 3)))
    else
        visible[] = false
    end
    return
end
scene




using Makie

img = rand(100, 100)
scene = Scene()
heatmap!(scene, img, scale_plot = false)
clicks = Node(Point2f0[(0, 0)])
blues = Node(Point2f0[])

on(scene.events.mousebuttons) do buttons
    if ispressed(scene, Mouse.left)
        pos = to_world(scene, Point2f0(scene.events.mouseposition[]))
        found = -1
        for i in 1:length(clicks[])
           if norm(pos - clicks.value[i]) < 1
               found = i
           end
        end
        if found >= 1
            blues[] = push!(blues[], pos)
            deleteat!(clicks[], found)
        else
            push!(clicks[], pos)
        end
        clicks[] = clicks[]
   end
   return
end

scatter!(scene, clicks, color = :red, marker = '+', markersize = 10, raw = true)
red_clicks = scene[end]
scatter!(scene, blues, color = :blue, marker = 'o', markersize = 10, raw = true)
scene



using Makie
points = node(:poly, Point2f0[(0, 0), (0.5, 0.5), (1.0, 0.0)])

scene = poly(points, strokewidth = 2, strokecolor = :black, color = :skyblue2, show_axis = false, scale_plot = false)
scatter!(points, color = :white, strokewidth = 10, markersize = 0.05, strokecolor = :black, raw = true)
pplot = scene[end]
push!(points[], Point2f0(0.6, -0.3))
points[] = points[]

function add_move!(scene, points, pplot)
    idx = Ref(0); dragstart = Ref(false); startpos = Base.RefValue(Point2f0(0))
    on(events(scene).mousedrag) do drag
        if ispressed(scene, Mouse.left)
            if drag == Mouse.down
                plot, _idx = Makie.mouse_selection(scene)
                if plot == pplot
                    idx[] = _idx; dragstart[] = true
                    startpos[] = to_world(scene, Point2f0(scene.events.mouseposition[]))
                end
            elseif drag == Mouse.pressed && dragstart[] && checkbounds(Bool, points[], idx[])
                pos = to_world(scene, Point2f0(scene.events.mouseposition[]))
                points[][idx[]] = pos
                points[] = points[]
            end
        else
            dragstart[] = false
        end
        return
    end
end

function add_remove_add!(scene, points, pplot)
    on(events(scene).mousebuttons) do but
        if ispressed(but, Mouse.left) && ispressed(scene, Keyboard.left_control)
            pos = to_world(scene, Point2f0(events(scene).mouseposition[]))
            push!(points[], pos)
            points[] = points[]
        elseif ispressed(but, Mouse.right)
            plot, idx = Makie.mouse_selection(scene)
            if plot == pplot && checkbounds(Bool, points[], idx)
                deleteat!(points[], idx)
                points[] = points[]
            end
        end
        return
    end
end
add_move!(scene, points, pplot)
add_remove_add!(scene, points, pplot)
center!(scene)
scene


using Makie, Colors
using AbstractPlotting: modelmatrix, textslider, colorswatch, hbox!

scene = Scene(resolution = (1000, 1000))
ui_width = 260
ui = Scene(scene, lift(x-> IRect(0, 0, ui_width, widths(x)[2]), pixelarea(scene)))
plot_scene = Scene(scene, lift(x-> IRect(ui_width, 0, widths(x) .- Vec(ui_width, 0)), pixelarea(scene)))
theme(ui)[:plot] = NT(raw = true)
campixel!(ui)
translate!(ui, 10, 50, 0)
a = textslider(ui, 0f0:50f0, "a")
b = textslider(ui, -20f0:20f0, "b")
c = textslider(ui, 0f0:20f0, "c")
d = textslider(ui, range(0.0, stop=0.01, length=100), "d")
scales = textslider(ui, range(0.01, stop=0.5, length=100), "scale")
color, pop = colorswatch(ui)
hbox!(ui.plots)

function lorenz(t0, a, b, c, h)
    Point3f0(
        t0[1] + h * a * (t0[2] - t0[1]),
        t0[2] + h * (t0[1] * (b - t0[3]) - t0[2]),
        t0[3] + h * (t0[1] * t0[2] - c * t0[3]),
    )
end
# step through the `time`
function lorenz(array::Vector, a = 5.0 ,b = 2.0, c = 6.0, d = 0.01)
    t0 = Point3f0(0.1, 0, 0)
    for i = eachindex(array)
        t0 = lorenz(t0, a,b,c,d)
        array[i] = t0
    end
    array
end

n1, n2 = 18, 30
N = n1*n2
args_n = (a, b, c, d)
args = (13f0, 10f0, 2f0, 0.01f0)
setindex!.(args_n, args)
v0 = lorenz(zeros(Point3f0, N), args...)
positions = Reactive.foldp(lorenz, v0, args_n...)
rotations = lift(diff, positions)
rotations = lift(x-> push!(x, x[end]), rotations)

plot = meshscatter!(
    plot_scene,
    positions,
    #marker = Makie.loadasset("cat.obj"),
    markersize = scales, rotation = rotations,
    intensity = collect(range(0f0, stop=1f0, length=length(positions[]))),
    color = color
)
scene


function record_events(f, scene, path)
    display(scene)
    result = Vector{Pair{Float64, Pair{Symbol, Any}}}()
    for field in fieldnames(Events)
        foreach(getfield(scene.events, field)) do value
            value = isa(value, Set) ? copy(value) : value
            push!(result, time() => (field => value))
        end
    end
    f()

    open(path, "w") do io
        serialize(io, result)
    end
end
record_events(scene, "test.jls") do
    wait(Makie.global_gl_screen())
end

function replay(scene, path)
    display(scene)
    events = open(io-> deserialize(io), path)
    sort!(events, by = first)
    for i in 1:length(events)
        t1, (field, value) = events[i]
        field == :mousedrag && continue
        if field == :mousebuttons
            println(value)
            getfield(scene.events, field)[] = value
        else
            getfield(scene.events, field)[] = value
        end
        yield(); force_update!()
        if i < length(events)
            t2, (field, value) = events[i + 1]
            # min sleep time 0.001
            (t2 - t1 > 0.001) && sleep(t2 - t1)
        end
    end
end

replay(scene, "test.jls")
open(io-> serialize(io, Set([Mouse.left])) , "test2.jls", "w")
open(io-> deserialize(io) , "test2.jls")

scatter!(campixel(scene), lift(x-> [x], scene.events.mouseposition),color = :black, markersize = 20, raw = true)
scene
