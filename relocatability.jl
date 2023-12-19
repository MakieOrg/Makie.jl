
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
using PackageCompiler

using Pkg
tmpdir = mktempdir()

# create a temporary project
cd(tmpdir)
rm("MakieApp", recursive=true)
Pkg.generate("MakieApp")
Pkg.activate("MakieApp")
Pkg.add([(name ="GLMakie", rev="sd/relocatability")])
open("MakieApp/src/MakieApp.jl", "w") do io
    print(io, module_src)
end
Pkg.activate(".")
Pkg.add("PackageCompiler")

using PackageCompiler
rm("executable", recursive=true)
create_app(joinpath(pwd(), "MakieApp"), "executable"; force=true, incremental=true, include_transitive_dependencies=false)

isfile(joinpath(pwd(), "MakieApp", "Project.toml"))
