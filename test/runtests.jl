mode = get(ENV, "MAKIE_COMPILE", "")

function is_ci()
    get(ENV, "TRAVIS", "") == "true" ||
    get(ENV, "APPVEYOR", "") == "true" ||
    get(ENV, "CI", "") == "true"
end

if is_ci()
    Pkg.clone("https://github.com/SimonDanisch/AbstractNumbers.jl.git")
    Pkg.checkout("GLAbstraction")
    Pkg.checkout("GLVisualize")
    Pkg.checkout("MeshIO")
    Pkg.add("VisualRegressionTests")
    Pkg.checkout("GLWindow")
end

if isempty(mode)
    # we're not compiling, so we do a reference image test run
    include("visual_regression.jl")
else
    # when snoop compiling, we simply just execute all sample code directly
    parse("all_samples.jl")
end
