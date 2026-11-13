# Glyph synchronization under load: text with many character sets arriving over
# time, one figure on two pages, text that changes after display, char markers,
# tick labels on zoom, and insert/delete churn. Each page's console must stay
# clean; the screenshots show whether every glyph arrived (a missing glyph draws
# nothing or a box).
using Test, Bonito, WGLMakie
using WGLMakie: Makie
isdefined(@__MODULE__, :StressKit) || include(joinpath(@__DIR__, "helpers.jl"))

# Character sets the default font covers; every entry brings glyphs no other has.
const ALPHABETS = [
    "digits 0123456789", "latin The quick brown fox", "greek αβγδεζηθ ΩΨΦ",
    "cyrillic Привет мир", "math ∑∫∂∇ ≤≥≠ ∞√", "accents àéîõü ÅÆØ ß",
    "arrows ←↑→↓ ↔", "currency €£¥", "scripts x₁x₂ y² z³",
    "punct !?;:,.«»“”", "upper ABCDEFGHIJKLM", "mixed Ωmega-3 ≈ 0.5%",
]

function text_figure(i, label)
    fig = Figure(size = (320, 200), fontsize = 13)
    ax = Axis(fig[1, 1]; title = label, xlabel = "x $(i)", ylabel = "y $(i)")
    lines!(ax, 1:10, (1:10) .* i)
    text!(ax, 1.5, 8i; text = label, align = (:left, :center), fontsize = 15)
    return fig
end

@testset "staggered text arrival" begin
    slots = [Observable{Any}(DOM.div()) for _ in ALPHABETS]
    app = App(() -> DOM.div(slots...; style = "display:grid; grid-template-columns: repeat(3, 330px); gap: 4px"))
    with_page(app; name = "glyphs-staggered", width = 1020, height = 860) do page
        @test wait_js(page, "typeof Bonito !== 'undefined'")
        figs = Figure[]
        for (i, label) in enumerate(ALPHABETS)
            fig = text_figure(i, label)
            push!(figs, fig)
            slots[i][] = fig
            sleep(0.1)
        end
        @test wait_canvases(page, length(ALPHABETS))
        screens = [wait_initialized(fig) for fig in figs]
        @test canvases_alive(page)
        shot(page, "all")
        images = [Makie.colorbuffer(screen) for screen in screens]
        @test all(img -> length(unique(img)) > 50, images)
        # Different labels draw different pixels.
        @test all(ndiff(images[i], images[i + 1]) > 100 for i in 1:(length(images) - 1))
    end
end

@testset "one figure on two pages" begin
    fig = text_figure(1, "shared αβγ 123")
    app = App(() -> DOM.div(fig))
    with_page(app; name = "glyphs-two-pages", width = 400, height = 260) do page
        @test wait_canvases(page, 1)
        first_screen = wait_initialized(fig)
        tab = open_tab(page; width = 400, height = 260)
        try
            @test wait_canvases(tab, 1)
            second_screen = wait_initialized(fig)
            @test first_screen !== second_screen
            # Glyphs added after both pages are up must reach both pages.
            ax = fig.content[1]
            text!(ax, 5.5, 3; text = "later: Ω∑ 42 ←", fontsize = 17, align = (:center, :center))
            a = Makie.colorbuffer(first_screen)
            b = Makie.colorbuffer(second_screen)
            @test ndiff(a, b) < 50
            shot(page, "first")
            shot(tab, "second")
        finally
            finish!(tab; close_server = false)
        end
    end
end

@testset "text changes after display" begin
    str = Observable("start")
    fig = Figure(size = (420, 200))
    ax = Axis(fig[1, 1])
    text!(ax, 0.5, 0.5; text = str, align = (:center, :center), fontsize = 24, space = :relative)
    with_page(App(() -> DOM.div(fig)); name = "glyphs-updates", width = 440, height = 220) do page
        @test wait_canvases(page, 1)
        screen = wait_initialized(fig)
        before = Makie.colorbuffer(screen)
        words = ["Ωmega ∑ 1", "Привет 22", "√2 ≈ 1.414", "αβγδ ← → ↑", "€ 9.99 £ 10", "final: done!"]
        for w in words
            str[] = w
        end
        after = Makie.colorbuffer(screen)
        @test ndiff(before, after) > 100
        shot(page, "final")
    end
end

@testset "char markers" begin
    marker = Observable('α')
    fig = Figure(size = (400, 300))
    ax = Axis(fig[1, 1])
    scatter!(ax, 1:10, 1:10; marker, markersize = 30)
    with_page(App(() -> DOM.div(fig)); name = "glyphs-markers", width = 420, height = 320) do page
        @test wait_canvases(page, 1)
        screen = wait_initialized(fig)
        images = [Makie.colorbuffer(screen)]
        for m in ['β', 'Ж', '∑', '€', '7']
            marker[] = m
            push!(images, Makie.colorbuffer(screen))
        end
        @test all(ndiff(images[i], images[i + 1]) > 50 for i in 1:(length(images) - 1))
        shot(page, "final")
    end
end

@testset "tick labels on zoom" begin
    fig = Figure(size = (500, 300))
    ax = Axis(fig[1, 1])
    lines!(ax, 0 .. 10, sin)
    with_page(App(() -> DOM.div(fig)); name = "glyphs-ticks", width = 520, height = 320) do page
        @test wait_canvases(page, 1)
        screen = wait_initialized(fig)
        images = [Makie.colorbuffer(screen)]
        for lims in [(0.001, 0.002, -1.0e-3, 1.0e-3), (-1.0e6, 1.0e6, -5, 5), (1.0e-9, 2.0e-9, 0, 1)]
            limits!(ax, lims...)
            push!(images, Makie.colorbuffer(screen))
        end
        shot(page, "scientific")
        limits!(ax, 0, 10, -1, 1)
        push!(images, Makie.colorbuffer(screen))
        @test all(ndiff(images[i], images[i + 1]) > 50 for i in 1:(length(images) - 1))
        shot(page, "restored")
    end
end

@testset "insert and delete churn" begin
    fig = Figure(size = (500, 300))
    ax = Axis(fig[1, 1])
    lines!(ax, 1:10)
    with_page(App(() -> DOM.div(fig)); name = "glyphs-churn", width = 520, height = 320) do page
        @test wait_canvases(page, 1)
        screen = wait_initialized(fig)
        base = Makie.colorbuffer(screen)
        for i in 1:40
            t = text!(ax, 5, 5; text = "churn $(i) Ω$(i)", fontsize = 20, align = (:center, :center))
            if i % 10 == 0
                @test ndiff(Makie.colorbuffer(screen), base) > 50
            end
            delete!(ax, t)
        end
        @test ndiff(Makie.colorbuffer(screen), base) < 50
        text!(ax, 5, 5; text = "churn survived", fontsize = 20, align = (:center, :center))
        @test ndiff(Makie.colorbuffer(screen), base) > 50
        shot(page, "final")
    end
end
