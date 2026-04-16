function record_comparison(base_folder::String, backend::String; record_folder_name = "recorded", tag = last_major_version())
    record_folder = joinpath(base_folder, record_folder_name)
    @info "Downloading reference images"
    reference_folder = download_refimages(tag)
    # we copy the reference images into the output folder, since we want to upload it all as an artifact, to know against what images we compared
    local_reference_copy_dir = joinpath(base_folder, "reference")
    if isdir(local_reference_copy_dir)
        rm(local_reference_copy_dir, recursive = true)
    end
    cp(reference_folder, local_reference_copy_dir)
    testimage_paths = get_all_relative_filepaths_recursively(record_folder)
    missing_refimages, scores = compare(testimage_paths, reference_folder, record_folder)

    open(joinpath(base_folder, "new_files.txt"), "w") do file
        for path in missing_refimages
            println(file, path)
        end
    end

    open(joinpath(base_folder, "missing_files.txt"), "w") do file
        ref_backend_aliases = Dict("SkiaMakie" => "CairoMakie")
        ref_backend = get(ref_backend_aliases, backend, backend)
        backend_ref_dir = joinpath(reference_folder, ref_backend)
        recorded_paths = mapreduce(vcat, walkdir(backend_ref_dir)) do (root, dirs, files)
            relpath.(joinpath.(root, files), reference_folder)
        end
        skipped = Set([joinpath(backend, "$name.png") for name in SKIPPED_NAMES])
        missing_recordings = setdiff(Set(recorded_paths), Set(testimage_paths), skipped)

        for path in missing_recordings
            println(file, path)
        end
    end

    open(joinpath(base_folder, "scores.tsv"), "w") do file
        paths_scores = sort(collect(pairs(scores)), by = last, rev = true)
        for (path, score) in paths_scores
            println(file, score, '\t', path)
        end
    end

    return missing_refimages, scores
end

function test_comparison(scores; threshold)
    return @testset "Comparison scores" begin
        for (image, score) in pairs(scores)
            @testset "$image" begin
                @test score <= threshold
            end
        end
    end
end

function compare(
        relative_test_paths::Vector{String}, reference_dir::String, record_dir;
        o_refdir = reference_dir, missing_refimages = String[],
        scores = Dict{String, Float64}()
    )

    # Allow backends to share reference images (e.g. SkiaMakie → CairoMakie)
    ref_backend_aliases = Dict("SkiaMakie" => "CairoMakie")

    for relative_test_path in relative_test_paths
        # Remap backend prefix in the reference path if an alias exists
        ref_relative = relative_test_path
        for (from, to) in ref_backend_aliases
            if startswith(ref_relative, from * "/") || startswith(ref_relative, from * "\\")
                ref_relative = to * ref_relative[length(from)+1:end]
                break
            end
        end
        ref_path = joinpath(reference_dir, ref_relative)
        rec_path = joinpath(record_dir, relative_test_path)
        if !isfile(ref_path)
            push!(missing_refimages, relative_test_path)
        elseif endswith(ref_path, ".html")
            # ignore
        else
            diff = compare_media(rec_path, ref_path)
            scores[relative_test_path] = diff
        end
    end
    return missing_refimages, scores
end
