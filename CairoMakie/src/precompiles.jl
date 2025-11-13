using PrecompileTools

macro compile(block)
    return quote
        figlike = $(esc(block))
        Makie.colorbuffer(figlike)
    end
end

let
    @compile_workload begin
        CairoMakie.activate!()
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
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
