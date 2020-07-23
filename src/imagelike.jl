
get_dim(x, ind, dim, size) = get_dim(LinRange(extrema(x)..., size[dim]), ind, dim, size)
get_dim(x::AbstractVector, ind, dim, size) = x[Tuple(ind)[dim]]
get_dim(x::AbstractMatrix, ind, dim, size) = x[ind]

function surface_normals(x, y, z)
    vec(map(CartesianIndices(z)) do i
        i1, imax = CartesianIndex(1, 1), CartesianIndex(size(z))
        ci(x, y) = min(max(i + CartesianIndex(x, y), i1), imax)
        offsets = (ci(-1, -1), ci(1, -1), ci(-1, 1), ci(1, 1))
        normalize(mapreduce(+, init = Vec3f0(0), offsets) do off
            s = size(z)
            Vec3f0(get_dim(x, off, 1, s), get_dim(y, off, 2, s), z[off])
        end)
    end)
end

function draw_mesh(mscene::Scene, mesh, plot; uniforms...)
    uniforms = Dict(uniforms)

    if haskey(uniforms, :lightposition)
        eyepos = getfield(mscene.camera, :eyeposition)
        uniforms[:lightposition] = lift(uniforms[:lightposition], eyepos, typ=Vec3f0) do pos, eyepos
            ifelse(pos == :eyeposition, eyepos, pos)::Vec3f0
        end
    end

    colormap = if haskey(plot, :colormap)
        uniforms[:colormap] = Sampler(lift(x->AbstractPlotting.el32convert(to_colormap(x)), plot.colormap))
    end
    colorrange = if haskey(plot, :colorrange)
        uniforms[:colorrange] = lift(Vec2f0, plot.colorrange)
    end

    get!(uniforms, :colormap, false)
    get!(uniforms, :colorrange, false)
    get!(uniforms, :color, false)
    get!(uniforms, :model, plot.model)

    return Program(
        WebGL(),
        lasset("mesh.vert"),
        lasset("mesh.frag"),
        mesh;
        uniforms...
    )
end

function limits_to_uvmesh(plot)
    px, py = plot[1], plot[2]
    rectangle = lift(px, py) do x, y
        xmin, xmax = extrema(x)
        ymin, ymax = extrema(y)
        Rect2D(xmin, ymin, xmax - xmin, ymax - ymin)
    end

    positions = Buffer(lift(rectangle) do rect
        return decompose(Point2f0, rect)
    end)

    faces = Buffer(lift(rectangle) do rect
        return decompose(GLTriangleFace, rect)
    end)

    uv = Buffer(lift(decompose_uv, rectangle))

    vertices = GeometryBasics.meta(positions; uv=uv)

    return GeometryBasics.Mesh(vertices, faces)
end

function create_shader(mscene::Scene, plot::Surface)
    # TODO OWN OPTIMIZED SHADER ... Or at least optimize this a bit more ...
    px, py, pz = plot[1], plot[2], plot[3]

    positions = Buffer(lift(px, py, pz) do x, y, z
        vec(map(CartesianIndices(z)) do i
            GeometryBasics.Point{3, Float32}(
                get_dim(x, i, 1, size(z)),
                get_dim(y, i, 2, size(z)),
                z[i]
            )
        end)
    end)

    faces = Buffer(lift(pz) do z
        return decompose(GLTriangleFace, Rect2D(0f0, 0f0, 1f0, 1f0), size(z))
    end)

    uv = Buffer(lift(pz) do z
        decompose_uv(Tesselation(Rect2D(0f0, 0f0, 1f0, 1f0), size(z)))
    end)

    pcolor = if haskey(plot, :color) && plot.color[] isa AbstractArray
        plot.color
    else
        pz
    end

    color = Sampler(
        map(x-> x', pcolor),
        minfilter = to_value(get(plot, :interpolate, false)) ? :linear : :nearest
    )

    normals = Buffer(lift(surface_normals, px, py, pz))

    vertices = GeometryBasics.meta(
        positions; uv=uv, normals=normals
    )

    mesh = GeometryBasics.Mesh(vertices, faces)

    return draw_mesh(mscene, mesh, plot;
        uniform_color = color,
        color = Vec4f0(0),
        shading = plot.shading,
        ambient = plot.ambient,
        diffuse = plot.diffuse,
        specular = plot.specular,
        shininess = plot.shininess,
        lightposition = plot.lightposition
    )
end

function create_shader(mscene::Scene, plot::Union{Heatmap, Image})
    image = plot[3]
    color = Sampler(
        map(x-> x', image),
        minfilter = to_value(get(plot, :interpolate, false)) ? :linear : :nearest
    )
    mesh = limits_to_uvmesh(plot)

    return draw_mesh(mscene, mesh, plot;
        uniform_color = color,
        color = Vec4f0(0),
        normals = Vec3f0(0),
        shading = false,
        ambient = plot.ambient,
        diffuse = plot.diffuse,
        specular = plot.specular,
        colorrange = haskey(plot, :colorrange) ? plot.colorrange : false,
        shininess = plot.shininess,
        lightposition = plot.lightposition
    )
end

function create_shader(mscene::Scene, plot::Volume)
    x, y, z, vol = plot[1], plot[2], plot[3], plot[4]
    box = GeometryBasics.mesh(FRect3D(Vec3f0(0), Vec3f0(1)))
    cam = cameracontrols(mscene)
    model2 = lift(plot.model, x, y, z) do m, xyz...
        mi = minimum.(xyz)
        maxi = maximum.(xyz)
        w = maxi .- mi
        m2 = Mat4f0(
            w[1], 0, 0, 0,
            0, w[2], 0, 0,
            0, 0, w[3], 0,
            mi[1], mi[2], mi[3], 1
        )
        return convert(Mat4f0, m) * m2
    end

    modelinv = lift(inv, model2)
    algorithm = lift(x-> Cuint(convert_attribute(x, key"algorithm"())), plot.algorithm)

    eyepos = getfield(mscene.camera, :eyeposition)

    lightposition = lift(plot.lightposition, eyepos, typ=Vec3f0) do pos, eyepos
        ifelse(pos == :eyeposition, eyepos, pos)::Vec3f0
    end
    return Program(
        WebGL(),
        lasset("volume.vert"),
        lasset("volume.frag"),
        box,

        volumedata = Sampler(lift(AbstractPlotting.el32convert, vol)),
        modelinv = modelinv,
        colormap = Sampler(lift(to_colormap, plot.colormap)),
        colorrange = lift(Vec2f0, plot.colorrange),
        isovalue = lift(Float32, plot.isovalue),
        isorange = lift(Float32, plot.isorange),
        absorption = lift(Float32, get(plot, :absorption, Observable(1f0))),

        algorithm = algorithm,
        eyeposition = eyepos,
        ambient = plot.ambient,
        diffuse = plot.diffuse,
        specular = plot.specular,
        shininess = plot.shininess,
        lightposition = lightposition,
        model = model2
    )
end
