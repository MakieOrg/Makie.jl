function get_obs(x::Attributes, visited, obs=Set())
    if x in visited; return; else; push!(visited, x); end
    union!(obs, values(x))
    return obs
end

function get_obs(x::Union{AbstractVector, Tuple}, visited, obs=Set())
    if x in visited; return; else; push!(visited, x); end
    isempty(x) && return
    for e in x
        get_obs(e, visited, obs)
    end
    return obs
end

get_obs(::Nothing, visited, obs=Set()) = obs
get_obs(::DataType, visited, obs=Set()) = obs
get_obs(::Method, visited, obs=Set()) = obs

function get_obs(x, visited, obs=Set())
    if x in visited; return; else; push!(visited, x); end
    for f in fieldnames(typeof(x))
        if isdefined(x, f)
            get_obs(getfield(x, f), visited, obs)
        end
    end
end

function get_obs(x::Union{AbstractDict, NamedTuple}, visited, obs=Set())
    if x in visited; return; else; push!(visited, x); end
    for (k, v) in pairs(x)
        get_obs(v, visited, obs)
    end
    return obs
end

function get_obs(x::Union{Observables.AbstractObservable, Observables.ObserverFunction}, visited, obs=Set())
    push!(obs, x)
    return obs
end

function get_obs(x::Axis, visited, obs=Set())
    if x in visited; return; else; push!(visited, x); end

    # get_obs(x.attributes, visited, obs)
    get_obs(x.layoutobservables, visited, obs)
    get_obs(x.scene, visited, obs)
    get_obs(x.finallimits, visited, obs)
    get_obs(x.scrollevents, visited, obs)
    get_obs(x.keysevents, visited, obs)
    get_obs(x.mouseeventhandle.obs, visited, obs)
    return obs
end

function precompile_obs(x)
    obsies = get_obs(x, Base.IdSet())
    for obs in obsies
        Base.precompile(obs)
    end
end


function drawplot(scene, screen, primitive, Typ)
    if isempty(primitive.plots)
        Cairo.save(screen.context)
        CairoMakie.draw_atomic(scene, screen, primitive, Typ)
        Cairo.restore(screen.context)
    else
        for plot in primitive.plots
            drawplot(scene, screen, plot, Typ)
        end
    end
end

function draw_plot(scene, screen, Typ, args...; kw...)
    plot = PlotObject(Typ, Any[args...], Dict{Symbol, Any}(kw))
    Makie.prepare_plot!(scene, plot)
    drawplot(scene, screen, plot, Typ())
