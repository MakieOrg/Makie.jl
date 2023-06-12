using PrecompileTools

macro compile(block)
    return quote
        let
            figlike = $(esc(block))
            Makie.colorbuffer(figlike)
            return nothing
        end
    end
end

let
    @setup_workload begin
        x = rand(5)
        @compile_workload begin
            GLMakie.activate!()
            screen = GLMakie.singleton_screen(false)
            close(screen)
            destroy!(screen)
            base_path = normpath(joinpath(dirname(pathof(Makie)), "..", "precompile"))
            shared_precompile = joinpath(base_path, "shared-precompile.jl")
            include(shared_precompile)
            try
                display(plot(x); visible=false)
            catch
            end
            Makie.CURRENT_FIGURE[] = nothing
            empty!(atlas_texture_cache)
            closeall()
            @assert isempty(SCREEN_REUSE_POOL)
            @assert isempty(ALL_SCREENS)
            @assert isempty(SINGLETON_SCREEN)
        end
    end
    nothing
end
