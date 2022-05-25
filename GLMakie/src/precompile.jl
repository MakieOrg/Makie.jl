function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
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
        if isa(x, PlotObject)
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
end
