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
        # `display` returns once the page is up; the plot initializes afterwards and
        # reports failures (e.g. files missing after relocation) through its screen.
        screen = WGLMakie.Makie.getscreen(WGLMakie.Makie.get_scene(fig), WGLMakie)
        WGLMakie.get_screen_session(screen; error = "Plot did not initialize")
        return screen
    end
else
    _display(fig) = display(fig)
end

function julia_main()::Cint
    _display(scatter(1:4))
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
    # Electron 6 passes `--no-sandbox` itself. Bonito 5 only disables the sandbox through
    # ElectronCall's SecurityConfig, and without the flag Chromium aborts on GitHub's
    # runners (no SUID helper), leaving the app waiting for Electron forever.
    # The registered ElectronCall cannot be relocated yet (it resolves main.js through
    # the package directory); move to it once a release carries the `@path` fix.
    pkg"add Electron@6.1"
end

open("MakieApp/src/MakieApp.jl", "w") do io
    print(io, module_src)
end

Pkg.activate(".")
Pkg.add("PackageCompiler")

using PackageCompiler

create_app(joinpath(pwd(), "MakieApp"), "executable"; force = true, incremental = true, include_transitive_dependencies = false)
exe = joinpath(pwd(), "executable", "bin", "MakieApp")

# Keep the app's output visible, and bound the run: a dead Electron (e.g. a sandbox
# abort) would otherwise leave it waiting forever.
function run_app(exe; timeout = 600)
    # `wait = false` swallows the child's stdio unless it is redirected explicitly.
    p = run(pipeline(`$(exe)`; stdout = stdout, stderr = stderr); wait = false)
    timer = Timer(timeout) do _
        @error "MakieApp did not exit within $(timeout)s, killing it"
        kill(p)
    end
    wait(p)
    close(timer)
    return p
end

p = run_app(exe)
@test success(p)

julia_pkg_dir = joinpath(Base.DEPOT_PATH[1], "packages")
@test isdir(julia_pkg_dir)
mvd_julia_pkg_dir = julia_pkg_dir * ".old"
new_makie_dir = makie_dir * ".old"
mv(julia_pkg_dir, mvd_julia_pkg_dir; force = true)
mv(makie_dir, new_makie_dir; force = true)
# Move package dir so that we can test relocatability (hardcoded paths to package dir being invalid now)
try
    @info "Running executable in relocated mode..."
    p2 = run_app(exe)
    @test success(p2)
finally
    mv(mvd_julia_pkg_dir, julia_pkg_dir)
    mv(new_makie_dir, makie_dir)
end
