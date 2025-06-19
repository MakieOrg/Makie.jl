using PrecompileTools

macro compile(block)
    return quote
        let
            figlike = $(esc(block))
            Makie.colorbuffer(figlike; px_per_unit = 1)
            Makie.second_resolve(figlike, :gl_renderobject)
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
                display(plot(x); visible = false)
            catch
            end
            Makie.CURRENT_FIGURE[] = nothing

            screen = Screen(Scene())
            refresh_func = refreshwindowcb(screen)
            refresh_func(to_native(screen))
            close(screen)
            screen = empty_screen(false)
            close(screen)
            destroy!(screen)
            screen = empty_screen(false, false, nothing)
            destroy!(screen)
            config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}())
            screen = Screen(Scene(), config, nothing, MIME"image/png"(); visible = false, start_renderloop = false)
            close(screen)


            config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}())
            screen = Screen(Scene(), config; visible = false, start_renderloop = false)
            close(screen)

            closeall(; empty_shader = false)
            @assert isempty(SCREEN_REUSE_POOL)
            @assert isempty(ALL_SCREENS)
            @assert isempty(SINGLETON_SCREEN)
        end
    end
    nothing
end

precompile(Screen, (Scene, ScreenConfig))
precompile(GLFramebuffer, (NTuple{2, Int},))
precompile(glTexImage, (GLenum, Int, GLenum, Int, Int, Int, GLenum, GLenum, Ptr{Float32}))
precompile(glTexImage, (GLenum, Int, GLenum, Int, Int, Int, GLenum, GLenum, Ptr{RGBAf}))
precompile(glTexImage, (GLenum, Int, GLenum, Int, Int, Int, GLenum, GLenum, Ptr{RGBf}))
precompile(glTexImage, (GLenum, Int, GLenum, Int, Int, Int, GLenum, GLenum, Ptr{RGBA{N0f8}}))
precompile(
    glTexImage,
    (GLenum, Int, GLenum, Int, Int, Int, GLenum, GLenum, Ptr{GLAbstraction.DepthStencil_24_8})
)
precompile(glTexImage, (GLenum, Int, GLenum, Int, Int, Int, GLenum, GLenum, Ptr{Vec{2, GLuint}}))
precompile(glTexImage, (GLenum, Int, GLenum, Int, Int, Int, GLenum, GLenum, Ptr{RGBA{Float16}}))
precompile(glTexImage, (GLenum, Int, GLenum, Int, Int, Int, GLenum, GLenum, Ptr{N0f8}))
precompile(setindex!, (GLMakie.GLAbstraction.Texture{Float16, 2}, Matrix{Float32}, Rect2{Int32}))
precompile(getindex, (Makie.Text{Tuple{Vector{Point{2, Float32}}}}, Symbol))
precompile(getproperty, (Makie.Text{Tuple{Vector{Point{2, Float32}}}}, Symbol))
precompile(plot!, (Makie.Text{Tuple{Vector{Point{2, Float32}}}},))
precompile(Base.getindex, (Attributes, Symbol))
