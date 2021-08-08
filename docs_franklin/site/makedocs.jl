using Pkg
Pkg.activate(".")
Pkg.instantiate()

using NodeJS
using Franklin
using Documenter: deploydocs, deployfolder, GithubActions

run(`$(npm_cmd()) install highlight.js`)

cfg = GithubActions() # this should pick up all details via GHA environment variables

repo = "github.com/JuliaPlots/Makie.jl.git"
push_preview = true

deploydecision = deploy_folder(cfg; repo, push_preview)

@info "Setting PREVIEW_FRANKLIN_WEBSITE_URL to $repo"
@info "Setting PREVIEW_FRANKLIN_PREPATH to $(deploydecision.subfolder)"

optimize()

deploydocs(;
    repo,
    push_preview,
    target = "__site",
)