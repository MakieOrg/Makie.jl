function pick_native(screen::Screen, rect::Rect2i)
    (x, y) = minimum(rect)
    (w, h) = widths(rect)
    session = get_screen_session(screen)
    empty = Matrix{Tuple{Union{Nothing, AbstractPlot}, Int}}(undef, 0, 0)
    isnothing(session) && return empty
    scene = screen.scene
    picking_data = Bonito.evaljs_value(
        session, js"""
            Promise.all([$(WGL), $(scene)]).then(([WGL, scene]) => WGL.pick_native_matrix(scene, $x, $y, $w, $h))
        """
    )
    if isnothing(picking_data)
        return empty
    end
    w2, h2 = picking_data["size"]
    matrix = reshape(picking_data["data"], (w2, h2))
    if isempty(matrix)
        return empty
    else
        lookup = plot_lookup(scene)
        return map(matrix) do (uuid, index)
            !haskey(lookup, uuid) && return (nothing, 0)
            plt = lookup[uuid]
            return (plt, Int(index) + !(plt isa Volume))
        end
    end
end

function plot_lookup(scene::Scene)
    all_plots = Makie.collect_atomic_plots(scene)
    return Dict(Pair.(js_uuid.(all_plots), all_plots))
end

# Skips one set of allocations
function Makie.pick_closest(scene::Scene, screen::Screen, xy, range::Integer)
    # isopen(screen) || return (nothing, 0)
    xy_vec = Cint[round.(Cint, xy)...]
    range = round(Int, range)
    session = get_screen_session(screen)
    # E.g. if websocket got closed
    isnothing(session) && return (nothing, 0)
    selection = Bonito.evaljs_value(
        session, js"""
            Promise.all([$(WGL), $(scene)]).then(([WGL, scene]) => WGL.pick_closest(scene, $(xy_vec), $(range)))
        """
    )
    lookup = plot_lookup(scene)
    !haskey(lookup, selection[1]) && return (nothing, 0)
    plt = lookup[selection[1]]
    return (plt, Int(selection[2]) + !(plt isa Volume))
end

# Skips some allocations
function Makie.pick_sorted(scene::Scene, screen::Screen, xy, range)
    xy_vec = Cint[round.(Cint, xy)...]
    range = round(Int, range)
    session = get_screen_session(screen)
    # E.g. if websocket got closed
    isnothing(session) && return Tuple{Plot, Int}[]
    selection = Bonito.evaljs_value(
        session, js"""
            Promise.all([$(WGL), $(scene)]).then(([WGL, scene]) => {
                const picked = WGL.pick_sorted(scene, $(xy_vec), $(range))
                return picked
            })
        """
    )
    isnothing(selection) && return Tuple{Plot, Int}[]
    lookup = plot_lookup(scene)
    filter!(((id, idx),) -> haskey(lookup, id), selection)
    return map(selection) do (id, idx)
        plt = lookup[id]
        return (plt, Int(idx) + !(plt isa Volume))
    end
end

function Makie.pick(::Scene, screen::Screen, xy)
    plot_matrix = pick_native(screen, Rect2i(xy..., 1, 1))
    return plot_matrix[1, 1]
end

function Makie.pick(::Scene, screen::Screen, r::Rect2)
    return pick_native(screen, Rect2i(round.(minimum(r)), round.(widths(r))))
end

"""
    ToolTip(figurelike, js_callback; plots=plots_you_want_to_hover, trigger=:click,
range=0, class="popup", css=POPUP_CSS)

Returns a Bonito DOM element, which creates a popup whenever you interact with a plot
element in `plots`. The content of the popup is filled with the return value of
js_callback, which can be a string or `HTMLNode`.

`trigger` controls what shows the popup:
- `:click` (default): click on a plot element. Picking uses an exact 1×1 pixel hit test,
  matching pre-existing click-to-inspect behavior.
- `:hover`: move the mouse over a plot element; the popup follows the cursor and hides
  again once you move off the element or press the mouse down.

`range` sets the picking tolerance in pixels. `0` (the default) uses the exact 1×1 pick
described above, regardless of `trigger`. Any value `> 0` switches to a tolerant
"closest point within `range` pixels" pick instead — useful for `:hover` (and for `:click`
on small or sparse markers), since requiring an exact hit under the cursor is impractical
when following continuous mouse movement.

The popup is styled via `class` (the CSS class on the popup `div`, default `"popup"`) and
`css` (a stylesheet to load — any `jsrender`-able such as an `Asset`, `Styles` or DOM node;
default `POPUP_CSS`). To restyle, set both: a class your stylesheet targets, and the
stylesheet
itself. Your CSS must handle the `show` class (toggled when the popup is visible).

To match the GLMakie `DataInspector` look, use the bundled preset:
`ToolTip(fig, callback; plots, class = "datainspector-popup", css = DATAINSPECTOR_CSS)`.
See [`DATAINSPECTOR_CSS`](@ref).

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

    tooltip = WGL.ToolTip(f, on_click_callback; plots=pl)
    return DOM.div(f, tooltip)
end
```
"""
struct ToolTip
    scene::Scene
    callback::Bonito.JSCode
    plot_uuids::Vector{String}
    trigger::Symbol
    range::Int
    class::String
    css::Any
    function ToolTip(
            figlike,
            callback;
            plots = nothing,
            trigger = :click,
            range = 0,
            class = "popup",
            css = POPUP_CSS,
        )
        scene = Makie.get_scene(figlike)
        if isnothing(plots)
            plots = scene.plots
        end
        all_plots = js_uuid.(filter!(x -> x.inspectable[], Makie.collect_atomic_plots(plots)))
        return new(scene, callback, all_plots, trigger, range, class, css)
    end
end

const POPUP_CSS = Bonito.Asset(@path joinpath(@__DIR__, "popup.css"))

"""
    DATAINSPECTOR_CSS

A ready-made `ToolTip` stylesheet that mimics the GLMakie `DataInspector` popup
(square white box, black outline, downward tail pointing at the data point).
Pair it with `class = "datainspector-popup"`:

```julia
ToolTip(fig, callback; plots, class = "datainspector-popup", css = DATAINSPECTOR_CSS)
```
"""
const DATAINSPECTOR_CSS = DOM.span(
    # load the Makie UI font so the text matches DataInspector exactly
    Bonito.Styles(
        Bonito.CSS(
            "@font-face",
            "font-family" => "TeXGyreHerosMakie",
            "src" => Bonito.Asset(Makie.assetpath("fonts", "TeXGyreHerosMakie-Regular.otf")),
        )
    ),
    Bonito.Asset(@path joinpath(@__DIR__, "datainspector_popup.css")),
)

function Bonito.jsrender(session::Session, tt::ToolTip)
    scene = tt.scene
    popup = DOM.div("", class = tt.class)
    Bonito.evaljs(
        session, js"""
            Promise.all([$(WGL), $(scene)]).then(([WGL, scene]) => {
                const plots_to_pick = new Set($(tt.plot_uuids));
                const callback = $(tt.callback);
                WGL.register_popup($popup, scene, plots_to_pick, callback, {
                    trigger: $(string(tt.trigger)),
                    range: $(tt.range)
                })
            })
        """
    )
    return DOM.span(Bonito.jsrender(session, tt.css), popup)
end