end

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(Makie.backend_display, (CairoBackend, Scene))
    activate!()
    f, ax1, pl = scatter(1:4)
    f, ax2, pl = lines(1:4)
    precompile_obs(ax1)
    precompile_obs(ax2)
    Makie.colorbuffer(ax1.scene)
    Makie.colorbuffer(ax2.scene)
    scene = Scene()
    screen = CairoMakie.CairoScreen(scene)
    attributes = Attributes(
        colorrange=nothing,
        model=Mat4f(I),
        color=:red,

    )
    r = Rect2f(0, 0, 1, 1)
    mesh = GeometryBasics.mesh(r)
    CairoMakie.draw_mesh2D(scene, screen, attributes, mesh)
     mesh = GeometryBasics.uv_mesh(r)
    CairoMakie.draw_mesh2D(scene, screen, attributes, mesh)
    mesh = GeometryBasics.normal_mesh(r)
    CairoMakie.draw_mesh2D(scene, screen, attributes, mesh)
    mesh = GeometryBasics.uv_normal_mesh(r)
    CairoMakie.draw_mesh2D(scene, screen, attributes, mesh)

    color = to_color(:red)
    vs =  decompose(Point2f, mesh)::Vector{Point2f}
    fs = decompose(GLTriangleFace, mesh)::Vector{GLTriangleFace}
    uv = decompose_uv(mesh)::Union{Nothing, Vector{Vec2f}}
    model = Mat4f(I)
    cols = per_face_colors(color, nothing, nothing, nothing, vs, fs, nothing, uv)
    CairoMakie.draw_mesh2D(scene, screen, cols, :data, vs, fs, model)

    mesh2 = GeometryBasics.normal_mesh(Sphere(Point3f(0), 1f0))

    attributes = Attributes(
        colorrange=nothing,
        model=Mat4f(I),
        color=:red,
        shading=true,
        diffuse=Vec3f(1),
        specular=Vec3f(0),
        shininess=2f0,
        faceculling=-10,
        space=:data
    )

    CairoMakie.draw_mesh3D(scene, screen, attributes, mesh2)
    mktempdir() do path
        save(joinpath(path, "test.png"), scatter(1:4))
    end

    scene = Scene()
    Makie.campixel!(scene)
    screen = CairoMakie.CairoScreen(scene)
    draw_plot(scene, screen, LineSegments, Point{2, Float32}[[17.306759, 16.0], [17.306759, 584.0], [203.98639, 16.0], [203.98639, 584.0], [390.66602, 16.0], [390.66602, 584.0], [577.34564, 16.0], [577.34564, 584.0], [764.02527, 16.0], [764.02527, 584.0]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,0.12f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, LineSegments, Point{2, Float32}[[110.646576, 16.0], [110.646576, 584.0], [297.3262, 16.0], [297.3262, 584.0], [484.0058, 16.0], [484.0058, 584.0], [670.6855, 16.0], [670.6855, 584.0]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,0.05f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, LineSegments, Point{2, Float32}[[16.0, 196.01993], [784.0, 196.01993], [16.0, 384.6459], [784.0, 384.6459], [16.0, 573.2719], [784.0, 573.2719]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,0.12f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, LineSegments, Point{2, Float32}[[16.0, 101.70693], [784.0, 101.70693], [16.0, 290.33292], [784.0, 290.33292], [16.0, 478.9589], [784.0, 478.9589]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,0.05f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, LineSegments, Point{2, Float32}[[17.306759, 15.5], [17.306759, 9.5], [203.98639, 15.5], [203.98639, 9.5], [390.66602, 15.5], [390.66602, 9.5], [577.34564, 15.5], [577.34564, 9.5], [764.02527, 15.5], [764.02527, 9.5]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, LineSegments, Point{2, Float32}[[110.646576, 15.5], [110.646576, 11.5], [297.3262, 15.5], [297.3262, 11.5], [484.0058, 15.5], [484.0058, 11.5], [670.6855, 15.5], [670.6855, 11.5]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, Text, ""; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), rotation=0.0f0, position=Point2f(400.0, 12.0), visible=true, font="dejavu sans book", markerspace=:data, align=(:center, :top), inspectable=false, textsize=16.0)
    draw_plot(scene, screen, Lines, Point{2, Float32}[[15.5, 16.0], [784.5, 16.0]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, Text, Tuple{AbstractString, Point{2, Float32}}[("0", [17.306759, 13.0]), ("200", [203.98639, 13.0]), ("400", [390.66602, 13.0]), ("600", [577.34564, 13.0]), ("800", [764.02527, 13.0])]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), rotation=0.0, font="dejavu sans book", visible=true, markerspace=:data, align=(:center, :top), inspectable=false, textsize=16.0)
    draw_plot(scene, screen, LineSegments, Point{2, Float32}[[15.5, 196.01993], [9.5, 196.01993], [15.5, 384.6459], [9.5, 384.6459], [15.5, 573.2719], [9.5, 573.2719]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, LineSegments, Point{2, Float32}[[15.5, 101.70693], [11.5, 101.70693], [15.5, 290.33292], [11.5, 290.33292], [15.5, 478.9589], [11.5, 478.9589]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, Text, ""; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), rotation=1.5707964f0, position=Point2f(10.0, 300.0), visible=true, font="dejavu sans book", markerspace=:data, align=(:center, :bottom), inspectable=false, textsize=16.0)
    draw_plot(scene, screen, Lines, Point{2, Float32}[[16.0, 15.5], [16.0, 584.5]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, Text, Tuple{AbstractString, Point{2, Float32}}[("200", [11.0, 196.01993]), ("400", [11.0, 384.6459]), ("600", [11.0, 573.2719])]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), rotation=0.0, font="dejavu sans book", visible=true, markerspace=:data, align=(:right, :center), inspectable=false, textsize=16.0)
    draw_plot(scene, screen, Lines, Point2{Float64}[[15.5, 584.0], [784.5, 584.0]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, Lines, Point2{Float64}[[784.0, 15.5], [784.0, 584.5]]; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), linestyle=nothing, visible=true, linewidth=1.0, inspectable=false)
    draw_plot(scene, screen, Text, ""; color=RGBA{Float32}(0.0f0,0.0f0,0.0f0,1.0f0), position=Point2f(400.0, 588.0), visible=true, font="dejavu sans book", markerspace=:data, align=(:center, :bottom), inspectable=false, textsize=16.0)
    Makie.colorbuffer(screen)
    return
end
