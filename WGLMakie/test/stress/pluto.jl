# Pluto: a notebook whose cells show WGLMakie figures in the browser. One cell is
# deleted through the page (selection + Delete key, as a user would), every cell
# is run again, and a new plot cell is added. The notebook runs in its own process
# with this suite's project active, as a user's notebook would.
using Test, Bonito, WGLMakie, Pluto, Sockets
using WGLMakie: Makie
isdefined(@__MODULE__, :StressKit) || include(joinpath(@__DIR__, "helpers.jl"))
using .StressKit: WGL_CANVASES

const NOTEBOOK_ENV = dirname(Base.active_project())

plot_cell(i) = Pluto.Cell(
    """let
        fig = Figure(size = (420, 240))
        ax = Axis(fig[1, 1]; title = "pluto cell $(i) Ω$(i)")
        lines!(ax, 1:10, (1:10) .* $(i))
        text!(ax, 5, 5 * $(i); text = "text $(i) ∑", align = (:center, :center), fontsize = 18)
        fig
    end"""
)

# One line, so typing it into the page's editor needs no indentation handling.
one_line_cell(i) = """let fig = Figure(size = (420, 240)); ax = Axis(fig[1, 1]; title = "pluto cell $(i) Ω$(i)"); lines!(ax, 1:10, (1:10) .* $(i)); text!(ax, 5, 5 * $(i); text = "text $(i) ∑", align = (:center, :center), fontsize = 18); fig end"""

function free_port()
    server = Sockets.listen(Sockets.localhost, 0)
    port = Sockets.getsockname(server)[2]
    close(server)
    return Int(port)
end

@testset "Pluto notebook with plot cells" begin
    setup = Pluto.Cell("begin\n    import Pkg\n    Pkg.activate($(repr(NOTEBOOK_ENV)); io = devnull)\n    using WGLMakie\nend")
    cells = [setup; [plot_cell(i) for i in 1:3]]
    dir = mktempdir()
    path = joinpath(dir, "stress.jl")
    Pluto.save_notebook(Pluto.Notebook(cells, path), path)
    port = free_port()
    options = Pluto.Configuration.from_flat_kwargs(;
        port, launch_browser = false, require_secret_for_access = false,
        require_secret_for_open_links = false, auto_reload_from_file = false,
    )
    session = Pluto.ServerSession(; options)
    server = Pluto.run!(session)
    nb = nothing
    try
        nb = Pluto.SessionActions.open(session, path; run_async = false)
        @test all(c -> !c.errored, nb.cells)
        url = "http://127.0.0.1:$(port)/edit?id=$(nb.notebook_id)"
        with_url(url; name = "pluto", width = 900, height = 1000) do page
            @test wait_rendered(page, 3; timeout = 120.0)
            @test wait_js(page, "WGL.get_texture_atlas().waiters.length === 0")
            shot(page, "three")
            # Delete the middle plot cell the way a user does: select it, press Delete.
            doomed = nb.cells[3]
            js(page, "window.__doomed = $(WGL_CANVASES)[1].wglmakie_screen; true")
            js(page, "window.editor_state_set({selected_cells: [$(repr(string(doomed.cell_id)))]}); true")
            @test wait_js(page, "window.editor_state.selected_cells.length === 1")
            js(page, "document.dispatchEvent(new KeyboardEvent('keydown', {key: 'Delete', bubbles: true})); true")
            @test Bonito.wait_for(() -> !(doomed.cell_id in nb.cell_order); timeout = 30) === :success
            @test wait_rendered(page, 2)
            # The deleted cell's figure released its screen and left the scene cache
            # (three scenes per figure: root, the Axis, and the Axis' block scene).
            @test wait_js(page, "Object.keys(window.__doomed).length === 0"; timeout = 10.0)
            @test wait_js(page, "Object.keys(WGL.scene_cache).length === 6"; timeout = 10.0)
            shot(page, "deleted")
            # Run every cell again: outputs are replaced in place.
            Pluto.update_run!(session, nb, nb.cells)
            @test all(c -> !c.errored, nb.cells)
            @test wait_rendered(page, 2; timeout = 120.0)
            @test wait_js(page, "WGL.get_texture_atlas().waiters.length === 0")
            # The replaced outputs released their screens: two figures, three scenes each
            # (root, the Axis, and the Axis' block scene).
            @test wait_js(page, "Object.keys(WGL.scene_cache).length === 6"; timeout = 30.0)
            shot(page, "rerun")
            # Add a plot cell at the end the way a user does: the "+" below the last
            # cell, code typed into its editor, Shift+Enter.
            js(page, "[...document.querySelectorAll('pluto-cell')].at(-1).querySelector('button.add_cell.after').click(); true")
            @test wait_js(page, "document.querySelectorAll('pluto-cell').length === 4")
            @test Bonito.wait_for(() -> length(nb.cell_order) == 4; timeout = 30) === :success
            # Focus the new cell's editor (as a click on it would), type the code with
            # real key events and submit with Shift+Enter.
            js(page, "(() => { const cell = [...document.querySelectorAll('pluto-cell')].at(-1); cell.scrollIntoView(); cell.querySelector('.cm-content').focus(); return true; })()")
            @test wait_js(page, "document.activeElement?.classList.contains('cm-content') && document.activeElement.closest('pluto-cell') === [...document.querySelectorAll('pluto-cell')].at(-1)")
            type_keys(page, one_line_cell(4))
            added = nb.cells[end]
            press_keys(page, "Return"; modifiers = ["shift"])
            @test Bonito.wait_for(() -> !isempty(added.code) && added.runtime !== nothing && !added.queued && !added.running; timeout = 120) === :success
            @test !added.errored
            @test wait_rendered(page, 3; timeout = 120.0)
            js(page, "[...document.querySelectorAll('pluto-cell')].at(-1).scrollIntoView(); true")
            shot(page, "added")
        end
    finally
        nb === nothing || Pluto.SessionActions.shutdown(session, nb)
        close(server)
    end
end
