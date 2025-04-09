function get_frames(a, b)
    return (get_frames(a), get_frames(b))
end

rgbaf_convert(x::AbstractMatrix{<:Union{RGB,RGBA}}) = convert(Matrix{RGBAf}, x)

function get_frames(video::AbstractString)
    mktempdir() do folder
        afolder = joinpath(folder, "a")
        mkpath(afolder)
        Makie.extract_frames(video, afolder)
        aframes = joinpath.(afolder, readdir(afolder))
        if length(aframes) > 10
            # we don't want to compare too many frames since it's time costly
            # so we just compare 10 random frames if more than 10
            samples = range(1, stop=length(aframes), length=10)
            istep = round(Int, length(aframes) / 10)
            samples = 1:istep:length(aframes)
            aframes = aframes[samples]
        end
        return load.(aframes)
    end
end

function compare_images(a::AbstractMatrix{<:Union{RGB,RGBA}}, b::AbstractMatrix{<:Union{RGB,RGBA}})

    a = rgbaf_convert(a)
    b = rgbaf_convert(b)

    if size(a) != size(b)
        @warn "images don't have the same size, difference will be Inf"
        return Inf
    end

    approx_tile_size_px = 30

    range_dim1 = round.(Int, range(0, size(a, 1), length = ceil(Int, size(a, 1) / approx_tile_size_px)))
    range_dim2 = round.(Int, range(0, size(a, 2), length = ceil(Int, size(a, 2) / approx_tile_size_px)))

    boundary_iter(boundaries) = zip(boundaries[1:end-1] .+ 1, boundaries[2:end])

    _norm(rgb1::RGBf, rgb2::RGBf) = sqrt(sum(((rgb1.r - rgb2.r)^2, (rgb1.g - rgb2.g)^2, (rgb1.b - rgb2.b)^2)))
    _norm(rgba1::RGBAf, rgba2::RGBAf) = sqrt(sum(((rgba1.r - rgba2.r)^2, (rgba1.g - rgba2.g)^2, (rgba1.b - rgba2.b)^2, (rgba1.alpha - rgba2.alpha)^2)))

    # compute the difference score as the maximum of the mean squared differences over the color
    # values of tiles over the image. using tiles is a simple way to increase the local sensitivity
    # without directly going to pixel-based comparison
    # it also makes the scores more comparable between reference images of different sizes, because the same
    # local differences would be normed to different mean scores if the images have different numbers of pixels
    return maximum(Iterators.product(boundary_iter(range_dim1), boundary_iter(range_dim2))) do ((mi1, ma1), (mi2, ma2))
        @views mean(_norm.(a[mi1:ma1, mi2:ma2], b[mi1:ma1, mi2:ma2]))
    end
end

function compare_media(a::AbstractString, b::AbstractString)
    _, ext = splitext(a)
    if ext in (".png", ".jpg", ".jpeg", ".JPEG", ".JPG")
        imga = load(a)
        imgb = load(b)
        return compare_images(imga, imgb)
    elseif ext in (".mp4", ".gif")
        aframes = get_frames(a)
        bframes = get_frames(b)
        # Frames can differ in length, which usually shouldn't be the case but can happen
        # when the implementation of record changes, or when the example changes its number of frames
        # In that case, we just return inf + warn
        if length(aframes) != length(bframes)
            @warn "not the same number of frames in video, difference will be Inf"
            return Inf
        end
        return maximum(compare_images.(aframes, bframes))
    else
        error("Unknown media extension: $ext")
    end
end

function get_all_relative_filepaths_recursively(dir)
    mapreduce(vcat, walkdir(dir)) do (root, dirs, files)
        relpath.(joinpath.(root, files), dir)
    end
end

function record_comparison(base_folder::String, backend::String; record_folder_name="recorded", tag=last_major_version())
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
        backend_ref_dir = joinpath(reference_folder, backend)
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
    @testset "Comparison scores" begin
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
        scores = Dict{String,Float64}()
    )

    for relative_test_path in relative_test_paths
        ref_path = joinpath(reference_dir, relative_test_path)
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
