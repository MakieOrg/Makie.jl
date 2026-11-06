# Offline export: several plots on one static page, loaded from a file without a
# Julia process behind it. Covers `export_static` of an App and the Documenter-style
# `Page(exportable = true, offline = true)` with several figures shown in a row.
using Test, Bonito, WGLMakie
using WGLMakie: Makie
isdefined(@__MODULE__, :StressKit) || include(joinpath(@__DIR__, "helpers.jl"))

function export_figures()
    f1 = Figure(size = (400, 250))
    ax = Axis(f1[1, 1]; title = "offline lines α")
    lines!(ax, 0 .. 10, sin)
    text!(ax, 5, 0; text = "static text Ω", align = (:center, :center), fontsize = 18)
    f2 = Figure(size = (400, 250))
    xs = range(-1, 1; length = 30)
    surface(f2[1, 1], xs, xs, [x^2 - y^2 for x in xs, y in xs]; axis = (type = Axis3, title = "surface"))
    f3 = Figure(size = (400, 250))
    heatmap(f3[1, 1], [sin(x) * cos(y) for x in 1:20, y in 1:20]; axis = (title = "heatmap",))
    f4 = Figure(size = (400, 250))
    scatter(f4[1, 1], 1:10; marker = 'x', markersize = 20, axis = (title = "char markers",))
    return [f1, f2, f3, f4]
end

@testset "export_static with four figures" begin
    figs = export_figures()
    app = App(() -> DOM.div(figs...; style = "display:flex; flex-wrap:wrap; width: 820px"))
    path = joinpath(RESULTS, "export-static.html")
    mkpath(RESULTS)
    Bonito.export_static(path, app)
    @test filesize(path) > 100_000
    with_url("file://" * path; name = "export-static", width = 840, height = 560) do page
        @test wait_rendered(page, 4)
        @test wait_js(page, "(() => { const a = WGL.get_texture_atlas(); return a.waiters.length === 0; })()")
        # Text glyphs must have come with the page: nothing can be pulled offline.
        @test js(
            page, """(() => {
                const atlas = WGL.get_texture_atlas();
                const plots = Object.values(WGL.plot_cache).map(m => m.plot_object).filter(p => p.glyph_info?.glyph_hashes);
                return plots.length >= 2 && plots.every(p => Array.from(p.glyph_info.glyph_hashes).every(h => atlas.glyph_data.has(String(h))));
            })()"""
        ) === true
        shot(page, "all")
    end
end

@testset "Page(exportable, offline) with figures shown in sequence" begin
    figs = export_figures()
    # The Documenter flow: `Page` configures the process, the first figure shown
    # carries the page setup, the following ones are sub-sessions of it.
    Bonito.Page(exportable = true, offline = true)
    # Each figure sits in a block of its own, as a notebook or docs page would put
    # it (WGLMakie's wrapper fills its parent's height).
    html = sprint() do io
        println(io, "<html><body>")
        for fig in figs
            println(io, "<div>")
            show(io, MIME"text/html"(), fig)
            println(io, "</div>")
        end
        println(io, "</body></html>")
    end
    Bonito.Page(exportable = false, offline = false)
    path = joinpath(RESULTS, "export-page.html")
    write(path, html)
    @test filesize(path) > 100_000
    with_url("file://" * path; name = "export-page", width = 840, height = 1100) do page
        @test wait_rendered(page, 4)
        @test wait_js(page, "(() => { const a = WGL.get_texture_atlas(); return a.waiters.length === 0; })()")
        shot(page, "all")
    end
end
