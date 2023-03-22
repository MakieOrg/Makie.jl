using SnoopPrecompile

let
    @precompile_all_calls begin
        base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
        shared_precompile = joinpath(base_path, "shared-precompile.jl")

        logo = Makie.logo()
        cheatsheet_3d(randn(10), logo)
        cheatsheet_2d(logo)

        empty!(FONT_CACHE)
        empty!(_default_font)
        empty!(_alternative_fonts)
        Makie._current_figure[] = nothing
    end
    nothing
end

for T in (DragPan, RectangleZoom, LimitReset)
    precompile(process_interaction, (T, MouseEvent, Axis))
end
precompile(process_axis_event, (Axis, MouseEvent))
