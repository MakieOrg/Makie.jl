
function pick_native(screen::Screen, rect::Rect2i)
    task = @async begin
        (x, y) = minimum(rect)
        (w, h) = widths(rect)
        session = get_three(screen).session
        scene = screen.scene
        picking_data = JSServe.evaljs_value(session, js"""
            Promise.all([$(WGL), $(scene)]).then(([WGL, scene]) => WGL.pick_native_matrix(scene, $x, $y, $w, $h))
        """)
        w2, h2 = picking_data["size"]
        @assert w2 == w && h2 == h
        matrix = reshape(picking_data["data"], (w2, h2))

        if isempty(matrix)
            return Matrix{Tuple{Union{Nothing, AbstractPlot}, Int}}(undef, 0, 0)
        else
            all_children = Makie.flatten_plots(scene)
            lookup = Dict(Pair.(js_uuid.(all_children), all_children))
            return map(matrix) do (uuid, index)
                !haskey(lookup, uuid) && return (nothing, 0)
                return (lookup[uuid], Int(index) + 1)
            end
        end
    end
    return fetch(task)
end

function plot_lookup(scene::Scene)
    all_plots = Makie.flatten_plots(scene)
    return Dict(Pair.(js_uuid.(all_plots), all_plots))
end

# Skips one set of allocations
function Makie.pick_closest(scene::Scene, screen::Screen, xy, range::Integer)
    # isopen(screen) || return (nothing, 0)
    xy_vec = Cint[round.(Cint, xy)...]
    range = round(Int, range)
    session = get_three(screen).session
    selection = JSServe.evaljs_value(session, js"""
        Promise.all([$(WGL), $(scene)]).then(([WGL, scene]) => WGL.pick_closest(scene, $(xy_vec), $(range)))
    """)
    lookup = plot_lookup(scene)
    return (lookup[selection[1]], selection[2] + 1)
end

# Skips some allocations
function Makie.pick_sorted(scene::Scene, screen::Screen, xy, range)
    xy_vec = Cint[round.(Cint, xy)...]
    range = round(Int, range)
    session = get_three(screen).session
    selection = JSServe.evaljs_value(session, js"""
        Promise.all([$(WGL), $(scene)]).then(([WGL, scene]) => WGL.pick_sorted(scene, $(xy_vec), $(range)))
    """)
    isnothing(selection) && return Tuple{Union{Nothing,AbstractPlot},Int}[]
    lookup = plot_lookup(scene)
    return map(selection) do (plot_id, index)
        return (lookup[plot_id], index + 1)
    end
end

function Makie.pick(scene::Scene, screen::Screen, xy)
    plot_matrix = pick_native(screen, Rect2i(xy..., 1, 1))
    @assert size(plot_matrix) == (1, 1)
    return plot_matrix[1, 1]
end

"""
    ToolTip(figurelike, js_callback; plots=plots_you_want_to_hover)

Returns a JSServe DOM element, which creates a popup whenever you click on a plot element in `plots`.
The content of the popup is filled with the return value of js_callback, which can be a string or `HTMLNode`.

Usage example:

```julia
App() do session
    f, ax, pl = scatter(1:4, markersize=100, color=Float32[0.3, 0.4, 0.5, 0.6])
    custom_info = ["a", "b", "c", "d"]
    on_click_callback = js\"\"\"(plot, index) => {
        // the plot object is currently just the raw THREEJS mesh
        console.log(plot)
        // Which can be used to extract e.g. position or color:
        const {pos, color} = plot.geometry.attributes
        console.log(pos)
        console.log(color)
        const x = pos.array[index*2] // everything is a flat array in JS
        const y = pos.array[index*2+1]
        const c = Math.round(color.array[index] * 10) / 10 // rounding to a digit in JS
        const custom = \$(custom_info)[index]
        // return either a string, or an HTMLNode:
        return "Point: <" + x + ", " + y + ">, value: " + c + " custom: " + custom
    }
    \"\"\"

    tooltip = WGLMakie.ToolTip(f, on_click_callback; plots=pl)
    return DOM.div(f, tooltip)
end
```
"""
struct ToolTip
    scene::Scene
    callback::JSServe.JSCode
    plot_uuids::Vector{String}
    function ToolTip(figlike, callback; plots=nothing)
        scene = Makie.get_scene(figlike)
        if isnothing(plots)
            plots = scene.plots
        end
        all_plots = WGLMakie.js_uuid.(filter!(x-> x.inspectable[], Makie.flatten_plots(plots)))
        new(scene, callback, all_plots)
    end
end

const POPUP_CSS = JSServe.Asset(joinpath(@__DIR__, "popup.css"))

function JSServe.jsrender(session::Session, tt::ToolTip)
    scene = tt.scene
    popup =  DOM.div("", class="popup")

    JSServe.onload(session, popup, js"""
    (popup) => {
        const plots_to_pick = new Set($(tt.plot_uuids));
        const callback = $(tt.callback);
        document.addEventListener("mousedown", event=> {
            if (!popup.classList.contains("show")) {
                popup.classList.add("show");
            }
            popup.style.left = event.pageX + 'px';
            popup.style.top = event.pageY + 'px';
            $(scene).then(scene => {
                const [x, y] = WGLMakie.event2scene_pixel(scene, event)
                const [_, picks] = WGLMakie.pick_native(scene, x, y, 1, 1)
                if (picks.length == 1){
                    const [plot, index] = picks[0];
                    if (plots_to_pick.has(plot.plot_uuid)) {
                        const result = callback(plot, index)
                        if (typeof result === 'string' || result instanceof String) {
                            popup.innerText = result
                        } else {
                            popup.innerHTML = result
                        }
                    }
                } else {
                    popup.classList.remove("show");
                }
            })

        });
        document.addEventListener("keyup", event=> {
            if (event.key === "Escape") {
                popup.classList.remove("show");
            }
        })
    }
    """)
    return DOM.span(JSServe.jsrender(session, POPUP_CSS), popup)
end
