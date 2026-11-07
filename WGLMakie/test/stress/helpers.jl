# Shared scaffolding for the WGLMakie browser stress suite.
#
# Every scenario serves a Bonito `App` on a local server, opens it in a headless
# Electron window through ElectronCall's testing helpers, and records every
# console warning and error in Electron's MAIN process (the window's
# `console-message` event), so nothing a page logs before Bonito is up, or while
# the renderer is busy, is missed. A scenario fails if anything unexpected was
# logged. Screenshots go to `results/` next to this file for inspection.
module StressKit

    using Bonito, WGLMakie, JSON, Test
    using WGLMakie: Makie
    using ElectronCall
    const ECT = ElectronCall.Testing

    const RESULTS = joinpath(@__DIR__, "results")

    # Console messages that are not the page's fault: the GPU process commenting on
    # the driver, and Chromium's software compositor reading WebGL frames back.
    const BENIGN = [
        r"^\[\.WebGL-[^\]]*\]GL Driver Message \([^,]*, Performance,",
        r"Automatic fallback to software WebGL has been deprecated",
    ]

    struct Page
        ctx::ECT.TestContext
        # `nothing` for a page loaded from a file (an offline export).
        server::Union{Bonito.Server, Nothing}
        app::Union{App, Nothing}
        name::String
    end

    function capture_console!(ctx::ECT.TestContext)
        run(
            ctx.app, """(() => {
                const wc = electron.BrowserWindow.fromId($(ctx.window.id)).webContents;
                global.__stressConsole = [];
                wc.on('console-message', (e) => {
                    if (e.level !== 'warning' && e.level !== 'error') return;
                    global.__stressConsole.push({type: e.level, message: String(e.message),
                        source: String(e.sourceId ?? ''), line: e.lineNumber});
                });
                return true;
            })()"""
        )
        return ctx
    end

    function console_entries(ctx::ECT.TestContext)
        v = run(ctx.app, "global.__stressConsole.splice(0)")
        return v === nothing ? Any[] : collect(Any, v)
    end

    unexpected(entries) = filter(e -> !any(re -> occursin(re, e["message"]), BENIGN), entries)

    """
        open_page(app; name, width = 1000, height = 800) -> Page

    Serve `app` on a fresh local server and open it in a headless window. The page's
    console is recorded from the first load on.
    """
    function open_page(app::App; name::String, width::Int = 1000, height::Int = 800)
        server = Bonito.Server("127.0.0.1", 0)
        Bonito.route!(server, "/" => app)
        ctx = open_window(server; width, height)
        return Page(ctx, server, app, name)
    end

    "A second window on the same server: a new session of the same app."
    function open_tab(page::Page; width::Int = 1000, height::Int = 800)
        ctx = open_window(page.server; width, height)
        return Page(ctx, page.server, page.app, page.name)
    end

    open_window(server::Bonito.Server; kw...) = open_window("http://127.0.0.1:$(server.port)/"; kw...)

    function open_window(url::AbstractString; width::Int, height::Int, offscreen::Bool = true)
        # Electron warns about the missing Content-Security-Policy of every unpackaged
        # app; the pages under test are not the ones being judged for that.
        ctx = withenv("ELECTRON_DISABLE_SECURITY_WARNINGS" => "true") do
            ECT.open_window(url; width, height, offscreen)
        end
        capture_console!(ctx)
        return ctx
    end

    "A page served by nothing but the file system, e.g. an offline export."
    function open_url(url::AbstractString; name::String, width::Int = 1000, height::Int = 800)
        return Page(open_window(url; width, height), nothing, nothing, name)
    end

    function with_url(f, url::AbstractString; name::String, kw...)
        page = open_url(url; name, kw...)
        try
            f(page)
        finally
            finish!(page; close_server = false)
        end
        return
    end

    """
        with_page(f, app; name, kw...)

    Run `f(page)`, then assert the console stayed clean and tear everything down.
    The server is closed only by the outermost page, tabs opened with `open_tab`
    close just their window.
    """
    function with_page(f, app::App; name::String, kw...)
        page = open_page(app; name, kw...)
        try
            f(page)
        finally
            finish!(page; close_server = true)
        end
        return
    end

    function finish!(page::Page; close_server::Bool)
        entries = unexpected(console_entries(page.ctx))
        for e in entries
            println("console $(e["type"]) in $(page.name): $(e["message"]) ($(e["source"]):$(e["line"]))")
        end
        @test isempty(entries)
        close(page.ctx)
        close_server && page.server !== nothing && close(page.server)
        return
    end

    js(page::Page, code::AbstractString) = ECT.eval_js(page.ctx, code)

    function wait_js(page::Page, code::AbstractString; timeout = 30.0)
        ok = ECT.wait_for(page.ctx, code; timeout)
        ok || println("timed out waiting for: ", code)
        return ok
    end

    # WGLMakie's canvases only: before initialization the wrapper still shows the
    # spinner, afterwards the canvas carries its screen. Editors (Monaco's minimap) and
    # other widgets add canvases of their own.
    const WGL_CANVASES = "[...document.querySelectorAll('canvas')].filter(c => c.wglmakie_screen || c.parentElement?.querySelector('.wglmakie-spinner'))"

    wait_canvases(page::Page, n::Int; timeout = 30.0) =
        wait_js(page, "$(WGL_CANVASES).length === $(n)"; timeout)

    """
        wait_rendered(page, n; timeout = 30.0)

    Wait until exactly `n` figures are on the page and every one has drawn its first
    frame (its spinner is gone) with a live WebGL context. The check for a notebook
    or a chat, where the figures' screens live in another process.
    """
    function wait_rendered(page::Page, n::Int; timeout = 30.0)
        return wait_js(
            page, """(() => {
                const cs = $(WGL_CANVASES);
                if (cs.length !== $(n) || document.querySelector('.wglmakie-spinner')) return false;
                return cs.every(c => c.wglmakie_screen && c.wglmakie_screen.renderer && c.width > 0 &&
                    !c.wglmakie_screen.renderer.getContext().isContextLost());
            })()"""; timeout
        )
    end

    "Every canvas has a size and a WebGL context that is not lost."
    canvases_alive(page::Page) = js(
        page, """(() => {
            const cs = $(WGL_CANVASES);
            return cs.length > 0 && cs.every(c => c.width > 0 && c.height > 0 &&
                (() => { const gl = c.getContext('webgl2') || c.getContext('webgl'); return gl && !gl.isContextLost(); })());
        })()"""
    ) === true

    function shot(page::Page, label::AbstractString)
        mkpath(RESULTS)
        path = joinpath(RESULTS, "$(page.name)-$(label).png")
        ECT.screenshot(page.ctx; path)
        println("screenshot: ", path)
        return path
    end

    "The WGLMakie screen a figure was displayed on most recently (a re-display adds a new one)."
    function newest_screen(fig)
        screens = filter(s -> s isa WGLMakie.Screen, Makie.get_scene(fig).current_screens)
        return isempty(screens) ? nothing : last(screens)
    end

    "Wait until the figure's newest screen reports its plots initialized, or fail."
    function wait_initialized(fig; timeout = 30.0)
        ok = Bonito.wait_for(; timeout) do
            screen = newest_screen(fig)
            screen !== nothing && isready(screen.plot_initialized)
        end
        @test ok === :success
        screen = newest_screen(fig)
        ok === :success && @test fetch(screen.plot_initialized) === true
        return screen
    end

    "Wait until every WGLMakie screen of the figure except the newest is closed."
    function wait_old_screens_closed(fig; timeout = 10.0)
        scene = Makie.get_scene(fig)
        ok = Bonito.wait_for(; timeout) do
            screens = filter(s -> s isa WGLMakie.Screen, scene.current_screens)
            all(s -> !isopen(s), screens[1:(end - 1)])
        end
        @test ok === :success
        return
    end

    # Real keyboard input through Electron's input pipeline: contenteditable editors
    # (CodeMirror) take text only from genuine key events, not from scripted ones.
    function type_keys(page::Page, text::AbstractString; char_delay = 0.02)
        for c in text
            ECT.send_input(page.ctx, JSON.json(Dict("type" => "char", "keyCode" => string(c))))
            sleep(char_delay)
        end
        return
    end

    "A real mouse click (through Electron's input pipeline) at the center of the first element matching `selector`."
    function click_at(page::Page, selector::AbstractString)
        rect = js(page, "(() => { const r = document.querySelector($(JSON.json(selector))).getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height / 2]; })()")
        x, y = round(Int, rect[1]), round(Int, rect[2])
        for type in ("mouseMove", "mouseDown", "mouseUp")
            ECT.send_input(page.ctx, JSON.json(Dict("type" => type, "x" => x, "y" => y, "button" => "left", "clickCount" => 1)))
        end
        return
    end

    function press_keys(page::Page, key::AbstractString; modifiers = String[])
        ECT.send_input(page.ctx, JSON.json(Dict("type" => "keyDown", "keyCode" => key, "modifiers" => modifiers)))
        ECT.send_input(page.ctx, JSON.json(Dict("type" => "keyUp", "keyCode" => key, "modifiers" => modifiers)))
        return
    end

    "Number of pixels that differ between two colorbuffers."
    ndiff(a, b) = count(a .!= b)

    export Page, open_page, open_tab, open_url, with_page, with_url, finish!, js, wait_js, wait_canvases, wait_rendered,
        canvases_alive, shot, newest_screen, wait_initialized, wait_old_screens_closed, type_keys, press_keys, click_at, ndiff, RESULTS

end # module

using .StressKit
