using Test
using BinaryProvider, FileIO, Random, Pkg
include("../examples/library.jl")

record_reference_images = get(ENV, "RECORD_EXAMPLES", false) == "true"
version = v"0.0.7"

download_dir = joinpath(@__DIR__, "testimages")
tarfile = joinpath(download_dir, "images.zip")
url = "https://github.com/SimonDanisch/ReferenceImages/archive/v$(version).tar.gz"
refpath = joinpath(download_dir, "ReferenceImages-$(version)", "images")
recordpath = joinpath(homedir(), "ReferenceImages", "images")
if record_reference_images
    cd(homedir()) do
        isdir(dirname(recordpath)) || run(`git clone git@github.com:SimonDanisch/ReferenceImages.git`)
        isdir(recordpath) && rm(recordpath, recursive = true, force = true)
        mkdir(recordpath)
    end
end


# function url2hash(url::String)
#     path = download(url)
#     open(io-> bytes2hex(BinaryProvider.sha256(io)), path)
# end
# url2hash(url) |> println


if !record_reference_images
    if get(ENV, "USE_REFERENCE_IMAGES", "false") == "true"
        @info("Using Local reference image repository")
        refpath = recordpath
    elseif !isdir(refpath)
        download_images() = BinaryProvider.download_verify(
            url, "dabc4c35eb82a801708596964dc35c0acf1879b487a35b73322f094f611f19c3",
            tarfile
        )
        try
            download_images()
        catch e
            if isa(e, ErrorException) && occursin("Hash Mismatch", e.msg)
                rm(tarfile, force = true)
                download_images()
            else
                rethrow(e)
            end
        end
        BinaryProvider.unpack(tarfile, download_dir)
        # check again after download
        if !isdir(refpath)
            error("Something went wrong while downloading reference images. Plots can't be compared to references")
        end
    end
else
    refpath = recordpath
end

function toimages(f, example, x::Scene, record)
    image = Makie.GLMakie.scene2image(x)
    rpath = joinpath(refpath, "$(example.unique_name).jpg")
    if record
        FileIO.save(joinpath(recordpath, "$(example.unique_name).jpg"), image)
    else
        path = joinpath(refpath, "$(example.unique_name).jpg")
        if isfile(path)
            refimage = FileIO.load(path)
            f(image, refimage)
        else
            @warn("No reference image for $(example.unique_name) - skipping test")
            FileIO.save(joinpath(test_diff_path, "no_reference_$(basename(path))"), image)
        end
    end
end

is_image_file(path) = lowercase(splitext(path)[2]) in (".png", ".jpg", ".jpeg")



function toimages(f, example, events::RecordEvents, r)
    # the path is fixed at record time to be stored relative to the example
    epath = event_path(example, "")
    isfile(epath) || error("Can't find events for example. Please run `record_example_events()`")
    # the current path of RecordEvents is where we now actually want to store the video
    video_path = events.path * ".mp4"
    record(events.scene, video_path) do io
        replay_events(events.scene, epath) do
            recordframe!(io)
        end
    end
    toimages(f, example, video_path, r)
end


function toimages(f, example, s::Stepper, record)
    ispath(s.folder) || error("Not a path: $(s.folder)")
    if record
        # just copy the stepper files from s.folder into the recordpath
        rpath2 = joinpath(recordpath, basename(s.folder))
        cp(s.folder, rpath2, force = true)
    else
        for frame in readdir(s.folder)
            is_image_file(frame) || continue
            path = joinpath(s.folder, frame)
            pathref = joinpath(refpath, basename(s.folder), frame)
            if isfile(pathref)
                image = FileIO.load(path)
                refimage = FileIO.load(pathref)
                f(image, refimage)
            else
                @warn("No reference frames for $(example.unique_name) found - skipping tests")
                cp(path, joinpath(test_diff_path, "no_reference_$(basename(path))"), force = true)
                break
            end
        end
    end
end

function toimages(f, example, path::String, record)
    isfile(path) || error("Not a file: $path")
    filepath, ext = splitext(path)
    rpath = joinpath(refpath, basename(filepath))

    if record
        rpath2 = joinpath(recordpath, basename(filepath))
        isdir(rpath2) || mkpath(rpath2)
        run(`ffmpeg -loglevel quiet -i $(abspath(path)) -y $rpath2\\frames%04d.jpg`)
    else
        filepath, ext = splitext(path)
        isdir(filepath) || mkdir(filepath)
        run(`ffmpeg -loglevel quiet -i $path -y $filepath\\frames%04d.jpg`)
        for frame in readdir(filepath)
            pathref = joinpath(refpath, basename(filepath), frame)
            if isfile(pathref)
                image = FileIO.load(joinpath(filepath, frame))
                refimage = FileIO.load(pathref)
                f(image, refimage)
            else
                @warn("No reference frames for $(example.unique_name) found - skipping tests")
                cp(joinpath(filepath, frame), joinpath(test_diff_path, "no_reference_$(frame)"), force = true)
                break
            end
        end
    end
end

include("visualregression.jl")


test_diff_path = joinpath(dirname(pathof(Makie)), "..", "test", "testresults")

rm(test_diff_path, force = true, recursive = true)
mkpath(test_diff_path)

function test_examples(record, tags...; kw_args...)
    Random.seed!(42)
    @testset "Visual Regression" begin
        eval_examples(tags..., replace_nframes = false, outputfile = (entry, ending)-> "./media/" * string(entry.unique_name, ending); kw_args...) do example, value
            sigma = [1,1]; eps = 0.02
            maxdiff = 0.05
            toimages(example, value, record) do image, refimage
                @testset "$(example.title):" begin
                    diff = approx_difference(image, refimage, sigma, eps)
                    if diff >= maxdiff
                        save(
                            joinpath(test_diff_path, "$(example.unique_name)_differ.jpg"),
                            hcat(image, refimage)
                        )
                    end
                    @test diff < maxdiff
                end
            end
            # reset global states
            Random.seed!(42)
            AbstractPlotting.set_theme!(resolution = (500, 500))
        end
    end
end

cd(@__DIR__)
isdir("media") || mkdir("media")
isdir("testresults") || mkdir("testresults")
AbstractPlotting.set_theme!(resolution = (500, 500))

@info("Number of examples in database: $(length(database))")

exclude_tags = ["bigdata"]
@info("Excluding tags: $exclude_tags")

indices_excluded = []
for tag in exclude_tags
    global indices_excluded
    indices = find_indices(tag)
    indices_excluded = vcat(indices_excluded, indices)
end
num_excluded = length(unique(indices_excluded))
@info("Number of examples to be skipped: $(num_excluded)")

# run the tests
test_examples(record_reference_images; exclude_tags = exclude_tags)
