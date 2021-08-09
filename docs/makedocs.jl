using Pkg
Pkg.activate(".")
pkg"dev .. ../CairoMakie ../GLMakie ../WGLMakie"
Pkg.instantiate()
Pkg.precompile()

using NodeJS
using Franklin
using Documenter: deploydocs, deploy_folder, GitHubActions

run(`$(npm_cmd()) install highlight.js`)

cfg = GitHubActions() # this should pick up all details via GHA environment variables

repo = "github.com/JuliaPlots/Makie.jl.git"
push_preview = true

deploydecision = deploy_folder(cfg; repo, push_preview,
    devbranch = "master",
    devurl = "dev",
)

@info "Setting PREVIEW_FRANKLIN_WEBSITE_URL to $repo"
ENV["PREVIEW_FRANKLIN_WEBSITE_URL"] = repo
@info "Setting PREVIEW_FRANKLIN_PREPATH to $(deploydecision.subfolder)"
ENV["PREVIEW_FRANKLIN_PREPATH"] = deploydecision.subfolder


optimize()

deploydocs(;
    repo,
    push_preview,
    target = "__site",
)