using PrecompileTools

macro compile(block)
    return quote
        let
            Makie.render_for_precompile(Screen, $(esc(block)))
            return nothing
        end
    end
end

function is_context_unavailable(err)
    return err isa GLFW.GLFWError && err.code in (
        GLFW.NOT_INITIALIZED, GLFW.API_UNAVAILABLE, GLFW.VERSION_UNAVAILABLE,
        GLFW.PLATFORM_ERROR, GLFW.FORMAT_UNAVAILABLE,
    )
end

"""
    GLMakie.precompile_plot(figlike)
    GLMakie.precompile_plot(f, figlike)

Render `figlike` in a hidden window, so that displaying such plots gets compiled. Meant to be
called inside a package's precompile workload, e.g. in a package extension for GLMakie:

```julia
using PrecompileTools, GLMakie

@compile_workload begin
    GLMakie.precompile_plot(my_plot_function(data))
end
```

With `f`, `f()` is called after the first frame while the window is still open, so interactions
can be precompiled by sending events. Afterwards the figure is rendered again, to also compile the
updates the interaction caused. For example a `DataInspector` hover:

```julia
fig, ax, plt = scatter(rand(10))
DataInspector(fig)
GLMakie.precompile_plot(fig) do
    events(fig).mouseposition[] = Tuple(pixel_position(plt, 1))
end
```

If no OpenGL context can be created (e.g. on a headless machine), nothing is rendered and `f` is
not called.
"""
precompile_plot(figlike) = Makie.precompile_plot(GLMakie, figlike)
precompile_plot(f, figlike) = Makie.precompile_plot(GLMakie, f, figlike)

function Makie.render_for_precompile(::Type{<:Screen}, figlike)
    try
        Makie.colorbuffer(figlike; px_per_unit = 1)
    catch err
        is_context_unavailable(err) || rethrow()
        @info "Skipping GLMakie rendering for precompilation because no usable OpenGL context is available." exception = err
        return false
    end
    Makie.second_resolve(figlike, :gl_renderobject)
    return true
end

Makie.handle_precompile_interactions(::Type{<:Screen}, figlike) = Makie.process_pending_hover!(figlike)

function Makie.cleanup_after_precompile(::Type{<:Screen})
    closeall()
    Makie.cleanup_globals()
    return
end

function precompile_screen()
    try
        return singleton_screen(false)
    catch err
        is_context_unavailable(err) || rethrow()
        @info "Skipping GLMakie's OpenGL precompile workload because no usable context is available." exception = err
        return nothing
    end
end

let
    @setup_workload begin
        x = rand(5)
        @compile_workload begin
            # NULL can render with EGL or OSMesa. Only skip the workload when
            # context creation actually fails, so imports also work without drivers.
            screen = precompile_screen()
            if !isnothing(screen)
                GLMakie.activate!(visible = false)
                close(screen)
                destroy!(screen)

                foreach(include, Makie.shared_precompile_paths())
                display(plot(x); visible = false)

                screen = Screen(Scene(); visible = false)
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
            # Cleanup globals to avoid serializing stale state (fonts, figures, tasks)
            # Note: __init__ doesn't run during precompilation, so we must always clean up here
            Makie.cleanup_globals()
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
