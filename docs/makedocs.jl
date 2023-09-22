using Pkg
cd(@__DIR__)
Pkg.activate(".")
pkg"dev .. ../MakieCore ../CairoMakie ../GLMakie ../WGLMakie ../RPRMakie"
Pkg.precompile()

using NodeJS
run(`$(npm_cmd()) install highlight.js`)
run(`$(npm_cmd()) install cheerio`)

using Downloads
using Tar

pagefind = let
    url = if Sys.isapple()
        "https://github.com/CloudCannon/pagefind/releases/download/v0.12.0/pagefind-v0.12.0-aarch64-apple-darwin.tar.gz"
    elseif Sys.islinux()
        "https://github.com/CloudCannon/pagefind/releases/download/v0.12.0/pagefind-v0.12.0-x86_64-unknown-linux-musl.tar.gz"
    else
        error()
    end
    d = Downloads.download(url)
    dir = Tar.extract(`gunzip -c $d`)
    p = joinpath(dir, "pagefind")
    run(`chmod +x $p`)
    p
end
success(`$pagefind`)

# copy NEWS file over to documentation
cp(
    joinpath(@__DIR__, "..", "NEWS.md"),
    joinpath(@__DIR__, "news.md"),
    force = true)

using Franklin
using Documenter: Documenter
using Gumbo
using AbstractTrees
using Random
import TOML
using Dates

include("buildutils/deploydocs.jl")
include("buildutils/relative_links.jl")
include("buildutils/redirect_generation.jl")

docs_url = "docs.makie.org"
repo = "github.com/MakieOrg/Makie.jl.git"
push_preview = true
devbranch = "master"
devurl = "dev"

params = deployparameters(; repo, devbranch, devurl, push_preview)

@info "Setting PREVIEW_FRANKLIN_WEBSITE_URL to $docs_url"
ENV["PREVIEW_FRANKLIN_WEBSITE_URL"] = docs_url

using GLMakie
# remove GLMakie's renderloop completely, because any time `GLMakie.activate!()`
# is called somewhere, it's reactivated and slows down CI needlessly
function GLMakie.renderloop(screen)
    return
end

serve(; single=true, cleanup=false, clear=true, fail_on_warning=true)
# for interactive development of the docs, use:
# cd(@__DIR__); serve(single=false, cleanup=true, clear=true, fail_on_warning = false)

cd("__site") do
    run(`$pagefind --source . --root-selector .franklin-content`)
end

# by making all links relative, we can forgo the `prepath` setting of Franklin
# which means that files in some `vX.Y.Z` subfolder which happens to be `stable`
# at the time, link relatively within `stable` so that users don't accidentally
# copy & paste versioned links if they started out on `stable`
@info "Rewriting all absolute links as relative"
make_links_relative()

generate_redirects([
    "/reference/index.html" => "/examples/index.html",
    r"/reference/blocks/(.*)" => s"/examples/blocks/\1",
    r"/reference/plots/(.*)" => s"/examples/plotting_functions/\1",
    r"/explanations/(.*)" => s"/documentation/\1",
], dry_run = false)

deploy(
    params;
    target = "__site",
)
