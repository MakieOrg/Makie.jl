using PackageCompiler

mode = get(ENV, "MAKIE_COMPILE", "")
if isempty(mode) # don't do anything
elseif mode == "force"
    PackageCompiler.compile_package(joinpath(@__DIR__, ".."), true)
elseif mode == "build"
    PackageCompiler.compile_package(joinpath(@__DIR__, ".."), false)
end
