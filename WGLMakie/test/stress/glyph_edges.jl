# The edges of the per-root glyph sync: a page-wide atlas fed by one shipped-set
# per root session, a priority listener that must ship glyphs before the update
# using them, pulls for anything the page missed, and sessions that come and go.
using Test, Bonito, WGLMakie
using WGLMakie: Makie
isdefined(@__MODULE__, :StressKit) || include(joinpath(@__DIR__, "helpers.jl"))

const FONT_NAMES = ["TeX Gyre Heros Makie", "TeX Gyre Heros Makie Bold", "TeX Gyre Heros Makie Italic", "Fira Mono Medium"]

"Printable characters a font has a glyph for, from the ranges listed."
function present_chars(font; ranges = [0x21:0x7E, 0xA1:0x024F, 0x0370:0x03FF, 0x0400:0x045F, 0x2010:0x205F, 0x2190:0x21FF, 0x2200:0x22FF, 0x2500:0x25FF])
    return [Char(c) for r in ranges for c in r if Makie.FreeTypeAbstraction.glyph_index(font, Char(c)) != 0]
end

# JS-side atlas bookkeeping must be settled: nothing waiting, nothing requested.
atlas_settled(page) = wait_js(page, "(() => { const a = WGL.get_texture_atlas(); return a.waiters.length === 0 && a.requested.size === 0; })()"; timeout = 15.0)

"Hashes every text or glyph-marker plot on the page refers to are present in the atlas."
all_plot_glyphs_present(page) = js(
    page, """(() => {
        const atlas = WGL.get_texture_atlas();
        const plots = Object.values(WGL.plot_cache).map(m => m.plot_object).filter(p => p.glyph_info?.glyph_hashes);
        return plots.length > 0 && plots.every(p => Array.from(p.glyph_info.glyph_hashes).every(h => atlas.glyph_data.has(String(h))));
    })()"""
) === true

function text_axis(size = (420, 220))
    fig = Figure(; size)
    ax = Axis(fig[1, 1])
    return fig, ax
end

@testset "the session's glyph listener is released with the session" begin
    fig, ax = text_axis()
    t = text!(ax, 0.5, 0.5; text = "listen Ω", align = (:center, :center), space = :relative, fontsize = 22)
    slot = Observable{Any}(fig)
    with_page(App(() -> DOM.div(slot)); name = "edge-listener", width = 440, height = 240) do page
        wait_initialized(fig)
        updater = t.attributes[:wgl_update_obs][]
        with_one = length(updater.listeners)
        for i in 1:25
            slot[] = DOM.div("gone $(i)")
            @test wait_canvases(page, 0)
            wait_old_screens_closed(fig)
            slot[] = fig
            wait_initialized(fig)
            @test wait_canvases(page, 1)
        end
        # Closed sessions took their listeners with them: only the live one remains.
        @test length(updater.listeners) <= with_one
        t.text = "listen Ω still works ∑"
        @test length(unique(Makie.colorbuffer(newest_screen(fig)))) > 10
        shot(page, "final")
    end
end

@testset "rapid updates with new glyphs settle" begin
    pool = present_chars(Makie.to_font(FONT_NAMES[1]))
    @test length(pool) > 200
    str = Observable("start")
    fig, ax = text_axis()
    text!(ax, 0.5, 0.5; text = str, align = (:center, :center), space = :relative, fontsize = 22)
    with_page(App(() -> DOM.div(fig)); name = "edge-rapid", width = 440, height = 240) do page
        screen = wait_initialized(fig)
        before = Makie.colorbuffer(screen)
        last_word = ""
        for i in 1:20
            chars = pool[(2i - 1):(2i)]
            last_word = "u$(i) " * String(chars)
            str[] = last_word
        end
        @test atlas_settled(page)
        @test all_plot_glyphs_present(page)
        after = Makie.colorbuffer(screen)
        @test ndiff(before, after) > 100
        shot(page, "final")
    end
end

