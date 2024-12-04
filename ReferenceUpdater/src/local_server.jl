const URL_CACHE = Dict{String, String}()

function wipe_cache!()
    for path in values(URL_CACHE)
        rm(path, recursive = true)
    end
    empty!(URL_CACHE)
    return
end

function serve_update_page_from_dir(folder)

    folder = realpath(folder)
    @assert isdir(folder) "$folder is not a valid directory."
    group_scores(folder)
    group_files(folder, "new_files.txt", "new_files_grouped.txt")
    group_files(folder, "missing_files.txt", "missing_files_grouped.txt")

    router = HTTP.Router()

    function receive_update(req)
        data = JSON3.read(req.body)
        images_to_update = data["images_to_update"]
        images_to_delete = data["images_to_delete"]
        tag = data["tag"]

        recorded_folder = joinpath(folder, "recorded")

        @info "Downloading latest reference folder for $tag"
        tempdir = download_refimages(tag)

        @info "Updating files in $tempdir"

        for image in images_to_update
            @info "Overwriting or adding $image"
            copy_filepath = joinpath(tempdir, image)
            copy_dir = splitdir(copy_filepath)[1]
            # make the path in case a new refimage is in a not yet existing folder
            mkpath(copy_dir)
            cp(joinpath(recorded_folder, image), copy_filepath, force = true)
        end

        for image in images_to_delete
            @info "Deleting $image"
            copy_filepath = joinpath(tempdir, image)
            if isfile(copy_filepath)
                rm(copy_filepath, recursive = true)
            else
                @warn "Cannot delete $image - it has already been deleted."
            end
        end

        @info "Uploading updated reference images under tag \"$tag\""
        try
            upload_reference_images(tempdir, tag)
            @info "Upload successful. You can ctrl+c out now."
            HTTP.Response(200, "Upload successful")
        catch e
            showerror(stdout, e, catch_backtrace())
            HTTP.Response(404)
        end
    end

    function serve_local_file(req)
        if req.target == "/"
            s = read(normpath(joinpath(dirname(pathof(ReferenceUpdater)), "reference_images.html")), String)
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

    HTTP.register!(router, "POST", "/", receive_update)
    HTTP.register!(router, "GET", "/", serve_local_file)
    HTTP.register!(router, "GET", "/**", serve_local_file)

    @info "Starting server. Open http://localhost:8849 in your browser to view. Ctrl+C to quit."
    try
        HTTP.serve(router, HTTP.Sockets.localhost, 8849)
    catch e
        if e isa InterruptException
            @info "Server stopped."
        else
            rethrow(e)
        end
    end
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
                filepath = Downloads.download(download_url, headers = Dict("Authorization" => "token $(github_token())"))
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

    error("""
        No \"ReferenceImages\" artifact found for commit $headsha and job id $(check["id"]).
        This could be because the job's workflow run ($(job["run_url"])) has not completed, yet.
        Artifacts are only available for complete runs.
    """)
end

"""
    serve_update_page(; commit, pr)

Create a ReferenceUpdater page which shows the test differences from a CI run
of a given commit hash or pr.
"""
function serve_update_page(; commit = nothing, pr = nothing)
    tmpdir = download_artifacts(commit = commit, pr = pr)
    @info "Serving update page from folder $tmpdir."
    serve_update_page_from_dir(tmpdir)
    return
end

"""
    update_from_previous_version(; source_version, target_version, commit, pr[, score_threshold = 0.03])

Replaces every test that is failing (based on score_threshold) or missing in the
given commit or pr with the respective test from the given `source_version` and
uploads the result to `target_version`.

This is useful for breaking pull requests, where new or changed tests from master
(previous version) should be added to the new, breaking verison. E.g.:
```
update_from_previous_version(source_version = "v0.21.0", target_version = "v0.22.0", pr = 4477)
```
"""
function update_from_previous_version(;
        source_version::String, target_version::String,
        commit = nothing, pr = nothing, score_threshold = 0.03)

    tmpdir = download_artifacts(commit = commit, pr = pr)

    @info "Updating reference images in $target_version from $source_version"
    @info "By score threshold:"
    # missing & changed
    folder = realpath(tmpdir)
    changed_or_missing = open(joinpath(folder, "scores.tsv"), "r") do file
        names = String[]
        for line in eachline(file)
            score_str, filename = split(line, '\t')
            if parse(Float64, score_str) >= score_threshold
                push!(names, filename)
                @info "  $filename"
            end
        end
        return names
    end

    @info "Missing:"
    open(joinpath(folder, "new_files.txt"), "r") do file
        for line in eachline(file)
            if !isempty(line)
                push!(changed_or_missing, line)
                @info "  $line"
            end
        end
    end

    # Get confirmation
    print("Are you sure you want to ")
    printstyled("replace/add", bold = true, color = :red)
    print(" the listed reference images in/to ")
    printstyled("$target_version", bold = true, color = :red)
    print(" with those from ")
    printstyled("$source_version", bold = false, color = :light_red)
    println("? (y/n)")
    input = lowercase(readline())
    if !any(x -> x == input, ["y", "yes"])
        @info "Cancelling"
        return
    end

    update_from_previous_version(changed_or_missing;
        source_version = source_version, target_version = target_version)

    return
