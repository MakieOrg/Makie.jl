using ImageFiltering, Base.Test
using Images

include("../examples/library.jl")

refpath = Pkg.dir("ReferenceImages", "Makie")

if !isdir(Pkg.dir("ReferenceImages"))
    Pkg.clone("https://github.com/SimonDanisch/ReferenceImages.git")
else
    Pkg.checkout("ReferenceImages")
end


isdir(refpath) || mkpath(refpath)

function toimages(f, example, x::Scene, record)
    image = Makie.scene2image(x)
    if record
        FileIO.save(joinpath(refpath, "$(example.unique_name).jpg"), image)
    else
        refimage = FileIO.load(joinpath(refpath, "$(example.unique_name).jpg"))
        f(image, refimage)
    end
end

function toimages(f, example, path::String, record)
    isfile(path) || error("Not a file: $path")
    if record
        filepath, ext = splitext(path)
        rpath = joinpath(refpath, basename(filepath))
        isdir(rpath) || mkpath(rpath)
        run(`ffmpeg -loglevel quiet -i $path -vf fps=1 -y $rpath\\frames%04d.jpg`)
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
# The version in images.jl throws an error... whyyyyy!?
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
function test_examples(record = false)
    srand(42)
    @testset "Visual Regression" begin
        eval_examples(replace_nframes = true, outputfile = (entry, ending)-> "./media/" * string(entry.unique_name, ending)) do example, value
            sigma = [1,1]; eps = 0.02
            toimages(example, value, record) do image, refimage
                @testset "$(example.title):" begin
                    diff = approx_difference(image, refimage, sigma, eps)
                    if diff >= 0.07
                        save(Pkg.dir("Makie", "test", "testresults", "$(example.unique_name)_differ.jpg"), hcat(image, refimage))
                    end
                    @test diff < 0.07
                end
            end
        end
    end
end
cd(@__DIR__)
isdir("media") || mkdir("media")
isdir("testresults") || mkdir("testresults")
AbstractPlotting.set_theme!(resolution = (500, 500))
test_examples(false)
