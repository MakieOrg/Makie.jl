import Pkg
Pkg.pkg"add CairoMakie#jk/scatter-glyphs AbstractPlotting#jk/textlayouting"
using Documenter, Literate, Glob
# avoid font caching warning in docs
using AbstractPlotting, CairoMakie, MakieLayout
CairoMakie.activate!()
scatter(rand(10), rand(10))

# generate examples
GENERATED = joinpath(@__DIR__, "src", "literate")
SOURCE_FILES = Glob.glob("*.jl", GENERATED)
foreach(fn -> Literate.markdown(fn, GENERATED), SOURCE_FILES)

makedocs(
         sitename="MakieRecipes",
         pages = Any[
                     "index.md",
                     "literate/example.md",
                    ]
        )

deploydocs(
    repo = "github.com/JuliaPlots/MakieRecipes.jl.git",
    push_preview = true
)
