using SnoopPrecompile

let
    @precompile_setup begin
        x = rand(5)
        @precompile_all_calls begin
            GLMakie.activate!()
            screen = GLMakie.singleton_screen(false)
            close(screen)
            destroy!(screen)

            logo = Makie.logo()
            fig = Makie.cheatsheet_3d(randn(10), logo)
            Makie.colorbuffer(fig)
            fig = Makie.cheatsheet_2d(logo)
            Makie.colorbuffer(fig)

            try
                display(plot(x); visible=false)
            catch
            end
            Makie._current_figure[] = nothing
            empty!(atlas_texture_cache)
            closeall()
            @assert isempty(SCREEN_REUSE_POOL)
            @assert isempty(ALL_SCREENS)
            @assert isempty(SINGLETON_SCREEN)
        end
    end
    nothing
end
