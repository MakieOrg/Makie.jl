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
    invalid_relative_links = Dict{String,Pair{String,String}}()

    function check_local_link!(invalid_relative_links, file_location, link)
        link_without_id = replace(link, r"#[a-zA-Z0-9!_\-\(\)]*$" => "")
        absolute_link = if startswith(link, "/")
            replace(link_without_id, r"^/+" => "")
        else
            normpath(joinpath(file_location, link_without_id))
        end
        _, ext = splitext(absolute_link)
        if !isempty(ext)
            if !isfile(absolute_link)
                push!(invalid_relative_links, absolute_link => (file_location => link))
            end
        else
            if !isfile(joinpath(absolute_link, "index.html"))
                push!(invalid_relative_links, absolute_link => (file_location => link))
            end
        end
    end

    function is_local_link(link)
        !startswith(link, "data:") && !startswith(link, r"https?") && !startswith(link, "#")
    end

    cd("__site") do
        for (root, _, files) in walkdir(".")
            path = join(splitpath(root)[2:end], "/")

            html_files = filter(endswith(".html"), files)
            for file in html_files
                file_location = joinpath(root, file)
                s = read(file_location, String)
                s = replace(s, '\0' => "\\0")

                html = parsehtml(s)

                for e in PreOrderDFS(html.root)
                    if (e isa HTMLElement{:script} || e isa HTMLElement{:img} || e isa HTMLElement{:video}) &&
                    haskey(e.attributes, "src")
                        link = e.attributes["src"]
                        if is_local_link(link)
                            relative_link = make_relative(link, path)
                            check_local_link!(invalid_relative_links, root, link)
                            e.attributes["src"] = relative_link
                        end

                    elseif (e isa HTMLElement{:link} || e isa HTMLElement{:a}) && haskey(e.attributes, "href")
                        link = e.attributes["href"]
                        if is_local_link(link)
                            relative_link = make_relative(link, path)
                            check_local_link!(invalid_relative_links, root, link)
                            e.attributes["href"] = relative_link
                        end

                    elseif e isa HTMLElement{:form} && haskey(e.attributes, "action")
                        link = e.attributes["action"]
                        if is_local_link(link)
                            relative_link = make_relative(link, path)
                            check_local_link!(invalid_relative_links, root, link)
                            e.attributes["action"] = relative_link
                        end
                    end
                end

                open(joinpath(root, file), "w") do f
                    return print(f, html)
                end
            end
        end
    end

    # these two are generated only in deployment
    delete!(invalid_relative_links, "siteinfo.js")
    delete!(invalid_relative_links, "../versions.js")

    for (key, value) in invalid_relative_links
        if startswith(key, "api/@ref")
            @warn "Ignoring an invalid `@ref` link on the API page, this should be fixed: $key $value"
            delete!(invalid_relative_links, key)
        end
    end

    if !isempty(invalid_relative_links)
        error("Found invalid relative links: \n$(join(invalid_relative_links, "\n"))")
    end

    return
end
