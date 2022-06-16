function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return
    precompile(Makie.backend_display, (GLBackend, Scene))

    activate!()
    precompile(refreshwindowcb, (GLFW.Window, Screen))
    p = plot(rand(10))
    # Mimic `display(p)` without actually creating a display
    function insertplotstype(scene)
        for elem in scene.plots
            inserttype(scene, elem)
        end
        foreach(s-> insertplotstype(s), scene.children)
    end
    function inserttype(scene, @nospecialize(x))
        if isa(x, Combined)
            if isempty(x.plots)
                precompile(insert!, (Screen, typeof(scene), typeof(x)))
            else
                foreach(x.plots) do x
                    inserttype(scene, x)
                end
            end
        else
            precompile(insert!, (Screen, typeof(scene), typeof(x)))
        end
    end
    scene = p.figure.scene
    insertplotstype(scene)
    screen = Screen(; visible=false)
    fig, ax1, pl = scatter(1:4;color=:green, visible=true, markersize=15)
    Makie.backend_display(screen, fig.scene)
    Makie.colorbuffer(screen)
    f, ax2, pl = lines(1:4)
    Makie.precompile_obs(ax1)
    Makie.precompile_obs(ax2)
    closeall()
    return
end
