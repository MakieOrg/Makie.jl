function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return

    activate!()
    f1, ax1, pl = scatter(1:4)
    f2, ax2, pl = lines(1:4)
    Makie.precompile_obs(ax1)
    Makie.precompile_obs(ax2)
    serv = JSServe.get_server()
    s = JSServe.Session()
    JSServe.jsrender(s, f1)
    JSServe.jsrender(s, f2)
    close(serv)
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
                precompile(insert!, (ThreeDisplay, typeof(scene), typeof(x)))
            else
                foreach(x.plots) do x
                    inserttype(scene, x)
                end
            end
        else
            precompile(insert!, (ThreeDisplay, typeof(scene), typeof(x)))
        end
    end
    fig, ax1, pl = scatter(1:4; color=:green, visible=true, markersize=15)
    screen = ThreeDisplay(JSServe.Session())
    Makie.push_screen!(fig.scene, screen)
    insertplotstype(fig.scene)
    insertplotstype(ax1.scene)
    insertplotstype(ax1.blockscene)
    three_display(screen.session, fig.scene);
    push!(fig.scene, pl)
    serialize_scene(fig.scene)
    Makie.MakieCore.plot!(fig.scene, Scatter, Attributes(color=:green, visible=true, markersize=15), 1:4)
    @assert precompile(insert!, (WGLMakie.ThreeDisplay, Scene, Scatter{Tuple{Vector{Point{2, Float32}}}}))
    @assert precompile(serialize_three, (Scene, Scatter{Tuple{Vector{Point{2, Float32}}}}))
    @assert precompile(scatter_shader, (Scene, Dict{Symbol, Observable}))
    Makie.get_texture_atlas()
    atlas = Makie.TextureAtlas()
    Makie.load_ascii_chars!(atlas)
    println("done")
    return
end
