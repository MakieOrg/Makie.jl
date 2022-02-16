function serve_update_page(folder)

    folder = realpath(folder)
    @assert isdir(folder) "$folder is not a valid directory."
    refimages_name = last(splitpath(realpath(folder)))
    @info "Refimage set name is $refimages_name"

    router = HTTP.Router()

    function receive_update(req)
        images = JSON3.read(req.body)
        
        tempdir = tempname()
        recorded_folder = joinpath(folder, "recorded")
        reference_folder = joinpath(folder, "reference")

        @info "Copying reference folder to $tempdir"
        cp(reference_folder, tempdir)

        for image in images
            @info "Overwriting $image in new reference folder"
            cp(joinpath(recorded_folder, image), joinpath(tempdir, image), force = true)
        end

        @info "Uploading updated reference images"
        try
            upload_reference_images(tempdir, "julius-test-tag"; name = refimages_name)

            HTTP.Response(200, "Upload successful")
        catch e
            showerror(stdout, e, catch_backtrace())
            HTTP.Response(404)
        end
    end

    function serve_local_file(req)
        req.target == "/" && return HTTP.Response(200,
            read(normpath(joinpath(dirname(pathof(ReferenceTests)), "reference_images.html"))))
        file = HTTP.unescapeuri(req.target[2:end])
        filepath = normpath(joinpath(folder, file))
        # check that we don't go outside of the artifact folder
        if !startswith(filepath, folder)
            @info "$file leads to $filepath which is outside of the artifact folder."
            return HTTP.Response(404)
        end

        if !isfile(filepath)
            return HTTP.Response(404)
        else
            return HTTP.Response(200, read(filepath))
        end
    end

    HTTP.@register(router, "POST", "/", receive_update)
    HTTP.@register(router, "GET", "/", serve_local_file)

    @info "Starting server"
    HTTP.serve(router, HTTP.Sockets.localhost, 8000)
end

# function serve_pr_update_page(pr_number)
#     prinfo = JSON3.read(HTTP.get("https://api.github.com/repos/JuliaPlots/Makie.jl/pulls/$pr_number").body)
function serve_update_page_for_commit(headsha; check_run_startswith = "GLMakie Julia 1.6")
    authget(url) = HTTP.get(url, Dict("Authorization" => "token $(ENV["GITHUB_TOKEN"])"))
    # headsha = prinfo["head"]["sha"]
    checksinfo = JSON3.read(authget("https://api.github.com/repos/JuliaPlots/Makie.jl/commits/$headsha/check-runs").body)
    checkvec = filter(x -> startswith(x["name"], check_run_startswith), checksinfo["check_runs"])
    if length(checkvec) == 1
        check = only(checkvec)
    else
        error("Found not 1 check but $(length(checkvec))")
    end
    job = JSON3.read(authget("https://api.github.com/repos/JuliaPlots/Makie.jl/actions/jobs/$(check["id"])").body)
    run = JSON3.read(authget(job["run_url"]).body)
    artifacts = JSON3.read(authget(run["artifacts_url"]).body)["artifacts"]
    for a in artifacts
        if endswith(a["name"], "1.6")
            @info "Choosing artifact $(a["name"])"
            download_url = a["archive_download_url"]
            @info "Downloading artifact from $download_url"
            filepath = Downloads.download(download_url, headers = Dict("Authorization" => "token $(ENV["GITHUB_TOKEN"])"))
            @info "Download successful"
            tmpdir = mktempdir()
            unzip(filepath, tmpdir)

            folders = readdir(tmpdir)
            if length(folders) == 0
                error("No folder in zip")
            elseif length(folders) == 1
                folder = only(folders)
            else
                menu = REPL.TerminalMenus.RadioMenu(folders, pagesize=4)
                choice = REPL.TerminalMenus.request("Choose a reference image set:", menu)

                if choice == -1
                    error("Cancelled")
                end
                folder = folders[choice]
            end

            @info "Serving update page for folder $folder"
            serve_update_page(joinpath(tmpdir, folder))
            return 
        end
    end
    error("No GLMakie reference image artifact found for $headsha")
end

function unzip(file, exdir = "")
    @info "Extracting zip file $file"
    fileFullPath = isabspath(file) ?  file : joinpath(pwd(),file)
    basePath = dirname(fileFullPath)
    outPath = (exdir == "" ? basePath : (isabspath(exdir) ? exdir : joinpath(pwd(),exdir)))
    isdir(outPath) ? "" : mkdir(outPath)
    zarchive = ZipFile.Reader(fileFullPath)
    for f in zarchive.files
        fullFilePath = joinpath(outPath,f.name)
        if (endswith(f.name,"/") || endswith(f.name,"\\"))
            mkdir(fullFilePath)
        else
            write(fullFilePath, read(f))
        end
    end
    close(zarchive)
    @info "Extracted zip file"
end