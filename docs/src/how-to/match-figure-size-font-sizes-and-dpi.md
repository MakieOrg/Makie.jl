# How to match figure size, font sizes and dpi

We want to create three plots for inclusion in a document. These are the requirements:

- Figure 1: png @ 4x3 inches and 100 dpi
- Figure 2: png @ 9x7 cm and 300 dpi
- Figure 3: svg @ 4x3 inches

The fontsize of all three should match the document's 12pt setting.

We assume the convention that Makie's unitless figure size is actually equivalent to CSS pixels.
For a deeper explanation why, check the section [Figure size and resolution](@ref).

We're using Typst here but the technique applies similarly for all authoring tools that allow you to set the dimensions of included images.

```@example
using CairoMakie
CairoMakie.activate!() # hide
using Typst_jll

# these are relative to 1 CSS px
inch = 96
pt = 4/3
cm = inch / 2.54

f1 = Figure(size = (4inch, 3inch), fontsize = 12pt)
f2 = Figure(size = (9cm, 7cm), fontsize = 12pt)
f3 = Figure(size = (4inch, 3inch), fontsize = 12pt)

titles = [
    "Figure 1: png @ 4x3 inches and 100 dpi",
    "Figure 2: png @ 9x7 cm and 300 dpi",
    "Figure 3: svg @ 4x3 inches",
]

data = cumsum(randn(100))

for (f, title) in zip([f1, f2, f3], titles)
    ax = Axis(f[1, 1]; title, xlabel = "time (s)", ylabel = "value (€)")
    lines!(ax, data)
end

save("figure1.png", f1, px_per_unit = 100/inch)
save("figure2.png", f2, px_per_unit = 300/inch)
save("figure3.svg", f3)

typst_code = """
    #set page(fill: rgb("#f5f2eb"))
    #set text(font: "TeX Gyre Heros Makie", size: 12pt, fill: luma(50%))

    This is some text at 12pt which the figures below should match.

    #image("figure1.png", width: 4in, height: 3in)
    #image("figure2.png", width: 9cm, height: 7cm)
    #image("figure3.svg") // vector graphics have physical dimensions
"""

open(io -> println(io, typst_code), "document.typ", "w")

cp(Makie.assetpath("fonts", "TeXGyreHerosMakie-Regular.otf"), "./texgyre.otf")

run(`$(Typst_jll.typst()) compile --font-path . document.typ output.svg`)

nothing # hide
```

![](output.svg)

