using GLMakie

function rewrap(robj::GLMakie.RenderObject{Pre}) where {Pre}
    GLMakie.ShaderAbstractions.switch_context!(robj.context)
    GLMakie.RenderObject{Pre}(
        robj.context,
        copy(robj.uniforms),
        robj.observables,
        robj.vertexarray,
        robj.prerenderfunction,
        robj.postrenderfunction,
        Observable(robj.visible),
        false
    )
end

function copy_plot!(screen::GLMakie.Screen, plot)
    robj = screen.cache[objectid(plot)]
    cpy = rewrap(robj)
    screenid = screen.screen2scene[WeakRef(parent(plot))]
    screen.cache2plot[cpy.id] = plot
    push!(screen.renderlist, (0, screenid, cpy))
    return cpy
end

GLMakie.activate!(float=true)
begin
    N = 50
    r = LinRange(-1, 1, N)
    r2 = LinRange(0, 1, N)
    cube = Float32[(x .^ 2 + y .^ 2 + z .^ 2) for x = r, y = r, z = r2]
    fig, ax, pl = volume(cube, algorithm=:iso);
    if isdefined(Main, :screen)
        # messing with the internal renderlist will not clean up correctly, so we need to cleanup manually
        screen.renderlist |> empty!
        screen.cache2plot |> empty!
    end
    GLMakie.closeall()
    screen = display(fig)
end

cpy = copy_plot!(screen, pl)
robj = screen.cache[objectid(pl)]
model = Makie.scalematrix(Vec3f(1, -1, -1)) * robj[:model][]
cpy.uniforms[:model] = model
cpy.uniforms[:modelinv] = inv(model)
