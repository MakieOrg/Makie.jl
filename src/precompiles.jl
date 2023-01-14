using SnoopPrecompile

macro compile(block)
    return quote
        let
            $(esc(block))
        end
    end
end

let
    @precompile_all_calls begin
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")
        include(shared_precompile)
        empty!(FONT_CACHE)
        empty!(_default_font)
        empty!(_alternative_fonts)
    end
    nothing
end

for T in (DragPan, RectangleZoom, LimitReset)
    precompile(process_interaction, (T, MouseEvent, Axis))
end
precompile(process_axis_event, (Axis, MouseEvent))