end

"""
    update_from_previous_version(changed_or_missing::Vector{String}; source_version, target_version)

Replaces every test in `changed_or_missing` with the respective test from the
given `source_version` and uploads the result to `target_version`. This is the
more manual version of the other method.

Tests should be given as `"backend/name-of-test.png"` in `changed_or_missing`.
Source and target version are given as `"v0.00.0"` matching the respective
github release version.
"""
function update_from_previous_version(
        changed_or_missing::Vector{String};
        source_version::String, target_version::String)

    # Merge new and old
    @info "Downloading new reference image set (target)"
    new_version = download_refimages(target_version)
    @info "Target path: $new_version"
    @info "Downloading old reference image set (source)"
    old_version = download_refimages(source_version)


    @info "Replacing target with source files..."
    for image in changed_or_missing
        @info "Overwriting or adding $image"
        src = joinpath(old_version, image)
        isfile(src) || error("Failed to find file $image in $source_version.")
        trg = joinpath(new_version, image)
        dir, _ = splitdir(trg)
        isdir(dir) || mkdir(dir)
        cp(src, trg, force = true)
    end

    rm(old_version, recursive = true)

    @info "Uploading updated reference images under tag \"$target_version\""
    try
        upload_reference_images(new_version, target_version)
        @info "Upload successful."
        HTTP.Response(200, "Upload successful")
    catch e
        showerror(stdout, e, catch_backtrace())
        HTTP.Response(404)
    end

    return
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
            mkpath(dirname(fullFilePath))
            write(fullFilePath, read(f))
        end
    end
    close(zarchive)
    @info "Extracted zip file"
end


function group_scores(path)
    isfile(joinpath(path, "scores_table.tsv")) && return

    # Load all refimg scores into a Dict
    # `filename => (score_glmakie, score_cairomakie, score_wglmakie)`
    data = Dict{String, Vector{Float64}}()
    open(joinpath(path, "scores.tsv"), "r") do file
        for line in eachline(file)
            score, filepath = split(line, '\t')
            pieces = splitpath(filepath)
            backend = pieces[1]
            filename = join(pieces[2:end], '/')

            scores = get!(data, filename, [-1.0, -1.0, -1.0])
            if backend == "GLMakie"
                scores[1] = parse(Float64, score)
            elseif backend == "CairoMakie"
                scores[2] = parse(Float64, score)
            elseif backend == "WGLMakie"
                scores[3] = parse(Float64, score)
            else
                error("$line -> $backend")
            end
        end
    end

    # sort by max score across all backends so problem come first
    data_vec = collect(pairs(data))
    sort!(data_vec, by = x -> maximum(x[2]), rev = true)

    # generate new file with
    #    GLMakie         CairoMakie        WGLMakie
    # score filename   score filename   score filename
    open(joinpath(path, "scores_table.tsv"), "w") do file
        for (filename, scores) in data_vec
            skip = scores .== -1.0
            println(file,
                ifelse(skip[1], "0.0", scores[1]), '\t', ifelse(skip[1], "", "GLMakie/$filename"), '\t',
                ifelse(skip[2], "0.0", scores[2]), '\t', ifelse(skip[2], "", "CairoMakie/$filename"), '\t',
                ifelse(skip[3], "0.0", scores[3]), '\t', ifelse(skip[3], "", "WGLMakie/$filename")
            )
        end
    end

    return
end

function group_files(path, input_filename, output_filename)
    isfile(joinpath(path, output_filename)) && return

    # Group files in new_files/missing_files into a table like layout:
    #  GLMakie  CairoMakie  WGLMakie

    # collect refimg names and which backends they exist for
    data = Dict{String, Vector{Bool}}()
    open(joinpath(path, input_filename), "r") do file
        for filepath in eachline(file)
            pieces = splitpath(filepath)
            backend = pieces[1]
            if !(backend in ("GLMakie", "CairoMakie", "WGLMakie"))
                error("Failed to parse backend in \"$pieces\", got \"$backend\"")
            end

            filename = join(pieces[2:end], '/')
            exists = get!(data, filename, [false, false, false])

            exists[1] |= backend == "GLMakie"
            exists[2] |= backend == "CairoMakie"
            exists[3] |= backend == "WGLMakie"
        end
    end

    # generate new structured file
    open(joinpath(path, output_filename), "w") do file
        for (filename, valid) in data
            println(file,
                ifelse(valid[1], "GLMakie/$filename", "INVALID"), '\t',
                ifelse(valid[2], "CairoMakie/$filename", "INVALID"), '\t',
                ifelse(valid[3], "WGLMakie/$filename", "INVALID")
            )
        end
    end

    return
end
