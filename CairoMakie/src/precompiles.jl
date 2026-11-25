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

let
    @compile_workload begin
        CairoMakie.activate!()
        foreach(include, Makie.shared_precompile_paths())
        # The second render reuses the screen and resolves computations after layout updates.
        fig = scatter(1:4; color = 1:4, colormap = :turbo, markersize = 20, visible = true)
        Makie.colorbuffer(fig; px_per_unit = 1)
        Makie.colorbuffer(fig; px_per_unit = 1)
        mktempdir() do dir
            save(joinpath(dir, "scatter.png"), fig)
        end
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
