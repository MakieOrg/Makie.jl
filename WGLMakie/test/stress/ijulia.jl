# IJulia in JupyterLab: a notebook with WGLMakie cells run in a kernel using this
# suite's project, outputs rendered in the page, a cell deleted, all cells run
# again, and a cell added. JupyterLab is driven through its own command system
# (`window.jupyterapp`, exposed with `--expose-app-in-browser`).
#
# Under JupyterLab, Bonito reaches its server through the `jupyter-server-proxy`
# extension (`/proxy/<port>/`). The first cell points the page at the kernel's
# server directly instead, so the suite does not depend on that extension being
# installed; with it, only the websocket URL differs.
using Test, Bonito, WGLMakie, IJulia, JSON, Sockets
using WGLMakie: Makie
isdefined(@__MODULE__, :StressKit) || include(joinpath(@__DIR__, "helpers.jl"))

const KERNEL_ENV = dirname(Base.active_project())
const KERNEL = "julia-wglstress"

function free_port()
    server = Sockets.listen(Sockets.localhost, 0)
    port = Sockets.getsockname(server)[2]
    close(server)
    return Int(port)
end

function wait_port(port; timeout = 60)
    return Bonito.wait_for(; timeout) do
        try
            close(Sockets.connect(Sockets.localhost, port))
            true
        catch e
            e isa Base.IOError || rethrow()
            false
        end
    end
end

cell_src(i) = """fig$(i) = Figure(size = (420, 240)); ax$(i) = Axis(fig$(i)[1, 1]; title = "jupyter cell $(i) Ω$(i)"); lines!(ax$(i), 1:10, (1:10) .* $(i)); text!(ax$(i), 5, 5 * $(i); text = "text $(i) ∑", align = (:center, :center), fontsize = 18); fig$(i)"""

function notebook_json(cells)
    return Dict(
        "nbformat" => 4, "nbformat_minor" => 5,
        "metadata" => Dict("kernelspec" => Dict("name" => KERNEL, "display_name" => KERNEL, "language" => "julia")),
        "cells" => [Dict("cell_type" => "code", "id" => "c$(i)", "metadata" => Dict(), "execution_count" => nothing, "outputs" => [], "source" => c) for (i, c) in enumerate(cells)],
    )
end

run_all(page) = js(page, "window.jupyterapp.shell.activateById(window.__nb.id); window.jupyterapp.commands.execute('notebook:run-all-cells'); true")

@testset "IJulia notebook in JupyterLab" begin
    spec = IJulia.installkernel(KERNEL, "--project=$(KERNEL_ENV)"; specname = KERNEL)
    port = free_port()
    bonito_port = free_port()
    setup = """using WGLMakie
    WGLMakie.Bonito.configure_server!(listen_url = "127.0.0.1", listen_port = $(bonito_port), proxy_url = "http://127.0.0.1:$(bonito_port)")"""
    dir = mktempdir()
    open(joinpath(dir, "stress.ipynb"), "w") do io
        JSON.print(io, notebook_json([setup; [cell_src(i) for i in 1:3]]))
    end
    log = joinpath(dir, "jupyter.log")
    cmd = `jupyter lab --no-browser --port=$(port) --ServerApp.token= --ServerApp.password= --ServerApp.disable_check_xsrf=True --expose-app-in-browser --ServerApp.root_dir=$(dir)`
    jupyter = run(pipeline(cmd; stdout = log, stderr = log); wait = false)
    try
        @test wait_port(port) === :success
        with_url("http://127.0.0.1:$(port)/lab"; name = "jupyter", width = 1100, height = 1000) do page
            # The app object exists before its extensions registered their commands.
            @test wait_js(page, "!!window.jupyterapp?.commands?.hasCommand('docmanager:open') && window.jupyterapp.commands.hasCommand('notebook:run-all-cells')"; timeout = 90.0)
            js(page, "window.__nb = null; window.jupyterapp.commands.execute('docmanager:open', {path: 'stress.ipynb', kernel: {name: $(repr(KERNEL))}}).then(w => { window.__nb = w; }); true")
            @test wait_js(page, "!!window.__nb?.content?.model && window.__nb.content.widgets.length === 4"; timeout = 60.0)
            @test wait_js(page, "window.__nb?.sessionContext?.session?.kernel?.status === 'idle'"; timeout = 120.0)
            @test wait_js(page, "document.querySelectorAll('.jp-Dialog').length === 0")
            run_all(page)
            @test wait_rendered(page, 3; timeout = 240.0)
            @test wait_js(page, "WGL.get_texture_atlas().waiters.length === 0")
            shot(page, "three")
            # Delete the middle plot cell through JupyterLab's own command.
            js(page, "window.__nb.content.activeCellIndex = 2; window.jupyterapp.commands.execute('notebook:delete-cell'); true")
            @test wait_js(page, "window.__nb.content.widgets.length === 3")
            @test wait_rendered(page, 2)
            shot(page, "deleted")
            run_all(page)
            @test wait_rendered(page, 2; timeout = 120.0)
            @test wait_js(page, "Object.keys(WGL.scene_cache).length === 6"; timeout = 30.0)
            shot(page, "rerun")
            # Append a plot cell and run it.
            js(page, "(() => { const m = window.__nb.content.model.sharedModel; m.insertCell(m.cells.length, {cell_type: 'code', source: $(repr(cell_src(4)))}); return true; })()")
            @test wait_js(page, "window.__nb.content.widgets.length === 4")
            js(page, "window.__nb.content.activeCellIndex = 3; window.jupyterapp.commands.execute('notebook:run-cell'); true")
            @test wait_rendered(page, 3; timeout = 120.0)
            js(page, "window.__nb.content.widgets[3].node.scrollIntoView(); true")
            shot(page, "added")
        end
    finally
        kill(jupyter)
        wait(jupyter)
        rm(spec; force = true, recursive = true)
    end
end
