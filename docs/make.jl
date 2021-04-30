using MakieCore
using Documenter

DocMeta.setdocmeta!(MakieCore, :DocTestSetup, :(using MakieCore); recursive = true)

makedocs(;
    modules = [MakieCore],
    authors = "Simon Danisch",
    repo = "https://github.com/SimonDanisch/MakieCore.jl/blob/{commit}{path}#{line}",
    sitename = "MakieCore.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://SimonDanisch.github.io/MakieCore.jl",
        assets = String[],
    ),
    pages = ["Home" => "index.md"],
)

deploydocs(; repo = "github.com/SimonDanisch/MakieCore.jl")
