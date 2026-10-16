# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using Markdown

App() do session::Session
    # We can now use this wherever we want:
    fig = Figure(size=(300, 300))
    contour(fig[1,1], rand(4,4))
    card = Card(Grid(
        Centered(DOM.h1("Hello"); style=Styles("grid-column" => "1 / 3")),
        StylableSlider(1:100; style=Styles("grid-column" => "1 / 3")),
        DOM.img(src="https://julialang.org/assets/infra/logo.svg"),
        fig; columns="1fr 1fr", justify_items="stretch"
    ))
    # Markdown creates a DOM as well, and you can interpolate
    # arbitrary jsrender'able elements in there:
    return DOM.div(card)
end
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide