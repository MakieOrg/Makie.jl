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
    cd("__site") do
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
    end
end