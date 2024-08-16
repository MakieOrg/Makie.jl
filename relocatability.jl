
module_src = """
module MakieApp

using GLMakie

function julia_main()::Cint
    screen = display(scatter(1:4))
    # wait(screen) commented out to test if this blocks anything, but didn't change anything
    return 0 # if things finished successfully
end

end # module MakieApp
"""

using Pkg, Test
makie_dir = pwd()
tmpdir = mktempdir()
# create a temporary project
cd(tmpdir)
Pkg.generate("MakieApp")
Pkg.activate("MakieApp")


paths = [makie_dir, joinpath(makie_dir, "MakieCore"), joinpath(makie_dir, "GLMakie")]

Pkg.develop(map(x-> (;path=x), paths))

open("MakieApp/src/MakieApp.jl", "w") do io
    print(io, module_src)
end

Pkg.activate(".")
Pkg.add("PackageCompiler")

using PackageCompiler

create_app(joinpath(pwd(), "MakieApp"), "executable"; force=true, incremental=true, include_transitive_dependencies=false)
exe = joinpath(pwd(), "executable", "bin", "MakieApp")
@test success(`$(exe)`)
julia_pkg_dir = joinpath(Base.DEPOT_PATH[1], "packages")
@test isdir(julia_pkg_dir)
mvd_julia_pkg_dir = julia_pkg_dir * ".old"
# Move package dir so that we can test relocatability (hardcoded paths to package dir being invalid now)
try
    mv(julia_pkg_dir, mvd_julia_pkg_dir)
    @test success(`$(exe)`)
catch e
    mv(mvd_julia_pkg_dir, julia_pkg_dir)
end
