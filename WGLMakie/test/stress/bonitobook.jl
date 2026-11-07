# BonitoBook: a book whose Julia cells show WGLMakie figures, all cells run while
# the page is open, a cell deleted, everything run again, and a cell added.
using Test, Bonito, WGLMakie, BonitoBook, Logging
using WGLMakie: Makie
isdefined(@__MODULE__, :StressKit) || include(joinpath(@__DIR__, "helpers.jl"))
using .StressKit: WGL_CANVASES

julia_cell(src) = "```julia (editor=true, logging=false, output=true)\n" * src * "\n```\n"
figure_src(i) = """let
    fig = Figure(size = (420, 240))
    ax = Axis(fig[1, 1]; title = "book cell $(i) Ω$(i)")
    lines!(ax, 1:10, (1:10) .* $(i))
    text!(ax, 5, 5 * $(i); text = "text $(i) ∑", align = (:center, :center), fontsize = 18)
    fig
end"""

cell_with(book, needle) = book.cells[findfirst(c -> occursin(needle, c.editor.source[]), book.cells)]

# Run cells the way the page's run buttons do: queued on the book's runner. The
# synchronous `run_all!` pins a task to thread 1, which a test driver living on
# another thread may never schedule.
function run_cells!(book, cells; timeout = 120)
    foreach(c -> BonitoBook.run!(c.editor), cells)
    done = Bonito.wait_for(; timeout) do
        isempty(book.runner.task_queue) && all(c -> !c.editor.loading[], cells)
    end
    @test done === :success
    return
end
julia_cells(book) = filter(c -> c.language == "julia", book.cells)

@testset "BonitoBook with plot cells" begin
    dir = mktempdir()
    file = joinpath(dir, "stress.md")
    write(file, "# Stress book\n\n" * julia_cell("using WGLMakie") * join((julia_cell(figure_src(i)) for i in 1:3), "\n"))
    # The book's runner captures the process-wide stdout, stderr and global logger
    # for cell output; the test driver takes them back so the run stays visible
    # and later log messages do not end up in a pipe nobody reads.
    driver_stdout, driver_stderr, driver_logger = stdout, stderr, Logging.global_logger()
    book = BonitoBook.Book(file)
    redirect_stdout(driver_stdout)
    redirect_stderr(driver_stderr)
    Logging.global_logger(driver_logger)
    with_page(App(() -> book; title = "book"); name = "book", width = 1100, height = 1000) do page
        @test wait_js(page, "document.querySelector('.book-cells-area') !== null"; timeout = 60.0)
        run_cells!(book, julia_cells(book))
        @test wait_rendered(page, 3; timeout = 120.0)
        @test wait_js(page, "WGL.get_texture_atlas().waiters.length === 0")
        shot(page, "three")
        doomed = cell_with(book, "book cell 2")
        js(page, "window.__doomed = $(WGL_CANVASES)[1].wglmakie_screen; true")
        delete!(book, doomed)
        @test wait_js(page, "document.getElementById($(repr("$(doomed.uuid)-container"))) === null")
        @test wait_rendered(page, 2)
        # The deleted cell's figure released its screen and left the scene cache
        # (three scenes per figure: root, the Axis, and the Axis' block scene).
        @test wait_js(page, "Object.keys(window.__doomed).length === 0"; timeout = 10.0)
        @test wait_js(page, "Object.keys(WGL.scene_cache).length === 6"; timeout = 10.0)
        shot(page, "deleted")
        run_cells!(book, julia_cells(book))
        @test wait_rendered(page, 2; timeout = 120.0)
        # The replaced outputs released their screens: two figures, three scenes each
        # (root, the Axis, and the Axis' block scene).
        @test wait_js(page, "Object.keys(WGL.scene_cache).length === 6"; timeout = 30.0)
        shot(page, "rerun")
        added = BonitoBook.CellEditor(figure_src(4), "julia", book.runner; theme = book.monaco_theme)
        BonitoBook.insert_cell_at!(book, added, :end)
        run_cells!(book, [added])
        @test wait_rendered(page, 3; timeout = 60.0)
        js(page, "document.getElementById($(repr("$(added.uuid)-container"))).scrollIntoView(); true")
        shot(page, "added")
    end
    # The book switched the process-wide Makie theme to its dark one.
    Makie.set_theme!()
end
