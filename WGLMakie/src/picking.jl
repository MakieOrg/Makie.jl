
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
    xy_vec = Cint[xy...]
    range = convert(Int, range)
    session = get_three(screen).session
    selection = JSServe.evaljs_value(session, js"""
        Promise.all([$(WGL), $(scene)]).then(([WGL, scene]) => WGL.pick_closest(scene, $(xy_vec), $(range)))
    """)
    lookup = plot_lookup(scene)
    return (lookup[selection[1]], selection[2] + 1)
end

# Skips some allocations
function Makie.pick_sorted(scene::Scene, screen::Screen, xy, range)
    xy_vec = Cint[xy...]
    range = convert(Int, range)
    session = get_three(screen).session
    selection = JSServe.evaljs_value(session, js"""
        Promise.all([$(WGL), $(scene)]).then(([WGL, scene]) => WGL.pick_sorted(scene, $(xy_vec), $(range)))
    """)
    lookup = plot_lookup(scene)
    @show selection
    return map(selection) do (plot_id, index)
        return (lookup[plot_id], index + 1)
    end
end

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
    popup_css = JSServe.Asset("popup.css")
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
    return DOM.span(JSServe.jsrender(session, popup_css), popup)
end
