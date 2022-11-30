using Makie: el32convert, surface_normals, get_dim

# Somehow we started using Nothing for some colors in Makie,
# but the convert leaves them at nothing -.-
# TODO clean this up in Makie
nothing_or_color(c) = to_color(c)
nothing_or_color(c::Nothing) = RGBAf(0, 0, 0, 1)

function draw_mesh(mscene::Scene, mesh, plot; uniforms...)
    uniforms = Dict(uniforms)
    filter!(kv -> !(kv[2] isa Function), uniforms)

    colormap = if haskey(plot, :colormap)
        cmap = lift(el32convert ∘ to_colormap, plot.colormap)
        uniforms[:colormap] = Sampler(cmap)
    end

    colorrange = if haskey(plot, :colorrange)
        uniforms[:colorrange] = lift(Vec2f, plot.colorrange)
    end

    get!(uniforms, :colormap, false)
    get!(uniforms, :colorrange, false)
    get!(uniforms, :color, false)
    get!(uniforms, :pattern, false)
    get!(uniforms, :model, plot.model)
    get!(uniforms, :depth_shift, 0f0)
    get!(uniforms, :lightposition, Vec3f(1))
    get!(uniforms, :ambient, Vec3f(1))
    get!(uniforms, :interpolate_in_fragment_shader, true)
    uniforms[:normalmatrix] = map(mscene.camera.view, plot.model) do v, m
        i = Vec(1, 2, 3)
        return transpose(inv(v[i, i] * m[i, i]))
    end

    return Program(WebGL(), lasset("mesh.vert"), lasset("mesh.frag"), mesh; uniforms...)
end

xy_convert(x::AbstractArray{Float32}, n) = copy(x)
xy_convert(x::AbstractArray, n) = el32convert(x)
xy_convert(x, n) = Float32[LinRange(extrema(x)..., n + 1);]

function limits_to_uvmesh(plot)
    px, py, pz = plot[1], plot[2], plot[3]
    px = map((x, z)-> xy_convert(x, size(z, 1)), px, pz)
    py = map((y, z)-> xy_convert(y, size(z, 2)), py, pz)
    # Special path for ranges of length 2 which
    # can be displayed as a rectangle
    t = Makie.transform_func_obs(plot)[]
    if px[] isa StepRangeLen && py[] isa StepRangeLen && Makie.is_identity_transform(t)
        rect = lift(px, py) do x, y
            xmin, xmax = extrema(x)
            ymin, ymax = extrema(y)
            return Rect2(xmin, ymin, xmax - xmin, ymax - ymin)
        end
        positions = Buffer(lift(rect-> decompose(Point2f, rect), rect))
        faces = Buffer(lift(rect -> decompose(GLTriangleFace, rect), rect))
        uv = Buffer(lift(decompose_uv, rect))
    else 
        grid(x, y, trans, space) = Makie.matrix_grid(p-> apply_transform(trans, p, space), x, y, zeros(length(x), length(y)))
        rect = lift((x, y) -> Tesselation(Rect2(0f0, 0f0, 1f0, 1f0), (length(x), length(y))), px, py)
        positions = Buffer(lift(grid, px, py, t, get(plot, :space, :data)))
        faces = Buffer(lift(r -> decompose(GLTriangleFace, r), rect))
        uv = Buffer(lift(decompose_uv, rect))
    end

    vertices = GeometryBasics.meta(positions; uv=uv)

    return GeometryBasics.Mesh(vertices, faces)
end

function get_color(plot, key::Symbol)::Observable{RGBAf}
    if haskey(plot, key)
        return lift(to_color, plot[key])
    else
        return Observable(RGBAf(0, 0, 0, 0))
    end
end

