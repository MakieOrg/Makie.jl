
function run_tests()
    db = load_database()
    recording_dir = joinpath(@__DIR__, "..", "recorded")
    rm(recording_dir, recursive=true, force=true)
    mkdir(recording_dir)
    AbstractPlotting.inline!(true)
    no_backend = AbstractPlotting.current_backend[] === missing
    for (source_location, entry) in db
        AbstractPlotting.set_theme!()
        # we currently can't record anything without a backend!
        if no_backend && ((:Record in entry.used_functions) || (:Stepper in entry.used_functions))
            continue
        end
        result = Base.invokelatest(entry.func)
        # only save if we have a backend for saving
        if !no_backend
            save_result(joinpath(recording_dir, entry.title), result)
        end
        @info("Tested: $(entry.title)")
        @test true
    end
    return
end

function extract_frames(video, frame_folder)
    path = joinpath(frame_folder, "frames%04d.png")
    FFMPEG.ffmpeg_exe(`-loglevel quiet -i $video -y $path`)
end

function compare_media(a, b; sigma=[1,1], eps=0.02)
    file, ext = splitext(a)
    if ext in (".png", ".jpg", ".jpeg", ".JPEG", ".JPG")
        imga = load(a)
        imgb = load(b)
        if size(imga) != size(imgb)
            @warn "images don't have the same size, difference will be Inf"
            return Inf
        end
        return test_approx_eq_sigma_eps(imga, imgb, sigma, eps)
    elseif ext in (".mp4", ".gif")
        mktempdir() do folder
            afolder = joinpath(folder, "a")
            bfolder = joinpath(folder, "b")
            mkpath(afolder); mkpath(bfolder)
            extract_frames(a, afolder)
            extract_frames(b, bfolder)
            aframes = joinpath.(afolder, readdir(afolder))
            bframes = joinpath.(bfolder, readdir(bfolder))
            if length(aframes) > 10
                # we don't want to compare too many frames since it's time costly
                # so we just compare 10 random frames if more than 10
                samples = rand(1:length(aframes), 10)
                aframes = aframes[samples]
                bframes = bframes[samples]
            end
            # test by maximum diff
            return mean(compare_media.(aframes, bframes; sigma=sigma, eps=eps))
        end
    else
        error("Unknown media extension: $ext")
    end
end

function compare(test_dir, reference_dir; missing_refimages=String[], scores=Dict{String,Float64}())
    for test_path in readdir(test_dir, join=true)
        ref_path = joinpath(reference_dir, basename(test_path))
        if isdir(test_path)
            if !isdir(ref_path)
                push!(missing_refimages, test_path)
            else
                compare(test_path, ref_path; missing_refimages=missing_refimages, scores=scores)
            end
        elseif isfile(test_path)
            if !isfile(ref_path)
                push!(missing_refimages, test_path)
            else
                diff = compare_media(test_path, ref_path)
                scores[replace(ref_path, reference_dir => "")] = diff
            end
        end
    end
    return missing_refimages, scores
end

# missing_imgs, scores = compare(recording_dir, joinpath(@__DIR__, "refimages"))
