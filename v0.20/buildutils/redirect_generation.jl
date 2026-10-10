function generate_redirects(rules; dry_run = true)
    htmlpaths = cd("__site") do
        collect(Iterators.flatmap(walkdir(".")) do (root, dirs, files)
            (chop(joinpath(root, file), head = 1, tail = 0) for file in files if endswith(file, ".html"))
        end)
    end
    redirects_dict = Dict{String,String}()
    for rule in rules
        for path in htmlpaths
            redirect_file = replace(path, rule)
            if redirect_file != path
                redirects_dict[redirect_file] = path
            end
        end
    end
    redirect_files = keys(redirects_dict)
    overwrites = intersect(redirect_files, htmlpaths)
    if !isempty(overwrites)
        strs = ["\"$r\" (redirects to \"$(redirects_dict[r])\")" for r in overwrites]
        error("The following redirect files would overwrite existing files:\n$(join(strs, "\n"))")
    end
    
    for (redirect_file, existing_file) in redirects_dict
        write_redirection_html(redirect_file, existing_file; dry_run)
    end

    return
end

function write_redirection_html(redirect_file, existing_file; dry_run)
    rel = relpath(existing_file, dirname(redirect_file))
    @assert startswith(redirect_file, "/")
    @assert startswith(existing_file, "/")
    
    @info "Adding redirect from $redirect_file to $existing_file"
    if !dry_run
        cd("__site") do
            filepath = "." * redirect_file
            mkpath(splitdir(filepath)[1])
            open(filepath, "w") do io
                print(io, """
                <!DOCTYPE HTML>
                <html lang="en-US">
                    <head>
                        <meta charset="UTF-8">
                        <meta http-equiv="refresh" content="0; url=$rel">
                        <link rel="canonical" href="$rel" />
                        <script type="text/javascript">
                            window.location.href = "$rel"
                        </script>
                        <title>Page Redirection</title>
                    </head>
                    <body>
                        If you are not redirected automatically, follow this <a href='$rel'>link</a>.
                    </body>
                </html>
                """)
            end
        end
    end
    return
end