function create_shader(mscene::Scene, plot::Surface)
    # TODO OWN OPTIMIZED SHADER ... Or at least optimize this a bit more ...
    px, py, pz = plot[1], plot[2], plot[3]
    grid(x, y, z, trans, space) = Makie.matrix_grid(p-> apply_transform(trans, p, space), x, y, z)
    positions = Buffer(lift(grid, px, py, pz, transform_func_obs(plot), get(plot, :space, :data)))
    rect = lift(z -> Tesselation(Rect2(0f0, 0f0, 1f0, 1f0), size(z)), pz)
    faces = Buffer(lift(r -> decompose(GLTriangleFace, r), rect))
    uv = Buffer(lift(decompose_uv, rect))
    plot_attributes = copy(plot.attributes)
    pcolor = if haskey(plot, :color) && plot.color[] isa AbstractArray
        if plot.color[] isa AbstractMatrix{<:Colorant}
            delete!(plot_attributes, :colormap)
            delete!(plot_attributes, :colorrange)
        end
        plot.color
    else
        pz
    end
    minfilter = to_value(get(plot, :interpolate, true)) ? :linear : :nearest
    color = Sampler(lift(x -> el32convert(to_color(permutedims(x))), pcolor), minfilter=minfilter)
    normals = Buffer(lift(surface_normals, px, py, pz))
    vertices = GeometryBasics.meta(positions; uv=uv, normals=normals)
    mesh = GeometryBasics.Mesh(vertices, faces)
    return draw_mesh(mscene, mesh, plot_attributes; uniform_color=color, color=false,
                     shading=plot.shading, diffuse=plot.diffuse,
                     specular=plot.specular, shininess=plot.shininess,
                     depth_shift=get(plot, :depth_shift, Observable(0f0)),
                     backlight=plot.backlight,
                     highclip=get_color(plot, :highclip),
                     lowclip=get_color(plot, :lowclip),
                     nan_color=get_color(plot, :nan_color))
end

function create_shader(mscene::Scene, plot::Union{Heatmap, Image})
    image = plot[3]
    color = Sampler(map(x -> el32convert(x'), image);
                    minfilter=to_value(get(plot, :interpolate, false)) ? :linear : :nearest)
    mesh = limits_to_uvmesh(plot)
    plot_attributes = copy(plot.attributes)
    if eltype(color) <: Colorant
        delete!(plot_attributes, :colormap)
        delete!(plot_attributes, :colorrange)
    end

    return draw_mesh(mscene, mesh, plot_attributes;
                     uniform_color=color, color=false,
                     normals=Vec3f(0), shading=false,
                     diffuse=plot.diffuse, specular=plot.specular,
                     colorrange=haskey(plot, :colorrange) ? plot.colorrange : false,
                     shininess=plot.shininess,
                     highclip=get_color(plot, :highclip),
                     lowclip=get_color(plot, :lowclip),
                     nan_color=get_color(plot, :nan_color),
                     backlight=0f0,
                     depth_shift = get(plot, :depth_shift, Observable(0f0)))
end

function create_shader(mscene::Scene, plot::Volume)
    x, y, z, vol = plot[1], plot[2], plot[3], plot[4]
    box = GeometryBasics.mesh(Rect3f(Vec3f(0), Vec3f(1)))
    cam = cameracontrols(mscene)
    model2 = lift(plot.model, x, y, z) do m, xyz...
        mi = minimum.(xyz)
        maxi = maximum.(xyz)
        w = maxi .- mi
        m2 = Mat4f(w[1], 0, 0, 0, 0, w[2], 0, 0, 0, 0, w[3], 0, mi[1], mi[2], mi[3], 1)
        return convert(Mat4f, m) * m2
    end

    modelinv = lift(inv, model2)
    algorithm = lift(x -> Cuint(convert_attribute(x, key"algorithm"())), plot.algorithm)

    return Program(WebGL(), lasset("volume.vert"), lasset("volume.frag"), box,
                   volumedata=Sampler(lift(Makie.el32convert, vol)),
                   modelinv=modelinv, colormap=Sampler(lift(to_colormap, plot.colormap)),
                   colorrange=lift(Vec2f, plot.colorrange),
                   isovalue=lift(Float32, plot.isovalue),
                   isorange=lift(Float32, plot.isorange),
                   absorption=lift(Float32, get(plot, :absorption, Observable(1f0))),
                   algorithm=algorithm,
                   diffuse=plot.diffuse, specular=plot.specular, shininess=plot.shininess,
                   model=model2, depth_shift = get(plot, :depth_shift, Observable(0f0)),
                   # these get filled in later by serialization, but we need them
                   # as dummy values here, so that the correct uniforms are emitted
                   lightposition=Vec3f(1), eyeposition=Vec3f(1), ambient=Vec3f(1))
end
