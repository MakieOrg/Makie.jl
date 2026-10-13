const ALL_BACKENDS = ("GLMakie", "CairoMakie", "WGLMakie")

function add_manifest_selection(
        upload_paths, delete_paths, reference_folder::AbstractString;
        manifest_dir = refimage_manifest_dir()
    )
    prune_inert!(reference_folder, manifest_dir)   # drop already-promoted / stale fragments
    for p in upload_paths
        write_entry(RefimageUpdate(String(p), pin_for(p, reference_folder)), manifest_dir)
    end
    for p in delete_paths
        write_entry(RefimageUpdate(String(p), "delete"), manifest_dir)
    end
    return manifest_dir
end

add_to_manifest(paths, reference_folder; manifest_dir = refimage_manifest_dir()) =
    add_manifest_selection(paths, String[], reference_folder; manifest_dir)

"""
    review_pin_state(path, score, pinned_paths; threshold = 0.05)

What a reviewed image needs: `:pinned` when an active pin file already covers it,
`:unpinned` when it differs enough to need one, and `:unchanged` when it is only shown to
compare against another backend that differs.
"""
function review_pin_state(path, score, pinned_paths; threshold = 0.05)
    path in pinned_paths && return :pinned
    return score > threshold ? :unpinned : :unchanged
end

function manifest_candidates(artifact_dir, select; threshold, backends)
    if select isa AbstractVector
        paths = Set(String.(select))
    elseif select === :auto
        paths = Set{String}()
        scores_file = joinpath(artifact_dir, "scores.tsv")
        if isfile(scores_file)
            for line in eachline(scores_file)
                isempty(strip(line)) && continue
                score_str, path = split(line, '\t')
                parse(Float64, score_str) > threshold && push!(paths, String(path))
            end
        end
        new_file = joinpath(artifact_dir, "new_files.txt")
        if isfile(new_file)
            for line in eachline(new_file)
                p = strip(line)
                isempty(p) && continue
                push!(paths, String(p))
            end
        end
    else
        error("`select` must be `:auto` or a vector of `<Backend>/<name>.png` paths, got $(repr(select))")
    end
    return sort!(filter(p -> any(b -> startswith(p, b * "/"), backends), collect(paths)))
end

"""
    add_pr_updates_to_manifest(pr; select=:auto, ...)

Add the reference image updates a PR's CI run recorded to the manifest, without running
any tests locally. The changed/new classification comes from the PR's `ReferenceImages`
artifact and the pinned hashes from the current release tarball.

`select = :auto` picks every image whose score exceeds `threshold` plus every new image;
pass a vector of `<Backend>/<name>.png` paths to select explicitly.
"""
function add_pr_updates_to_manifest(
        pr = nothing; commit = nothing, select = :auto, threshold = 0.05,
        backends = ALL_BACKENDS,
        tag = last_major_version(), manifest_dir = refimage_manifest_dir()
    )
    artifact_dir = download_artifacts(; pr, commit)
    reference_folder = cached_refimages(tag)
    paths = manifest_candidates(artifact_dir, select; threshold, backends)
    if isempty(paths)
        @info "No candidate images to add to the manifest."
        return manifest_dir
    end
    add_to_manifest(paths, reference_folder; manifest_dir)
    @info "Added $(length(paths)) entr$(length(paths) == 1 ? "y" : "ies") to $manifest_dir"
    return manifest_dir
end

function reference_paths_by_title(reference_folder, backends)
    by_title = Dict{String, Vector{String}}()
    for (root, _, files) in walkdir(reference_folder), file in files
        path = replace(relpath(joinpath(root, file), reference_folder), '\\' => '/')
        any(b -> startswith(path, b * "/"), backends) || continue
        push!(get!(by_title, recording_title(path), String[]), path)
    end
    return by_title
end

"""
    title_image_paths(titles, backends, reference_folder)

The `<Backend>/...` paths of the images that the reference tests `titles` produce. A title
with stored references maps to all of its stored images in `backends` (stepper frames and
videos included); a title without any maps to `<Backend>/<title>.png` in every backend.
"""
function title_image_paths(titles, backends, reference_folder)
    by_title = reference_paths_by_title(reference_folder, backends)
    paths = String[]
    for title in titles
        append!(paths, get(() -> ["$b/$title.png" for b in backends], by_title, title))
    end
    return sort!(paths)
end

