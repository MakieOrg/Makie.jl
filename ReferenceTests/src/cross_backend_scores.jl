function generate_backend_comparison_scores(root_folder)
    ref = joinpath(root_folder, "GLMakie", "recorded", "GLMakie")
    isdir(ref) || error("GLMakie subfolder $ref must exist")

    for folder in readdir(root_folder)
        isdir(joinpath(root_folder, folder)) || continue

        if folder == "GLMakie" # create dummy file
            close(open(joinpath(root_folder, folder, "cross_backend_scores.tsv"), "w"))
            continue
        end

        @info "Generating comparison scores between $folder and GLMakie"
        generate_backend_comparison_scores(joinpath(root_folder, folder, "recorded", folder), ref)
    end

    return
end

function generate_backend_comparison_scores(target_dir, reference_dir)
    isdir(target_dir) || error("Invalid directory: $target_dir")
    isdir(reference_dir) || error("Invalid directory: $reference_dir")

    target_files = get_all_relative_filepaths_recursively(target_dir)

    return open(joinpath(target_dir, "../../cross_backend_scores.tsv"), "w") do file
        for filepath in target_files
            isfile(joinpath(reference_dir, filepath)) || continue
            diff = compare_media(
                joinpath(target_dir, filepath),
                joinpath(reference_dir, filepath)
            )
            println(file, diff, '\t', filepath)
        end
    end
end
