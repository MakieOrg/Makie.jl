function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(Makie.backend_display, (CairoBackend, Scene))
    activate!()
    f, ax1, pl = scatter(1:4)
    f, ax2, pl = lines(1:4)
    Makie.colorbuffer(ax1.scene)
    Makie.colorbuffer(ax2.scene)
    scene = Scene()

    screen = CairoMakie.CairoScreen(scene)

    attributes = Attributes(
        colormap=nothing,
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
    CairoMakie.draw_mesh2D(scene, screen, cols, vs, fs, model)

    mesh2 = GeometryBasics.normal_mesh(Sphere(Point3f(0), 1f0))

    attributes = Attributes(
        colormap=nothing,
        colorrange=nothing,
        model=Mat4f(I),
        color=:red,
        shading=true,
        diffuse=Vec3f(1),
        specular=Vec3f(0),
        shininess=2f0,
        faceculling=true
    )

    CairoMakie.draw_mesh3D(scene, screen, attributes, mesh2)
    return
end
