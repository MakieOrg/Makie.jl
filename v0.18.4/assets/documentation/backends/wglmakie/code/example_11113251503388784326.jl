# This file was generated, do not modify it. # hide
__result = begin # hide
    using Colors
using JSServe: rows

App() do session::Session

    hue_slider = Slider(0:360)
    color_swatch = DOM.div(class="h-6 w-6 p-2 m-2 rounded shadow")

    onjs(session, hue_slider.value, js"""function (hue){
        $(color_swatch).style.backgroundColor = "hsl(" + hue + ",60%,50%)"
    }""")

    return DOM.div(JSServe.TailwindCSS, rows(hue_slider, color_swatch))
end
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide