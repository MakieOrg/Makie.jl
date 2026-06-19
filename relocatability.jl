const BACKEND = ARGS[1]
@assert BACKEND in ["CairoMakie", "GLMakie", "WGLMakie"]
module_src = """
module MakieApp

using $BACKEND

if "$BACKEND" == "WGLMakie"
    using Electron
    function _display(fig)
        disp = WGLMakie.Bonito.use_electron_display()
        display(disp, WGLMakie.Bonito.App(fig))
    end
else
    _display(fig) = display(fig)
end

function julia_main()::Cint
    screen = _display(scatter(1:4))
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

# Disable precompile workload, so that we compile less functions
# Speed up compilation and dont make the CI OOM.
# This should still precompile anything in the APP and backe that to the image.
write(
    joinpath(tmpdir, "MakieApp", "LocalPreferences.toml"), """
    [CairoMakie]
    precompile_workload = false
    [GLMakie]
    precompile_workload = false
    [Makie]
    precompile_workload = false
    [WGLMakie]
    precompile_workload = false
    """
)

makie_dir = @__DIR__

# Add packages from branch, to make it easier to move the code later (e.g. when running this locally)
# Since, package dir is much easier to move then the active project (on windows at least).
paths = ["Makie", "ComputePipeline", BACKEND]
Pkg.develop(map(x -> (; path = joinpath(makie_dir, x)), paths))

if BACKEND == "WGLMakie"
    # v5 WGLMakie needs the unreleased HTTP@2 Bonito stack + ElectronCall
    # (keep in sync with .github/workflows/_wglmakie.yml); drop the pins once
    # the registered versions catch up.
    Pkg.add([
        (; url = "https://github.com/SimonDanisch/Bonito.jl.git", rev = "sd/v5"),
        (; url = "https://github.com/JuliaWeb/HTTP.jl.git", rev = "master"),
        (; url = "https://github.com/JuliaServices/Reseau.jl.git", rev = "main"),
        (; url = "https://github.com/JuliaIO/MsgPack.jl.git", rev = "master"),
        (; url = "https://github.com/IanButterworth/ElectronCall.jl.git", rev = "main"),
    ])
end

open("MakieApp/src/MakieApp.jl", "w") do io
    print(io, module_src)
end

Pkg.activate(".")
Pkg.add("PackageCompiler")

using PackageCompiler

create_app(joinpath(pwd(), "MakieApp"), "executable"; force = true, incremental = true, include_transitive_dependencies = false)
exe = joinpath(pwd(), "executable", "bin", "MakieApp")
# `run` allows to see potential informative printouts, `success` swallows those
p = run(`$(exe)`)
@test p.exitcode == 0

julia_pkg_dir = joinpath(Base.DEPOT_PATH[1], "packages")
@test isdir(julia_pkg_dir)
mvd_julia_pkg_dir = julia_pkg_dir * ".old"
new_makie_dir = makie_dir * ".old"
mv(julia_pkg_dir, mvd_julia_pkg_dir; force = true)
mv(makie_dir, new_makie_dir; force = true)
# Move package dir so that we can test relocatability (hardcoded paths to package dir being invalid now)
try
    @info "Running executable in relocated mode..."
    p2 = run(`$(exe)`)
    @test p2.exitcode == 0
finally
    mv(mvd_julia_pkg_dir, julia_pkg_dir)
    mv(new_makie_dir, makie_dir)
end
