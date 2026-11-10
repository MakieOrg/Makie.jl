using PrecompileTools

macro compile(block)
    return quote
        # Run the workload inside a `let` body, to avoid storing
        # f, ax, pl as module level globals that get stored in package images
        let
            figlike = $(esc(block))
            Makie.colorbuffer(figlike)
        end
    end
end

"""
    CairoMakie.precompile_plot(figlike)
    CairoMakie.precompile_plot(f, figlike)

Render `figlike`, so that rendering such plots gets compiled. Meant to be called inside a
package's precompile workload, e.g. in a package extension for CairoMakie:

```julia
using PrecompileTools, CairoMakie

@compile_workload begin
    CairoMakie.precompile_plot(my_plot_function(data))
end
```

With `f`, `f()` is called after the first render and the figure is rendered again afterwards, to
also compile the updates `f` causes, e.g. changing attributes. CairoMakie can't pick, so hovers
(e.g. for `DataInspector`) don't do anything.
"""
precompile_plot(figlike) = precompile_plot(Returns(nothing), figlike)

function precompile_plot(f, figlike)
    Makie.colorbuffer(figlike; backend = CairoMakie)
    f()
    Makie.colorbuffer(figlike; backend = CairoMakie)
    # don't leave tasks or caches behind in the package image
    PrecompileTools.is_generating_output() && Makie.cleanup_globals()
    return
end

let
    @compile_workload begin
        CairoMakie.activate!()
        foreach(include, Makie.shared_precompile_paths())
        # Cleanup globals to avoid serializing stale state (fonts, figures, tasks)
        # Note: __init__ doesn't run during precompilation, so we must always clean up here
        Makie.cleanup_globals()
    end
end
precompile(openurl, (String,))
precompile(
    draw_atomic_scatter, (
        Scene, Cairo.CairoContext, Tuple{typeof(identity), typeof(identity)},
        Vector{ColorTypes.RGBA{Float32}}, Vec{2, Float32}, ColorTypes.RGBA{Float32},
        Float32, BezierPath, Vec{3, Float32}, Quaternionf,
        Mat4f, Vector{Point{2, Float32}},
        Mat4f, Makie.FreeTypeAbstraction.FTFont, Symbol,
        Symbol, Vector{Plane3f}, Bool,
    )
)
