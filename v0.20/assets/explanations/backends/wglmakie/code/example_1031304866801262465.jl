# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    App() do session
    f, ax, pl = scatter(1:4, markersize=100, color=Float32[0.3, 0.4, 0.5, 0.6])
    custom_info = ["a", "b", "c", "d"]
    on_click_callback = js"""(plot, index) => {
        // the plot object is currently just the raw THREEJS mesh
        console.log(plot)
        // Which can be used to extract e.g. position or color:
        const {pos, color} = plot.geometry.attributes
        console.log(pos)
        console.log(color)
        const x = pos.array[index*2] // everything is a flat array in JS
        const y = pos.array[index*2+1]
        const c = Math.round(color.array[index] * 10) / 10 // rounding to a digit in JS
        const custom = $(custom_info)[index]
        // return either a string, or an HTMLNode:
        return "Point: <" + x + ", " + y + ">, value: " + c + " custom: " + custom
    }
    """

    # ToolTip(figurelike, js_callback; plots=plots_you_want_to_hover)
    tooltip = WGLMakie.ToolTip(f, on_click_callback; plots=pl)
    return DOM.div(f, tooltip)
end
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide