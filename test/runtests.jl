using ImageFiltering, Base.Test
using Images, BinaryProvider
include("../examples/library.jl")

record_reference_images = false
version = v"0.0.3"

download_dir = joinpath(@__DIR__, "testimages")
tarfile = joinpath(download_dir, "images.zip")
url = "https://github.com/SimonDanisch/ReferenceImages/archive/v$(version).tar.gz"
refpath = joinpath(download_dir, "ReferenceImages-$(version)")
recordpath = Pkg.dir("ReferenceImages")

function url2hash(url::String)
    path = download(url)
    open(io-> bytes2hex(BinaryProvider.sha256(io)), path)
end
# url2hash(url) |> println


if !record_reference_images
    if !isdir(refpath)
        download_images() = BinaryProvider.download_verify(
            url, "56ed2f26aa5fc6046eaf42a759d27334d7f23993d9403bcd2c5090ac9b9c2f15",
            tarfile
        )
        try
            download_images()
        catch e
            if isa(e, ErrorException) && contains(e.msg, "Hash Mismatch")
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
    refpath = Pkg.dir("ReferenceImages")
end


function toimages(f, example, x::Scene, record)
    image = Makie.scene2image(x)
    rpath = joinpath(refpath, "$(example.unique_name).jpg")
    if record || !isfile(rpath)
        FileIO.save(joinpath(recordpath, "$(example.unique_name).jpg"), image)
    else
        refimage = FileIO.load(joinpath(refpath, "$(example.unique_name).jpg"))
        f(image, refimage)
    end
end

function toimages(f, example, path::String, record)
    isfile(path) || error("Not a file: $path")
    filepath, ext = splitext(path)
    rpath = joinpath(refpath, basename(filepath))
    if record || !isdir(rpath)
        rpath2 = joinpath(recordpath, basename(filepath))
        isdir(rpath2) || mkpath(rpath2)
        run(`ffmpeg -loglevel quiet -i $(abspath(path)) -y $rpath2\\frames%04d.jpg`)
    else
        filepath, ext = splitext(path)
        isdir(filepath) || mkdir(filepath)
        run(`ffmpeg -loglevel quiet -i $path -vf fps=1 -y $filepath\\frames%04d.jpg`)
        for frame in readdir(filepath)
            image = FileIO.load(joinpath(filepath, frame))
            refimage = FileIO.load(joinpath(refpath, basename(filepath), frame))
            f(image, refimage)
        end
    end
end

# The version in Images.jl throws an error... whyyyyy!?
function approx_difference(
        A::AbstractArray, B::AbstractArray,
        sigma::AbstractVector{T} = ones(ndims(A)),
        eps::AbstractFloat = 1e-2
    ) where T<:Real

    if length(sigma) != ndims(A)
        error("Invalid sigma in test_approx_eq_sigma_eps. Should be ndims(A)-length vector of the number of pixels to blur.  Got: $sigma")
    end
    kern = KernelFactors.IIRGaussian(sigma)
    Af = imfilter(A, kern, NA())
    Bf = imfilter(B, kern, NA())
    diffscale = max(Images.maxabsfinite(A), Images.maxabsfinite(B))
    d = Images.sad(Af, Bf)
    return d / (length(Af) * diffscale)
end

function test_examples(record, tags...)
    srand(42)
    @testset "Visual Regression" begin
        eval_examples(tags..., replace_nframes = true, outputfile = (entry, ending)-> "./media/" * string(entry.unique_name, ending)) do example, value
            sigma = [1,1]; eps = 0.02
            maxdiff = 0.01
            toimages(example, value, record) do image, refimage
                @testset "$(example.title):" begin
                    diff = approx_difference(image, refimage, sigma, eps)
                    if diff >= maxdiff
                        save(Pkg.dir("Makie", "test", "testresults", "$(example.unique_name)_differ.jpg"), hcat(image, refimage))
                    end
                    @test diff < maxdiff
                end
            end
            # reset global states
            srand(42)
            AbstractPlotting.set_theme!(resolution = (500, 500))
        end
    end
end

cd(@__DIR__)
isdir("media") || mkdir("media")
isdir("testresults") || mkdir("testresults")
AbstractPlotting.set_theme!(resolution = (500, 500))
test_examples(record_reference_images)

#
# example = example_database(:cat)[3]
# scene = eval_example(example)
# using Makie
#
# mesh(Makie.loadasset("cat.obj"))
#
# Makie.save(joinpath(@__DIR__, "test.png"), AbstractPlotting.current_scene())
# function test_examples(record = false)
#     srand(42)
#     @testset "Cairo" begin
#         eval_examples("2d", replace_nframes = true, outputfile = (entry, ending)-> "./media/" * string(entry.unique_name, ending)) do example, value
#             sigma = [1,1]; eps = 0.02
#             toimages(example, value, record) do image, refimage
#                 @testset "$(example.title):" begin
#                     diff = approx_difference(image, refimage, sigma, eps)
#                     if diff >= 0.07
#                         save(Pkg.dir("Makie", "test", "testresults", "$(example.unique_name)_differ.jpg"), hcat(image, refimage))
#                     end
#                     @test diff < 0.07
#                 end
#             end
#         end
#     end
# end

# cairo_unsupported = (:surface, :volume, :heatmap)
#
# eval_examples("2d", replace_nframes = true, outputfile = (entry, ending)-> "./media/" * string(entry.unique_name, ending)) do example, value
#     if example.tags
#     sigma = [1,1]; eps = 0.02
#     toimages(example, value, record) do image, refimage
#         @testset "$(example.title):" begin
#             diff = approx_difference(image, refimage, sigma, eps)
#             if diff >= 0.07
#                 save(Pkg.dir("Makie", "test", "testresults", "$(example.unique_name)_differ.jpg"), hcat(image, refimage))
#             end
#             @test diff < 0.07
#         end
#     end
# end
