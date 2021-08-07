using Pkg
Pkg.activate(".")
Pkg.instantiate()

using NodeJS
using Franklin
using Documenter: deploydocs

run(`$(npm_cmd()) install highlight.js`)

optimize()

deploydocs(
    repo = "github.com/jkrumbiegel/Makie.jl.git",
    push_preview = true,
    target = "__site",
)