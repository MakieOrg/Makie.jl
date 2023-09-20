function populate_stork_config(subfolder)
    sites = []
    tempdir = mktempdir()

    _get(el, type) = el.children[findfirst(x -> x isa type, el.children)]

    cd("__site/") do
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
    cd("__site/libs/stork") do
        run(`$stork build --input config_box_filled.toml --output index_box.st`)
        run(`$stork build --input config_page_filled.toml --output index_page.st`)
    end
end
