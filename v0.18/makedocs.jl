using Pkg
cd(@__DIR__)
Pkg.activate(".")
pkg"dev .. ../MakieCore ../CairoMakie ../GLMakie ../WGLMakie ../RPRMakie"
pkg"add MeshIO GeometryBasics"
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

using Franklin
using Documenter: deploydocs, deploy_folder, GitHubActions
using Gumbo
using AbstractTrees
using Random
import TOML

cfg = GitHubActions() # this should pick up all details via GHA environment variables

repo = "github.com/MakieOrg/Makie.jl.git"
push_preview = true

deploydecision = deploy_folder(cfg; repo, push_preview, devbranch="master", devurl="dev")

@info "Setting PREVIEW_FRANKLIN_WEBSITE_URL to $repo"
ENV["PREVIEW_FRANKLIN_WEBSITE_URL"] = repo

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


function populate_stork_config(deploydecision)
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
    cp("__site/libs/stork/config.toml", "__site/libs/stork/config_filled.toml", force = true)

    toml = TOML.parsefile("__site/libs/stork/config.toml")
    open("__site/libs/stork/config_filled.toml", "w") do io
        toml["input"]["files"] = map(Dict ∘ pairs, sites)
        subf = deploydecision.subfolder
        toml["input"]["url_prefix"] = isempty(subf) ? "" : "/" * subf * "/" # then url without / prefix
        TOML.print(io, toml, sorted = true)
    end

    return
end

function run_stork()
    wd = pwd()
    try
        cd("__site/libs/stork")
        run(`$stork build --input config_filled.toml --output index.st`)
    finally
        cd(wd)
    end
end

populate_stork_config(deploydecision)
run_stork()

# lunr()
optimize(; minify=false, prerender=false)

# by making all links relative, we can forgo the `prepath` setting of Franklin
# which means that files in some `vX.Y.Z` subfolder which happens to be `stable`
# at the time, link relatively within `stable` so that users don't accidentally
# copy & paste versioned links if they started out on `stable`
@info "Rewriting all absolute links as relative"
make_links_relative()

deploydocs(; repo, push_preview, target="__site")
