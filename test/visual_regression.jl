using VisualRegressionTests, Base.Test

cd(@__DIR__)
include("visual_regression_funcs.jl")

if !isa(Pkg.installed("ReferenceImages"), VersionNumber)
    Pkg.clone("https://github.com/SimonDanisch/ReferenceImages.git")
end

refpath(i) = Pkg.dir("ReferenceImages", "reference_images", "img_$i.png")

function record(filepath, func)
    srand(1234)
    scene = func()
    @assert isa(scene, Scene)
    Makie.save(filepath, scene)
end

function record_reference()
    i = 1
    while true
        # functions in visual_regression_funcs.jl all are named after the same sceme
        func = Symbol("testfunc_$i")
        isdefined(Main, func) || break # we only have n functions in visual_regression_funcs
        func_inst = getfield(Main, func)
        record(refpath(i), func_inst)
        i += 1
    end
end
# record_reference()

@testset "Makie visual regression" begin
    i = 1
    while true
        # functions in visual_regression_funcs.jl all are named after the same sceme
        func = Symbol("testfunc_$i")
        isdefined(Main, func) || break # we only have n functions in visual_regression_funcs
        func_inst = getfield(Main, func)
        path = refpath(i)
        f(fn) = record(fn, func_inst)
        @testset "$func" begin
            @test test_images(VisualTest(f, path), popup = false) |> success
        end
        i += 1
    end
end
