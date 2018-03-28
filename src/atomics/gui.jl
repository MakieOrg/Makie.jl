using GLVisualize: x_partition
using GLVisualize: widget, mm, play_slider, labeled_slider

function vbox(scene::T, sizes::AbstractFloat...) where T <: Scene
    parent = getscreen(scene)
    lastx = 0
    map(sizes) do size
        area = map(parent.area) do area
            w = round(Int, area.w * size)
            a = SimpleRectangle(lastx, 0, w, area.h)
            lastx += w
            a
        end
        Scene(scene, area)
    end
end

function hbox(scene::T, sizes::AbstractFloat...) where T <: Scene
    parent = getscreen(scene)
    lasty = 0
    map(sizes) do size
        area = map(parent.area) do area
            h = round(Int, area.h * size)
            a = SimpleRectangle(0, lasty, area.w, h)
            lasty += h
            a
        end
        Scene(scene, area)
    end
end




makie_widget(screen, x::Tuple) = makie_widget(screen, x...)
makie_widget(screen, x::Tuple{Any, Pair}) = makie_widget(screen, x[1], (x[2],))
makie_widget(screen, x) = makie_widget(screen, x, ())
function makie_widget(screen, x::Tuple{Bool, <: Range}, args::Tuple)
    viz, s = play_slider(x[2], screen; args...)
    push!(s, x[1])
    viz, s
end

function makie_widget(screen, x::Range, args::Tuple)
    labeled_slider(x, screen; args...)
end
function makie_widget(screen, x::Scene)
    native_visual(x), Signal(nothing)
end
function makie_widget(screen, x, args::Tuple)
    widget(x, screen; args...)
end

function gui(scene::Scene, elements::Pair...)
    screen = getscreen(scene)
    signals = Dict{String, Node}()
    controls = Pair[map(elements) do name_control
        name, control = name_control
        viz, s = makie_widget(screen, control)
        signals[name] = to_node(s)
        name => viz
    end...]
    _view(visualize(controls), screen, camera = :fixed_pixel)
    signals
end
export gui, vbox



hover(f, window, hover_robj::Context) = hover(f, window, hover_robj.children[])

"""
usage

hover(window, sprites) do ishover, robj, idx
    if ishover
        x, y, z = round.(robj[:position][idx], 2)
        c = robj[:color][idx]
        xs, ys = robj[:scale][idx]
        r, g, b = ((f,x)-> f(x)).((red, green, blue), c)
        \"\"\"
        position: (\$x, \$y, \$z)
        color: (\$r, \$g, \$b)
        scale: (\$xs, \$ys)
        \"\"\"
    else
        " " # glvisualize doesn't like empty strings, so just returning a space for now
    end
end
"""
function hover(display_func, window, hover_robj::RenderObject)
    area = map(window.inputs[:mouseposition]) do mp
        SimpleRectangle{Int}(round.(Int, mp + 10)..., 60mm, 30mm)
    end
    m2id = GLWindow.mouse2id(window)
    hovering = map(mh-> (mh.id == hover_robj.id), m2id)
    popup = GLWindow.Screen(
        window,
        hidden = map((!), hovering),
        area = area,
        stroke = (2f0, RGBA(0f0, 0f0, 0f0, 0.8f0))
    )
    v0 = Signal(display_func(false, hover_robj, value(m2id).index))
    _view(visualize(v0), popup)
    foreach(hovering) do ishover
        if ishover
            push!(v0, display_func(true, hover_robj, value(m2id).index))
            yield()
            GLAbstraction.center!(popup, first(keys(popup.cameras)); border = 10)
        end
        return
    end
    nothing
end
