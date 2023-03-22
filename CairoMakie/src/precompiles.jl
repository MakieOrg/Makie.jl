using SnoopPrecompile

let
    @precompile_all_calls begin
        CairoMakie.activate!()
        logo = Makie.logo()
        fig = Makie.cheatsheet_3d(randn(10), logo)
        Makie.colorbuffer(fig)
        fig = Makie.cheatsheet_2d(logo)
        Makie.colorbuffer(fig)
    end
end
