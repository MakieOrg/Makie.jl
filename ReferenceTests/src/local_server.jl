function serve_update_page_from_dir(folder)

    folder = realpath(folder)
    @assert isdir(folder) "$folder is not a valid directory."
    refimages_name = last(splitpath(realpath(folder)))
    @info "Refimage set name is $refimages_name"

    router = HTTP.Router()

    function receive_update(req)
        data = JSON3.read(req.body)
        images = data["images"]
        tag = data["tag"]

        tempdir = tempname()
        recorded_folder = joinpath(folder, "recorded")
        reference_folder = joinpath(folder, "reference")

        @info "Copying reference folder to \"$tempdir\""
        cp(reference_folder, tempdir)

        for image in images
            @info "Overwriting \"$image\" in new reference folder"
            copy_filepath = joinpath(tempdir, image)
            copy_dir = splitdir(copy_filepath)[1]
            # make the path in case a new refimage is in a not yet existing folder
            mkpath(copy_dir)
            cp(joinpath(recorded_folder, image), copy_filepath, force = true)
        end

        @info "Uploading updated reference images under tag \"$tag\""
        try
            upload_reference_images(tempdir, tag; name = refimages_name)

            HTTP.Response(200, "Upload successful")
        catch e
            showerror(stdout, e, catch_backtrace())
            HTTP.Response(404)
        end
    end

    function serve_local_file(req)
        if req.target == "/"
            s = read(normpath(joinpath(dirname(pathof(ReferenceTests)), "reference_images.html")), String)
            s = replace(s, "DEFAULT_TAG" => "'$(last_major_version())'")
            return HTTP.Response(200, s)
        end
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

    @info "Starting server. Open http://localhost:8849 in your browser to view."
    HTTP.serve(router, HTTP.Sockets.localhost, 8849)
end

function serve_update_page(; commit = nothing, pr = nothing)
    authget(url) = HTTP.get(url, Dict("Authorization" => "token $(ENV["GITHUB_TOKEN"])"))

    commit !== nothing && pr !== nothing && error("Keyword arguments `commit` and `pr` can't be set at once.")
    if pr !== nothing
        prinfo = JSON3.read(authget("https://api.github.com/repos/JuliaPlots/Makie.jl/pulls/$pr").body)
        headsha = prinfo["head"]["sha"]
        @info "PR is $pr, using last commit hash $headsha"
    elseif commit !== nothing
        headsha = commit
    else
        error("You have to specify either the keyword argument `commit` or `pr`.")
    end

    checksinfo = JSON3.read(authget("https://api.github.com/repos/JuliaPlots/Makie.jl/commits/$headsha/check-runs").body)

    checkruns = filter(checksinfo["check_runs"]) do x
        right_combination = any(["GLMakie", "WGLMakie", "CairoMakie"]) do package
            occursin(package, x["name"]) && occursin("1.6", x["name"])
        end
        if right_combination
            job = JSON3.read(authget("https://api.github.com/repos/JuliaPlots/Makie.jl/actions/jobs/$(x["id"])").body)
            run = JSON3.read(authget(job["run_url"]).body)
            if run["status"] != "completed"
                @info "$(x["name"])'s run hasn't completed yet, no artifacts will be available."
                false
            else
                true
            end
        else
            false
        end
    end

    if isempty(checkruns)
        error("No check runs fit the criteria, check if something about names or versions might have changed.")
    end

    menu = REPL.TerminalMenus.RadioMenu([x["name"] for x in checkruns])
    choice = REPL.TerminalMenus.request("Choose a workflow run:", menu)

    if choice == -1
        error("Cancelled")
    end
    check = checkruns[choice]

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

            @info "Serving update page for folder $folder."
            serve_update_page_from_dir(joinpath(tmpdir, folder))
            return
        end
    end
    error("""
        Reference image artifacts found for commit $headsha and job id $(check["id"]).
        This could be because the job's workflow run ($(job["run_url"])) has not completed, yet.
        Artifacts are only available for complete runs.
    """)
end

function unzip(file, exdir = "")
    fileFullPath = isabspath(file) ?  file : joinpath(pwd(),file)
    basePath = dirname(fileFullPath)
    outPath = (exdir == "" ? basePath : (isabspath(exdir) ? exdir : joinpath(pwd(),exdir)))
    isdir(outPath) ? "" : mkdir(outPath)
    @info "Extracting zip file $file to $outPath"
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
