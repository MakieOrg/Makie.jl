# Plots that live inside observables: a figure slot swapped many times, emptied
# and refilled, derived from a slider, swapped before initialization finished,
# and a list of figures that loses its middle element. Old screens must close,
# exactly one canvas per live figure must remain, and the console must stay clean.
using Test, Bonito, WGLMakie
using WGLMakie: Makie
isdefined(@__MODULE__, :StressKit) || include(joinpath(@__DIR__, "helpers.jl"))

function labeled_figure(i)
    fig = Figure(size = (400, 250))
    ax = Axis(fig[1, 1]; title = "figure $(i) Ω$(i)")
    scatter!(ax, 1:10, (1:10) .* (0.5 + i / 10); markersize = 12)
    text!(ax, 1, i + 1; text = "label $(i)", fontsize = 16)
    return fig
end

@testset "figure slot swapped repeatedly" begin
    slot = Observable{Any}(labeled_figure(0))
    with_page(App(() -> DOM.div(slot)); name = "obs-swap", width = 420, height = 270) do page
        @test wait_canvases(page, 1)
        wait_initialized(slot[])
        previous = Figure[]
        for i in 1:10
            push!(previous, slot[])
            slot[] = labeled_figure(i)
            wait_initialized(slot[])
            @test wait_canvases(page, 1)
            @test canvases_alive(page)
        end
        for fig in previous
            scene = Makie.get_scene(fig)
            closed = Bonito.wait_for(() -> all(s -> !isopen(s), scene.current_screens); timeout = 10)
            @test closed === :success
        end
        shot(page, "tenth")
        slot[] = DOM.div("nothing here")
        @test wait_canvases(page, 0)
        slot[] = labeled_figure(99)
        wait_initialized(slot[])
        @test wait_canvases(page, 1)
        @test canvases_alive(page)
        shot(page, "restored")
    end
end

@testset "figure derived from a slider" begin
    slider = Bonito.Slider(1:10)
    fig_obs = map(labeled_figure, slider.value)
    with_page(App(() -> DOM.div(slider, fig_obs)); name = "obs-slider", width = 420, height = 320) do page
        @test wait_canvases(page, 1)
        wait_initialized(fig_obs[])
        for v in [3, 7, 2, 10, 5]
            js(
                page, """(() => { const s = document.querySelector('input[type=range]');
                s.value = $(v); s.dispatchEvent(new Event('input', {bubbles: true})); return true; })()"""
            )
            @test Bonito.wait_for(() -> slider.value[] == v; timeout = 10) === :success
            wait_initialized(fig_obs[])
            @test wait_canvases(page, 1)
            @test canvases_alive(page)
        end
        shot(page, "final")
    end
end

@testset "swapped before initialization completes" begin
    slot = Observable{Any}(DOM.div())
    with_page(App(() -> DOM.div(slot)); name = "obs-rapid", width = 420, height = 270) do page
        @test wait_js(page, "typeof Bonito !== 'undefined'")
        figs = [labeled_figure(i) for i in 1:15]
        for fig in figs
            slot[] = fig
        end
        wait_initialized(last(figs))
        @test wait_canvases(page, 1)
        @test canvases_alive(page)
        for fig in figs[1:(end - 1)]
            scene = Makie.get_scene(fig)
            closed = Bonito.wait_for(() -> all(s -> !isopen(s), scene.current_screens); timeout = 10)
            @test closed === :success
        end
        shot(page, "final")
    end
end

@testset "list of figures loses its middle element" begin
    figs = Observable([labeled_figure(i) for i in 1:4])
    dom = map(fs -> DOM.div(fs...; style = "display:flex; flex-wrap: wrap"), figs)
    with_page(App(() -> DOM.div(dom)); name = "obs-list", width = 840, height = 560) do page
        @test wait_canvases(page, 4)
        foreach(wait_initialized, figs[])
        shot(page, "four")
        figs[] = figs[][[1, 2, 4]]
        # The remaining figures are displayed again: new screens, old ones closed.
        foreach(wait_initialized, figs[])
        foreach(wait_old_screens_closed, figs[])
        @test wait_canvases(page, 3)
        @test canvases_alive(page)
        shot(page, "three")
    end
end

# A figure removed from the page must free its WebGL context right away. Without
# that, Chromium evicts the oldest context after 16 live ones, which can be the
# figure currently on screen (a slider rebuilding a figure gets there quickly).
@testset "removed figures release their screens" begin
    slot = Observable{Any}(DOM.div())
    with_page(App(() -> DOM.div(slot)); name = "obs-release", width = 420, height = 270) do page
        @test wait_js(page, "typeof Bonito !== 'undefined'")
        for i in 1:25
            fig = labeled_figure(i)
            slot[] = fig
            wait_initialized(fig)
            @test wait_canvases(page, 1)
            # Keep a handle on the live screen, then remove the figure.
            js(page, "window.__lastScreen = document.querySelector('canvas').wglmakie_screen; true")
            slot[] = DOM.div("gone $(i)")
            @test wait_canvases(page, 0)
            # Disposal empties the screen object and drops its scenes from the cache.
            @test wait_js(page, "Object.keys(window.__lastScreen).length === 0"; timeout = 10.0)
            @test wait_js(page, "Object.keys(WGL.scene_cache).length === 0"; timeout = 10.0)
        end
        slot[] = labeled_figure(26)
        wait_initialized(slot[])
        @test canvases_alive(page)
        shot(page, "final")
    end
end
