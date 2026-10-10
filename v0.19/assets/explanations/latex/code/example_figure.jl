# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

with_theme(theme_latexfonts()) do
    fig = Figure()
    Label(fig[1, 1], "A standard Label", tellwidth = false)
    Label(fig[2, 1], L"A LaTeXString with a small formula $x^2$", tellwidth = false)
    Axis(fig[3, 1], title = "An axis with matching font for the tick labels")
    fig
end
end # hide
save(joinpath(@OUTPUT, "example_13634245335302074798.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_13634245335302074798.svg"), __result; ) # hide
nothing # hide