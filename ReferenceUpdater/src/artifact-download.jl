const URL_CACHE = Dict{String, String}()

function wipe_cache!()
    for path in values(URL_CACHE)
        rm(path, recursive = true)
    end
    empty!(URL_CACHE)
    return
end

function download_artifacts(; commit = nothing, pr = nothing)
    authget(url) = HTTP.get(url, Dict("Authorization" => "token $(github_token())"))

    commit !== nothing && pr !== nothing && error("Keyword arguments `commit` and `pr` can't be set at once.")
    if pr !== nothing
        prinfo = JSON3.read(authget("https://api.github.com/repos/MakieOrg/Makie.jl/pulls/$pr").body)
        headsha = prinfo["head"]["sha"]
        @info "PR is $pr, using last commit hash $headsha"
    elseif commit !== nothing
        headsha = commit
    else
        error("You have to specify either the keyword argument `commit` or `pr`.")
    end

    checksinfo = JSON3.read(authget("https://api.github.com/repos/MakieOrg/Makie.jl/commits/$headsha/check-runs").body)

    # Somehow identical artifacts can occur double, but with different ids?
    # I don't know what happens, but we need to filter them out!
    unique_artifacts = Set{String}()
    checkruns = filter(checksinfo["check_runs"]) do checkrun
        name = checkrun["name"]
        id = checkrun["id"]

        if name == "Merge artifacts"
            job = JSON3.read(authget("https://api.github.com/repos/MakieOrg/Makie.jl/actions/jobs/$(id)").body)
            run = JSON3.read(authget(job["run_url"]).body)
            if run["status"] != "completed"
                @info "$(name)'s run hasn't completed yet, no artifacts will be available."
                return false
            else
                return true
            end
        else
            return false
        end
    end

    if isempty(checkruns)
        error("\"Merge artifacts\" run is not available.")
    end
    if length(checkruns) > 1
        datetimes = map(checkruns) do checkrun
            DateTime(checkrun["completed_at"], dateformat"y-m-dTH:M:SZ")
        end
        datetime, idx = findmax(datetimes)
        @warn("Found multiple checkruns for \"Merge artifacts\". Using latest with timestamp: $datetime")
        check = checkruns[idx]
    else
        check = only(checkruns)
    end

    job = JSON3.read(authget("https://api.github.com/repos/MakieOrg/Makie.jl/actions/jobs/$(check["id"])").body)
    run = JSON3.read(authget(job["run_url"]).body)

    artifacts = JSON3.read(authget(run["artifacts_url"]).body)["artifacts"]

    for a in artifacts
        if a["name"] == "ReferenceImages"
            @info "Choosing artifact \"$(a["name"])\""
            download_url = a["archive_download_url"]
            if !haskey(URL_CACHE, download_url)
                @info "Downloading artifact from $download_url"
                filepath = Downloads.download(
                    download_url,
                    headers = Dict("Authorization" => "token $(github_token())"),
                    progress = download_progress_callback,
                )
                @info "Download successful"
                tmpdir = mktempdir()
                unzip(filepath, tmpdir)
                rm(filepath)
                URL_CACHE[download_url] = tmpdir
            else
                tmpdir = URL_CACHE[download_url]
                @info "$download_url cached at $tmpdir"
            end

            return tmpdir
        end
    end

    error(
        """
            No \"ReferenceImages\" artifact found for commit $headsha and job id $(check["id"]).
            This could be because the job's workflow run ($(job["run_url"])) has not completed, yet.
            Artifacts are only available for complete runs.
        """
    )
end

function unzip(file, exdir = "")
    fileFullPath = isabspath(file) ? file : joinpath(pwd(), file)
    basePath = dirname(fileFullPath)
    outPath = (exdir == "" ? basePath : (isabspath(exdir) ? exdir : joinpath(pwd(), exdir)))
    isdir(outPath) ? "" : mkdir(outPath)
    @info "Extracting zip file $file to $outPath"
    zarchive = ZipFile.Reader(fileFullPath)
    for f in zarchive.files
        fullFilePath = joinpath(outPath, f.name)
        if (endswith(f.name, "/") || endswith(f.name, "\\"))
            mkdir(fullFilePath)
        else
            mkpath(dirname(fullFilePath))
            write(fullFilePath, read(f))
        end
    end
    close(zarchive)
    return @info "Extracted zip file"
end
