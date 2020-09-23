using AbstractPlotting: @cell, save_result
using MeshIO
using AbstractPlotting

module RNG

using StableRNGs
using Colors
using Random

const STABLE_RNG = StableRNG(123)

rand(args...) = Base.rand(STABLE_RNG, args...)
randn(args...) = Base.randn(STABLE_RNG, args...)

seed_rng!() = Random.seed!(STABLE_RNG, 123)

function Base.rand(r::StableRNGs.LehmerRNG, ::Random.SamplerType{T}) where T <: ColorAlpha
    return T(Base.rand(r), Base.rand(r), Base.rand(r), Base.rand(r))
end

function Base.rand(r::StableRNGs.LehmerRNG, ::Random.SamplerType{T}) where T <: AbstractRGB
    return T(Base.rand(r), Base.rand(r), Base.rand(r))
end

end

using .RNG

using AbstractPlotting: Record, Stepper

module MakieGallery
    using FileIO
    assetpath(files...) = normpath(joinpath(@__DIR__, "..", "..", "..", "MakieGallery", "assets", files...))
    loadasset(files...) = FileIO.load(assetpath(files...))
end
using .MakieGallery

function load_database()
    empty!(AbstractPlotting.DATABASE)
    empty!(AbstractPlotting.UNIQUE_DATABASE_NAMES)
    include("examples2d.jl")
    include("attributes.jl")
    include("documentation.jl")
    include("examples2d.jl")
    include("examples3d.jl")
    include("layouting.jl")
    include("short_tests.jl")
    return AbstractPlotting.DATABASE
end

function run_tests()
    db = load_database()
    recording_dir = joinpath(@__DIR__, "test_output")
    rm(recording_dir, recursive=true, force=true); mkdir(recording_dir)
    evaled = 1
    AbstractPlotting.inline!(true)
    for (name, func) in db
        save_result(joinpath(recording_dir, name), func())
        evaled += 1
    end
    return evaled
end

run_tests()

using ghr_jll
using Tar
using Downloads

function upload_release(user, repo, token, tag, path)
    ghr() do ghr_path
        run(`$ghr_path -delete -u $(user) -r $(repo) -t $(token) $(tag) $(path)`)
    end
end

function create_new_refimage_release(path, tag="v0.7.0")
    mktempdir() do dir
        tarfile = joinpath(dir, "refimages.tar")
        Tar.create(path, tarfile)
        upload_release("JuliaPlots", "MakieReferenceImages", ENV["GITHUB_TOKEN"], tag, tarfile)
    end
end

create_new_refimage_release(recording_dir)

url = "https://github.com/JuliaPlots/MakieReferenceImages/releases/download/v0.7.0/refimages.tar"

Downloads.download(url, joinpath(@__DIR__, "refimages.tar"))

rm(joinpath(@__DIR__, "refimages"), force=true, recursive=true)

Tar.extract(joinpath(@__DIR__, "refimages.tar"), joinpath(@__DIR__, "refimages"))

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
        return approx_difference(imga, imgb, sigma, eps)
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

missing_imgs, scores = compare(recording_dir, joinpath(@__DIR__, "refimages"))
