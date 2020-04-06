import Pkg
# Pkg.pkg"add CairoMakie#jk/scatter-glyphs AbstractPlotting#jk/text-layouting"
using Documenter, Literate
# avoid font caching warning in docs
using AbstractPlotting, CairoMakie, MakieLayout
CairoMakie.activate!()
scatter(rand(10), rand(10))

# generate examples
GENERATED = joinpath(@__DIR__, "src", "literate")
SOURCE_FILES = joinpath.(GENERATED, ["examples.jl"])
foreach(fn -> Literate.markdown(fn, GENERATED), SOURCE_FILES)

makedocs(
         sitename="MakieRecipes",
         pages = Any[
                     "index.md",
                     "Examples" => "literate/examples.md",
                    ]
        )

deploydocs(
    repo = "github.com/JuliaPlots/MakieRecipes.jl.git",
    push_preview = true
)
