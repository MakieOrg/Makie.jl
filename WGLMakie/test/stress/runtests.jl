# WGLMakie browser stress suite.
#
# Drives WGLMakie through a headless Electron window (ElectronCall) the way users
# hit it: many figures and glyph sets arriving at once, figures swapped through
# observables, one figure on several pages, reloads and reconnects, offline
# exports, and notebook frontends (Pluto, JupyterLab with IJulia, BonitoBook)
# with cells deleted and re-run. Every page's console warnings and errors fail
# the scenario that produced them. Screenshots land in `results/` for a look.
#
# Run from this folder's project (instantiate it once):
#
#     julia --project=WGLMakie/test/stress WGLMakie/test/stress/runtests.jl
#
# or pass file names to run a subset: `... runtests.jl glyph_edges pluto`.
#
# Not part of CI: it needs a display (X11 or XWayland), Jupyter on the PATH for
# the IJulia file, and a few minutes per notebook frontend. Makie's texture atlas
# is fixed-size per process (about 800 glyphs); the scenarios share a budget well
# below that, keep new ones frugal with distinct characters.
using Test, WGLMakie
using WGLMakie: Makie

Makie.inline!(false)
WGLMakie.activate!(px_per_unit = 1.0)

include(joinpath(@__DIR__, "helpers.jl"))

const FILES = [
    "glyph_sync",      # character sets arriving over time, two pages, updates, markers, ticks, churn
    "glyph_edges",     # listeners, rapid updates, in-flight deletes, reload, reconnect, big batch
    "observables",     # figures swapped, emptied, derived from a slider, released on removal
    "offline_export",  # export_static and the Page(exportable, offline) sequence
    "bonitobook",      # book cells run, deleted, re-run, added
    "pluto",           # notebook cells shown, deleted through the page, re-run, added
    "ijulia",          # JupyterLab notebook with the IJulia kernel
]

selected = isempty(ARGS) ? FILES : filter(f -> any(a -> occursin(a, f), ARGS), FILES)
isempty(selected) && error("no scenario matches $(ARGS); known: $(join(FILES, ", "))")

@testset "WGLMakie stress" begin
    for file in selected
        @testset "$(file)" begin
            include(joinpath(@__DIR__, "$(file).jl"))
        end
    end
end
