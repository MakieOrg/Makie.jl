using Pkg
cd(@__DIR__)
Pkg.activate(".")
pkg"dev .. ../MakieCore ../CairoMakie ../GLMakie ../WGLMakie ../RPRMakie"
pkg"add MeshIO GeometryBasics JSServe"
Pkg.instantiate()
Pkg.precompile()

using NodeJS
run(`$(npm_cmd()) install highlight.js`)
run(`$(npm_cmd()) install lunr`)
run(`$(npm_cmd()) install cheerio`)

using Downloads
stork = Downloads.download("https://files.stork-search.net/releases/v1.4.2/stork-ubuntu-20-04")
run(`chmod +x $stork`)
success(`$stork`)

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

include("deploydocs.jl")

docs_url = "docs.makie.org"
repo = "github.com/MakieOrg/Makie.jl.git"
push_preview = true
devbranch = "master"
devurl = "dev"

params = deployparameters(; repo, devbranch, devurl, push_preview)

@info "Setting PREVIEW_FRANKLIN_WEBSITE_URL to $docs_url"
ENV["PREVIEW_FRANKLIN_WEBSITE_URL"] = docs_url

"""
Converts the string `s` which might be an absolute path,
to a relative path, relative to the current location `here`
"""
function make_relative(s, here)
    if !startswith(s, "/")
        return s
    end

    there = s[2:end]

    if here == ""
        return there
    end

    hereparts = split(here, "/")
    thereparts = split(there, "/")

    # tutorials/layout-tutorial   tutorials/
    closest_common = 0
    for i in 1:min(length(thereparts), length(hereparts))
        if hereparts[i] == thereparts[i]
            closest_common = i
        else
            break
        end
    end
    n_up = length(hereparts) - closest_common
    therepart = join(thereparts[(closest_common + 1):end], "/")
    if n_up == 0
        therepart
    else
        up_part = join((".." for i in 1:n_up), "/")
        if therepart == ""
            up_part
        else
            up_part * "/" * therepart
        end
    end
end

"""
Replaces all absolute links in all html files in the __site folder with
relative links.
"""
function make_links_relative()
    old = pwd()
    try
        cd("__site")
        for (root, _, files) in walkdir(".")
            path = join(splitpath(root)[2:end], "/")

            html_files = filter(endswith(".html"), files)
            for file in html_files
                s = read(joinpath(root, file), String)
                s = replace(s, '\0' => "\\0")

                html = parsehtml(s)

                for e in PreOrderDFS(html.root)
                    if (e isa HTMLElement{:script} || e isa HTMLElement{:img} || e isa HTMLElement{:video}) &&
                       haskey(e.attributes, "src")
                        link = e.attributes["src"]
                        e.attributes["src"] = make_relative(link, path)

                    elseif (e isa HTMLElement{:link} || e isa HTMLElement{:a}) && haskey(e.attributes, "href")
                        link = e.attributes["href"]
                        e.attributes["href"] = make_relative(link, path)

                    elseif e isa HTMLElement{:form} && haskey(e.attributes, "action")
                        link = e.attributes["action"]
                        e.attributes["action"] = make_relative(link, path)
                    end
                end

                open(joinpath(root, file), "w") do f
                    return print(f, html)
                end
            end
        end
    finally
        cd(old)
    end
end

using GLMakie
GLMakie.activate!(pause_renderloop=true)

serve(; single=true, cleanup=false, fail_on_warning=true)
# for interactive development of the docs, use:
# cd(@__DIR__); serve(single=false, cleanup=true, clear=true, fail_on_warning = false)


function populate_stork_config(subfolder)
    wd = pwd()
    sites = []
    tempdir = mktempdir()

    _get(el, type) = el.children[findfirst(x -> x isa type, el.children)]

    try
        cd("__site/")
        for (root, dirs, files) in walkdir(".")
            if any(x -> startswith(root, x), ["libs", "css", "assets"])
                continue
            end
            f = filter(endswith(".html"), files)
            isempty(f) && continue

            for file in f
                s = read(joinpath(root, file), String)
                s = replace(s, '\0' => "\\0")

                html = parsehtml(s)
                head = _get(html.root, HTMLElement{:head})
                title = _get(head, HTMLElement{:title})
                titletext = _get(title, HTMLText).text

                for e in PreOrderDFS(html.root)
                    if e isa HTMLElement
                        filter!(child -> !(child isa HTMLElement{:script}), e.children)
                    end
                end

                randfilepath = joinpath(tempdir, Random.randstring(20) * ".html")
                open(joinpath(tempdir, randfilepath), "w") do io
                    print(io, html)
                end

                push!(sites, (
                    title = titletext,
                    path = randfilepath,
                    url = normpath(joinpath(root, file)), # remove "./" prefix
                ))
            end
        end
    finally
        cd(wd)
    end

    for file in ["config_box", "config_page"]
        cp("__site/libs/stork/$(file).toml", "__site/libs/stork/$(file)_filled.toml", force = true)

        toml = TOML.parsefile("__site/libs/stork/$(file).toml")
        open("__site/libs/stork/$(file)_filled.toml", "w") do io
            toml["input"]["files"] = map(Dict ∘ pairs, sites)
            toml["input"]["url_prefix"] = isempty(subfolder) ? "/" : "/" * subfolder * "/" # then url without / prefix
            TOML.print(io, toml, sorted = true)
        end
    end
    return
end

function run_stork()
    wd = pwd()
    try
        cd("__site/libs/stork")
        run(`$stork build --input config_box_filled.toml --output index_box.st`)
        run(`$stork build --input config_page_filled.toml --output index_page.st`)
    finally
        cd(wd)
    end
end

populate_stork_config(params.subfolder)
run_stork()

# lunr()
# optimize(; minify=false, prerender=false)

# by making all links relative, we can forgo the `prepath` setting of Franklin
# which means that files in some `vX.Y.Z` subfolder which happens to be `stable`
# at the time, link relatively within `stable` so that users don't accidentally
# copy & paste versioned links if they started out on `stable`
@info "Rewriting all absolute links as relative"
make_links_relative()


deploy(
    params;
    target = "__site",
)
