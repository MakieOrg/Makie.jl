mode = get(ENV, "MAKIE_COMPILE", "")

function is_ci()
    get(ENV, "TRAVIS", "") == "true" ||
    get(ENV, "APPVEYOR", "") == "true" ||
    get(ENV, "CI", "") == "true"
end

if isempty(mode)
    # we're not compiling, so we do a reference image test run
    include("visual_regression.jl")
else
    # when snoop compiling, we simply just execute all sample code directly
    include("all_samples.jl")
end
