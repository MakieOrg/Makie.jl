
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
        conv(x) = convert(Matrix{RGBf0}, x)
        return Images.test_approx_eq_sigma_eps(conv(imga), conv(imgb), sigma, Inf)
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

function compare(test_files::Vector{String}, reference_dir::String; missing_refimages=String[], scores=Dict{String,Float64}())
    for test_path in test_files
        ref_path = joinpath(reference_dir, basename(test_path))
        if isdir(test_path)
            if !isdir(ref_path)
                push!(missing_refimages, test_path)
            else
                compare(joinpath.(test_path, readdir(test_path)), ref_path; missing_refimages=missing_refimages, scores=scores)
            end
        elseif isfile(test_path)
            if !isfile(ref_path)
                push!(missing_refimages, test_path)
            else
                diff = compare_media(test_path, ref_path)
                name = replace(ref_path, reference_dir => "")[2:end]
                @info(@sprintf "%1.4f == %s\n" diff name)
                scores[name] = diff
            end
        end
    end
    return missing_refimages, scores
end

# missing_imgs, scores = compare(recording_dir, joinpath(@__DIR__, "refimages"))

function reference_tests(recorded; ref_images = ReferenceTests.download_refimages(), difference=0.03)
    @testset "Reference Image Tests" begin
        missing_files, scores = ReferenceTests.compare(joinpath.(recorded, readdir(recorded)), ref_images)
        @testset "$name" for (name, score) in scores
            @test score < difference
        end
        return recorded, ref_images, scores
    end
end

function record_tests(db=load_database(); recording_dir=basedir("recorded"))
    recorded_files = String[]
    @testset "Record tests" begin
        rm(recording_dir, recursive=true, force=true)
        mkdir(recording_dir)
        Makie.inline!(true)
        no_backend = Makie.current_backend[] === missing
        for (source_location, entry) in db
            try
                Makie.set_theme!(resolution=(500, 500))
                # we currently can't record anything without a backend!
                if no_backend && ((:Record in entry.used_functions) || (:Stepper in entry.used_functions))
                    continue
                end
                RNG.seed_rng!()
                result = Base.invokelatest(entry.func)
                # only save if we have a backend for saving
                uname = unique_name(entry)
                if !no_backend
                    save_result(joinpath(recording_dir, uname), result)
                end
                push!(recorded_files, uname)
                @info("Tested: $(nice_title(entry))")
                @test true
            catch e
                @info("Test: $(nice_title(entry)) didn't pass")
                @test false
                Base.showerror(stderr, e)
                Base.show_backtrace(stderr, Base.catch_backtrace())
            end
        end
    end
    return recorded_files, recording_dir
end

function run_tests(db=load_database(); ref_images = ReferenceTests.download_refimages(),
                    recording_dir=joinpath(@__DIR__, "..", "recorded"), difference=0.03)
    files, dir = record_tests(db, recording_dir=recording_dir)
    reference_tests(recording_dir, ref_images=ref_images, difference=difference)
end
