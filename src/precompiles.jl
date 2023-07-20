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
precompile(_get_glyphcollection_and_linesegments,
           (LaTeXStrings.LaTeXString, Int64, Float32,
            FreeTypeAbstraction.FTFont, Attributes,
            Tuple{Symbol,Symbol}, Quaternion{Float64},
            MakieCore.Automatic, Float64,
            ColorTypes.RGBA{Float32}, ColorTypes.RGBA{Float32},
            Int64, Int64, Vec{2,Float32}))

precompile(Makie.apply_alignment_and_justification!, (Vector{Vector{Makie.GlyphInfo}}, MakieCore.Automatic,
                                                    Tuple{Symbol,Symbol}))

precompile(MakieCore.convert_arguments, (Type{Scatter}, UnitRange{Int64}))
precompile(Makie.assemble_colors, (UnitRange{Int64}, Any, Any))
let
    @compile_workload begin
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