@testset "text deleted while its glyphs are in flight" begin
    pool = present_chars(Makie.to_font(FONT_NAMES[1]))[100:end]
    fig, ax = text_axis()
    lines!(ax, 1:10)
    with_page(App(() -> DOM.div(fig)); name = "edge-inflight", width = 440, height = 240) do page
        screen = wait_initialized(fig)
        base = Makie.colorbuffer(screen)
        used = Char[]
        for i in 1:15
            chars = pool[(2i - 1):(2i)]
            append!(used, chars)
            t = text!(ax, 5, 5; text = "fly " * String(chars), fontsize = 20, align = (:center, :center))
            delete!(ax, t)
        end
        @test ndiff(Makie.colorbuffer(screen), base) < 50
        @test atlas_settled(page)
        text!(ax, 5, 5; text = "kept " * String(used), fontsize = 14, align = (:center, :center))
        @test ndiff(Makie.colorbuffer(screen), base) > 100
        @test atlas_settled(page)
        @test all_plot_glyphs_present(page)
        shot(page, "final")
    end
end

@testset "the oldest renderer receives new glyphs" begin
    figs = Figure[]
    for i in 1:6
        fig = Figure(size = (300, 180))
        ax = Axis(fig[1, 1]; title = "renderer $(i)")
        lines!(ax, 1:5)
        push!(figs, fig)
    end
    app = App(() -> DOM.div(figs...; style = "display:flex; flex-wrap: wrap; width: 920px"))
    with_page(app; name = "edge-oldest", width = 940, height = 420) do page
        screens = [wait_initialized(fig) for fig in figs]
        before = [Makie.colorbuffer(s) for s in screens]
        text!(figs[1].content[1], 3, 3; text = "first ∮∯∰", fontsize = 18, align = (:center, :center))
        text!(figs[6].content[1], 3, 3; text = "sixth ⊕⊗⊙", fontsize = 18, align = (:center, :center))
        after = [Makie.colorbuffer(s) for s in screens]
        @test ndiff(before[1], after[1]) > 100
        @test ndiff(before[6], after[6]) > 100
        @test all(ndiff(before[i], after[i]) == 0 for i in 2:5)
        @test atlas_settled(page)
        shot(page, "final")
    end
end

@testset "many text figures present at page load" begin
    figs = Figure[]
    for i in 1:16
        fig = Figure(size = (230, 150), fontsize = 12)
        ax = Axis(fig[1, 1]; title = "load $(i) " * String(Char.(0x03B1 .+ (i:(i + 2)))))
        lines!(ax, 1:5)
        text!(ax, 3, 3; text = "t$(i) " * String(Char.(0x0410 .+ (i:(i + 2)))), align = (:center, :center))
        push!(figs, fig)
    end
    app = App(() -> DOM.div(figs...; style = "display:flex; flex-wrap: wrap; width: 940px"))
    with_page(app; name = "edge-burst", width = 960, height = 660) do page
        foreach(wait_initialized, figs)
        @test atlas_settled(page)
        @test all_plot_glyphs_present(page)
        @test canvases_alive(page)
        shot(page, "all")
    end
end

@testset "per-point char markers change" begin
    markers = Observable(['α', 'β', 'γ', 'δ', 'ε', 'ζ'])
    fig, ax = text_axis((400, 260))
    scatter!(ax, 1:6, 1:6; marker = markers, markersize = 28)
    with_page(App(() -> DOM.div(fig)); name = "edge-markers", width = 420, height = 280) do page
        screen = wait_initialized(fig)
        a = Makie.colorbuffer(screen)
        markers[] = ['Ж', 'Ш', 'Щ', 'Ы', 'Ю', 'Я']
        b = Makie.colorbuffer(screen)
        markers[] = ['1', '2', '3', '4', '5', '6']
        c = Makie.colorbuffer(screen)
        @test ndiff(a, b) > 100 && ndiff(b, c) > 100
        @test atlas_settled(page)
        shot(page, "final")
    end
end

@testset "fonts switch after display" begin
    font = Observable(Makie.to_font(FONT_NAMES[1]))
    fig, ax = text_axis()
    text!(ax, 0.5, 0.5; text = "Fonts Ωλ 42", font, align = (:center, :center), space = :relative, fontsize = 26)
    with_page(App(() -> DOM.div(fig)); name = "edge-fonts", width = 440, height = 240) do page
        screen = wait_initialized(fig)
        images = [Makie.colorbuffer(screen)]
        for name in FONT_NAMES[2:end]
            font[] = Makie.to_font(name)
            push!(images, Makie.colorbuffer(screen))
        end
        @test all(ndiff(images[i], images[i + 1]) > 100 for i in 1:(length(images) - 1))
        @test atlas_settled(page)
        @test all_plot_glyphs_present(page)
        shot(page, "mono")
    end
