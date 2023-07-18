using PrecompileTools

macro compile(block)
    return quote
        let
            $(esc(block))
            return nothing
        end
    end
end

let
    @compile_workload begin
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
