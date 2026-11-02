function previous_major_version()
    path = basedir("..", "Makie", "Project.toml")
    version = VersionNumber(TOML.parse(String(read(path)))["version"])
    return "v" * string(VersionNumber(version.major, version.minor - 1))
end

"""
    update_from_previous_version(; kwargs...)

For updating a breaking pr with refimages from a previous release.

- `commit = nothing, pr = nothing`: pr/commit to get information about new/missing/changed refimages from
- `target = last_major_version()`: The tag that will be updated
- `source = previous_major_version()`: The tag that provides refimages
- `add_new = true`: Add refimages from source that are new in the CI run
- `delete_missing = true`: Remove refimages that are missing in CI run and do not exist in source
- `replacement_score_threshold = 0.03`: Minimum score needed to replace a refimg in target with a refimg in source
- `backup = true`: Create a copy of the refimages from the pr
"""
function update_from_previous_version(;
        commit = nothing, pr = nothing,
        target = last_major_version(),
        source = previous_major_version(),
        add_new = true,
        delete_missing = true,
        replacement_score_threshold = 0.03,
        backup = true
    )

    scored_path = download_artifacts(commit = commit, pr = pr)
    @info "Done downloading from pr/commit"

    backupdir = nothing
    if backup
        backupdir = mktempdir()
        @info "Backup $scored_path => $backupdir"
        cp(joinpath(scored_path, "reference"), backupdir, force = true)
        @info "Creating backup copy of pr/commit refimages at $backupdir. This will not be deleted automatically by ReferenceUpdater."
    end

    refimg_path = download_refimages(source)
    println()
    @info "Done downloading from source refimages to $refimg_path"

    upload_for_upload_set = Set{String}()
    marked_for_deletion_set = Set{String}()

    if add_new
        add_new_refimages!(upload_for_upload_set, scored_path, refimg_path)
    end

    if delete_missing
        delete_missing_refimages!(marked_for_deletion_set, scored_path, refimg_path)
    end

    replace_refimages!(upload_for_upload_set, scored_path, refimg_path, replacement_score_threshold)

    @info "Updating $target"

    @time upload_selection(
        target,
        upload_for_upload_set,
        marked_for_deletion_set,
        refimg_path
    )

    if !isnothing(backupdir)
        @info "Reminder: Backup in $backupdir will not be cleaned up by ReferenceUpdater. The OS may or may not clean it up."
    end

    isdir(refimg_path) && rm(refimg_path, force = true, recursive = true)

    return
end

function add_new_refimages!(set, scored_path, refimg_path)
    open(joinpath(scored_path, "new_files.txt")) do io
        for filename in eachline(io)
            isfile(joinpath(refimg_path, filename)) || continue
            @info "Adding new refimage $filename"
            push!(set, filename)
        end
        return
    end

    return
end

function delete_missing_refimages!(set, scored_path, refimg_path)
    open(joinpath(scored_path, "missing_files.txt")) do io
        for filename in eachline(io)
            isfile(joinpath(refimg_path, filename)) && continue
            @info "Removing refimage $filename"
            push!(set, filename)
        end
        return
    end

    return
end

function replace_refimages!(set, scored_path, refimg_path, threshold)
    open(joinpath(scored_path, "scores.tsv")) do io
        for line in eachline(io)
            score, filename = split(line, '\t')
            isfile(joinpath(refimg_path, filename)) || continue
            if parse(Float64, score) > threshold
                @info "Replacing $filename with score $score"
                push!(set, filename)
            end
        end
        return
    end

    return
end
