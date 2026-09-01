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
    # Rendering a figure into a NoConnection session takes the offline branch
    # in three_display, which serializes the scene synchronously -- so missing
    # shader assets in a relocated install throw here instead of being logged
    # as a warning on the server task (the Electron display path defers
    # serialization until JS reports the canvas size, which this app may exit
    # before reaching). Deliberately does not render the page HTML: offline
    # asset inlining reads non-relocatable asset files, a separate issue.
    function _offline_check()
        session = WGLMakie.Bonito.Session(WGLMakie.Bonito.NoConnection())
        WGLMakie.Bonito.session_dom(session, WGLMakie.Bonito.App(scatter(1:4)))
        close(session)
        return
    end
else
    _display(fig) = display(fig)
    _offline_check() = nothing
end

function julia_main()::Cint
    screen = _display(scatter(1:4))
    _offline_check()
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
    joinpath(tmpdir, "LocalPreferences.toml"), """
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
    pkg"add Electron@5.1"
end

open("MakieApp/src/MakieApp.jl", "w") do io
    print(io, module_src)
end

Pkg.activate(".")
Pkg.add("PackageCompiler")

using PackageCompiler

create_app(joinpath(pwd(), "MakieApp"), "executable"; force = true, incremental = true, include_transitive_dependencies = false)
exe = joinpath(pwd(), "executable", "bin", "MakieApp")

# Capture output so we can assert on it: WGLMakie demotes serialization
# failures to a warning on an async task, which never affects the exit code.
function run_and_capture(cmd)
    logfile = tempname()
    p = open(logfile, "w") do io
        run(pipeline(ignorestatus(cmd); stdout = io, stderr = io))
    end
    output = read(logfile, String)
    print(output)
    return p, output
end

p, output = run_and_capture(`$(exe)`)
@test p.exitcode == 0
@test !occursin("Error resizing/serializing scene", output)

julia_pkg_dir = joinpath(Base.DEPOT_PATH[1], "packages")
@test isdir(julia_pkg_dir)
mvd_julia_pkg_dir = julia_pkg_dir * ".old"
new_makie_dir = makie_dir * ".old"
mv(julia_pkg_dir, mvd_julia_pkg_dir; force = true)
mv(makie_dir, new_makie_dir; force = true)
# Move package dir so that we can test relocatability (hardcoded paths to package dir being invalid now)
try
    @info "Running executable in relocated mode..."
    p2, output2 = run_and_capture(`$(exe)`)
    @test p2.exitcode == 0
    @test !occursin("Error resizing/serializing scene", output2)
finally
    mv(mvd_julia_pkg_dir, julia_pkg_dir)
    mv(new_makie_dir, makie_dir)
end