end

@testset "page reload" begin
    fig, ax = text_axis()
    text!(ax, 0.5, 0.5; text = "reload me Ω", align = (:center, :center), space = :relative, fontsize = 24)
    with_page(App(() -> DOM.div(fig)); name = "edge-reload", width = 440, height = 240) do page
        first_screen = wait_initialized(fig)
        before = Makie.colorbuffer(first_screen)
        js(page, "setTimeout(() => location.reload(), 20); true")
        @test Bonito.wait_for(() -> newest_screen(fig) !== first_screen; timeout = 30) === :success
        screen = wait_initialized(fig)
        @test wait_canvases(page, 1)
        @test ndiff(before, Makie.colorbuffer(screen)) < 50
        text!(ax, 0.5, 0.25; text = "after reload ∑∏", align = (:center, :center), space = :relative, fontsize = 20)
        @test ndiff(before, Makie.colorbuffer(screen)) > 100
        @test atlas_settled(page)
        shot(page, "final")
    end
end

@testset "reconnect without reload" begin
    str = Observable("before drop")
    fig, ax = text_axis()
    text!(ax, 0.5, 0.5; text = str, align = (:center, :center), space = :relative, fontsize = 24)
    with_page(App(() -> DOM.div(fig)); name = "edge-reconnect", width = 440, height = 240) do page
        screen = wait_initialized(fig)
        before = Makie.colorbuffer(screen)
        js(page, "window.WEBSOCKET.close(); true")
        str[] = "while down ⊂⊃⊆"
        @test wait_js(page, "window.WEBSOCKET.isopen()"; timeout = 30.0)
        @test Bonito.wait_for(() -> isopen(screen.session); timeout = 30) === :success
        @test ndiff(before, Makie.colorbuffer(screen)) > 100
        str[] = "back up ⊄⊅⊈"
        @test ndiff(before, Makie.colorbuffer(screen)) > 100
        @test atlas_settled(page)
        @test all_plot_glyphs_present(page)
        shot(page, "final")
    end
end

# Makie's texture atlas is fixed-size (2048², about 850 glyph slots per process,
# no resizing) and shared by every backend in the process: filling it is not an
# edge case of the sync but a hard stop for all later text, so this suite keeps
# its distinct glyphs well below that (about 400 in total). One plot with 120
# fresh glyphs still ships a batch over 1 MB in one message.
@testset "one text plot with over a hundred fresh glyphs" begin
    font = Makie.to_font(FONT_NAMES[4])
    chars = present_chars(font)[(end - 119):end]
    str = join((String(chars[i:min(i + 24, end)]) for i in 1:25:length(chars)), "\n")
    fig = Figure(size = (700, 320))
    ax = Axis(fig[1, 1]; title = FONT_NAMES[4])
    with_page(App(() -> DOM.div(fig)); name = "edge-bigbatch", width = 720, height = 340) do page
        screen = wait_initialized(fig)
        before = Makie.colorbuffer(screen)
        text!(ax, 0.02, 0.98; text = str, font, align = (:left, :top), space = :relative, fontsize = 14)
        @test ndiff(before, Makie.colorbuffer(screen)) > 1000
        @test isopen(screen.session)
        @test atlas_settled(page)
        @test all_plot_glyphs_present(page)
        shot(page, "all")
    end
end

@testset "cached figure on a new page after its page closed" begin
    fig, ax = text_axis()
    text!(ax, 0.5, 0.5; text = "cached Ωλ", align = (:center, :center), space = :relative, fontsize = 24)
    reference = Ref{Any}(nothing)
    for round in 1:2
        with_page(App(() -> DOM.div(fig)); name = "edge-cached-$(round)", width = 440, height = 240) do page
            screen = wait_initialized(fig)
            img = Makie.colorbuffer(screen)
            if round == 1
                reference[] = img
            else
                @test ndiff(reference[], img) < 50
                text!(ax, 0.5, 0.25; text = "second page ∇∆", align = (:center, :center), space = :relative, fontsize = 20)
                @test ndiff(reference[], Makie.colorbuffer(screen)) > 100
            end
            @test atlas_settled(page)
            shot(page, "final")
        end
    end
end
