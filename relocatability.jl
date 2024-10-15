
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
tmpdir = mktempdir()
# create a temporary project
cd(tmpdir)
Pkg.generate("MakieApp")
Pkg.activate("MakieApp")

makie_dir = @__DIR__
commit = cd(makie_dir) do
    chomp(read(`git rev-parse --verify HEAD`, String))
end

# Add packages from branch, to make it easier to move the code later (e.g. when running this locally)
# Since, package dir is much easier to move then the active project (on windows at least).
paths = ["MakieCore", "Makie", "GLMakie"]
Pkg.add(map(x -> (; name=x, rev=commit), paths))

open("MakieApp/src/MakieApp.jl", "w") do io
    print(io, module_src)
end

Pkg.activate(".")
Pkg.add("PackageCompiler")

using PackageCompiler

create_app(joinpath(pwd(), "MakieApp"), "executable"; force=true, incremental=true, include_transitive_dependencies=false)
exe = joinpath(pwd(), "executable", "bin", "MakieApp")
# `run` allows to see potential informative printouts, `success` swallows those
p = run(`$(exe)`)
@test p.exitcode == 0
julia_pkg_dir = joinpath(Base.DEPOT_PATH[1], "packages")
@test isdir(julia_pkg_dir)
mvd_julia_pkg_dir = julia_pkg_dir * ".old"
mv(julia_pkg_dir, mvd_julia_pkg_dir, force = true)
# Move package dir so that we can test relocatability (hardcoded paths to package dir being invalid now)
try
    p2 = run(`$(exe)`)
    @test p2.exitcode == 0
finally
    mv(mvd_julia_pkg_dir, julia_pkg_dir)
end