"""
    pin_images(titles; backends = $(ALL_BACKENDS), delete = false, tag = last_major_version())

Add manifest entries for the images of the reference tests `titles` without any CI run:
changed tests are pinned to the hash of their current reference, tests without a stored
reference are pinned as `new`, and `delete = true` marks the stored images for deletion.
Pass `backends` when a new test does not run in every backend. The reference images are
cached and only downloaded again when the release changes.
"""
function pin_images(
        titles; backends = ALL_BACKENDS, delete = false,
        tag = last_major_version(), manifest_dir = refimage_manifest_dir()
    )
    reference_folder = cached_refimages(tag)
    paths = title_image_paths(titles, backends, reference_folder)
    upload_paths, delete_paths = delete ? (String[], paths) : (paths, String[])
    add_manifest_selection(upload_paths, delete_paths, reference_folder; manifest_dir)
    @info "Pinned $(length(paths)) image$(length(paths) == 1 ? "" : "s") in $manifest_dir" paths
    return paths
end

function read_path_list(file)
    paths = Set{String}()
    isfile(file) || return paths
    for line in eachline(file)
        p = strip(line)
        isempty(p) || push!(paths, String(p))
    end
    return paths
end

"""
    approval_coverage(root_path; threshold=0.05, reference_folder=joinpath(root_path, "reference"))

Count the new, changed and deleted reference images in a `ReferenceImages` artifact folder
and how many of them are approved by an active manifest entry. `threshold` is the CI
comparison threshold (an image scoring above it needs approval, as does every new or
deleted image). Returns `(; new, changed, deleted)`, each a `(; total, approved)` count;
all categories approved means the PR is ready to merge.
"""
function approval_coverage(root_path; threshold = 0.05, reference_folder = joinpath(root_path, "reference"))
    changed = Set{String}()
    scores_file = joinpath(root_path, "scores.tsv")
    if isfile(scores_file)
        for line in eachline(scores_file)
            isempty(strip(line)) && continue
            s, p = split(line, '\t')
            parse(Float64, s) > threshold && push!(changed, String(p))
        end
    end
    new_unapproved = read_path_list(joinpath(root_path, "new_files.txt"))
    missing_recordings = read_path_list(joinpath(root_path, "missing_files.txt"))

    c = classify_entries(read_manifest(joinpath(root_path, "refimage_updates")), reference_folder)
    counts(total, approved) = (; total = length(total), approved = length(approved))
    return (;
        new = counts(union(new_unapproved, c.exempt_new), c.exempt_new),
        changed = counts(changed, intersect(changed, c.exempt_changed)),
        deleted = counts(union(missing_recordings, c.to_delete), c.to_delete),
    )
end

total_images(cov) = cov.new.total + cov.changed.total + cov.deleted.total
approved_images(cov) = cov.new.approved + cov.changed.approved + cov.deleted.approved
fully_approved(cov) = total_images(cov) == approved_images(cov)

function coverage_summary(cov)
    parts = [
        "$(c.approved)/$(c.total) $name"
            for (name, c) in (("new", cov.new), ("changed", cov.changed), ("deleted", cov.deleted))
            if c.total > 0
    ]
    isempty(parts) && return "No new, changed or deleted images"
    return "Approved " * join(parts, ", ") * " images"
end

"""
    promote_manifest(recorded_dir, tag=last_major_version())

Splice the manifest's active updates into the `refimages-<tag>` release tarball and
re-upload it. `recorded_dir` is a folder of `<Backend>/<name>.png` recorded images (the
`recorded/` subtree of a `ReferenceImages` artifact). Inert entries are skipped.
"""
function promote_manifest(recorded_dir::AbstractString, tag = last_major_version())
    entries = read_manifest()
    tmpdir = download_refimages(tag)
    try
        classified = classify_entries(entries, tmpdir)
        for path in union(classified.exempt_changed, classified.exempt_new)
            source = joinpath(recorded_dir, normpath(path))
            isfile(source) || error("Recorded image missing for manifest entry: $path")
            target = joinpath(tmpdir, normpath(path))
            mkpath(splitdir(target)[1])
            cp(source, target, force = true)
        end
        for path in classified.to_delete
            target = joinpath(tmpdir, normpath(path))
            isfile(target) && rm(target)
        end
        n_promoted = length(classified.exempt_changed) + length(classified.exempt_new) + length(classified.to_delete)
        if n_promoted == 0
            @info "No active manifest entries to promote for $tag."
            return
        end
        @info "Promoting $n_promoted manifest entr$(n_promoted == 1 ? "y" : "ies") into refimages-$tag"
        upload_reference_images(tmpdir, tag)
    finally
        rm(tmpdir; force = true, recursive = true)
    end
    return
end
