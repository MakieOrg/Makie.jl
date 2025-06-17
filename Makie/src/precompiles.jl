using PrecompileTools

macro compile(block)
    return quote
        let
            $(esc(block))
            return nothing
        end
    end
end

precompile(Makie.initialize_block!, (Axis,))
precompile(
    Makie.apply_alignment_and_justification!, (
        Vector{Vector{Makie.GlyphInfo}}, Automatic,
        Tuple{Symbol, Symbol},
    )
)

precompile(convert_arguments, (Type{Scatter}, UnitRange{Int64}))
precompile(Makie.assemble_colors, (UnitRange{Int64}, Any, Any))
let
    @compile_workload begin
        icon()
        logo()
        f = Figure()
        ax = Axis(f[1, 1])
        Makie.initialize_block!(ax)
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
        empty!(FONT_CACHE)
        empty!(DEFAULT_FONT)
        empty!(ALTERNATIVE_FONTS)
        Makie.CURRENT_FIGURE[] = nothing
    end
    nothing
end

for T in (DragPan, RectangleZoom, LimitReset)
    precompile(process_interaction, (T, MouseEvent, Axis))
end
precompile(process_axis_event, (Axis, MouseEvent))
precompile(process_interaction, (ScrollZoom, ScrollEvent, Axis))
precompile(el32convert, (Vector{Int64},))
precompile(translate, (MoveTo, Vec2{Float64}))
precompile(scale, (MoveTo, Vec{2, Float32}))
precompile(append!, (Vector{FreeType.FT_Vector_}, Vector{FreeType.FT_Vector_}))
precompile(convert_command, (MoveTo,))
precompile(plot!, (Text{Tuple{Vector{Point{2, Float32}}}},))
precompile(Vec2{Float64}, (Tuple{Int64, Int64},))
precompile(_create_plot, (typeof(scatter), Dict{Symbol, Any}, UnitRange{Int64}))
precompile(BezierPath, (String,))
precompile(BezierPath, (String, Bool, Nothing, Bool, Bool, Bool))
