using GLMakie, GeometryBasics, LinearAlgebra, FileIO
GLMakie.activate!(float=true, render_on_demand=false, vsync=true)
frag = read(joinpath(@__DIR__, "clouds.frag"), String)
img = load(joinpath(@__DIR__, "noise.png"))
begin
    GLMakie.closeall()
    s=Scene()
    shadertoy!(s,
        Rect2f(-1, -1, 2, 2), frag;
        uniforms=Dict{Symbol, Any}(
            :iChannel0 => GLMakie.Sampler(img; x_repeat=:repeat, minfilter=:linear)
        )
    )
    s
end

begin
    GLMakie.closeall()
    s = Scene()
    shadertoy!(s, Rect2f(-1, -1, 2, 2), read(joinpath(@__DIR__, "raytracing.frag"), String))
    scren = display(s)
end

begin
    f, ax, pl = shadertoy(Rect2f(-1, -1, 2, 2), read(joinpath(@__DIR__, "raytracing.frag"), String))
    foreach(n->deregister_interaction!(ax, n), keys(interactions(ax)))
    f
end
shadertoy(Rect2f(-1, -1, 2, 2), read(joinpath(@__DIR__, "monster.frag"), String))
