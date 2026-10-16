# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using Markdown

struct GridCard
    elements::Any
end

GridCard(elements...) = GridCard(elements)

function JSServe.jsrender(card::GridCard)
    return DOM.div(JSServe.TailwindCSS, card.elements..., class="rounded-lg p-2 m-2 shadow-lg grid auto-cols-max grid-cols-2 gap-4")
end

App() do session::Session
    # We can now use this wherever we want:
    fig = Figure(resolution=(200, 200))
    contour(fig[1,1], rand(4,4))
    card = GridCard(
        Slider(1:100),
        DOM.h1("hello"),
        DOM.img(src="https://julialang.org/assets/infra/logo.svg"),
        fig
    )
    # Markdown creates a DOM as well, and you can interpolate
    # arbitrary jsrender'able elements in there:
    return md"""

    # Wow, Markdown works as well?

    $(card)

    """
end
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide