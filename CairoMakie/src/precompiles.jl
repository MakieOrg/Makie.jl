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

    get_obs(x.attributes, visited, obs)
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
    return
end
