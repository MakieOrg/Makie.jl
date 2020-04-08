

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

function draw_mesh(jsctx, jsscene, mscene::Scene, mesh, name, plot; uniforms...)
    uniforms = Dict(uniforms)
    if haskey(uniforms, :lightposition)
        eyepos = getfield(mscene.camera, :eyeposition)
        uniforms[:lightposition] = lift(uniforms[:lightposition], eyepos, typ=Vec3f0) do pos, eyepos
            ifelse(pos == :eyeposition, eyepos, pos)::Vec3f0
        end
    end

    program = Program(
        WebGL(),
        lasset("mesh.vert"),
        lasset("mesh.frag"),
        VertexArray(mesh);
        uniforms...
    )

    three_geom = wgl_convert(mscene, jsctx, program)
    update_model!(three_geom, plot)
    three_geom.name = string(objectid(plot))
    jsscene.add(three_geom)
end


function limits_to_uvmesh(plot)
    px, py = plot[1], plot[2]
    rectangle = lift(px, py) do x, y
        xmin, xmax = extrema(x)
        ymin, ymax = extrema(y)
        Rect2D(xmin, ymin, xmax - xmin, ymax - ymin)
    end
    positions = Buffer(lift(rectangle) do rect
        ps = decompose(Point2f0, rect)
        reinterpret(GeometryBasics.Point{2, Float32}, ps)
    end)
    faces = Buffer(lift(rectangle) do rect
        tris = decompose(GLTriangleFace, rect)
        convert(Vector{GeometryBasics.TriangleFace{Cuint}}, tris)
    end)
    uv = Buffer(lift(rectangle) do rect
        decompose(UV{Float32}, rect)
    end)
    vertices = GeometryBasics.meta(
        positions; texturecoordinates = uv
    )
    mesh = GeometryBasics.Mesh(vertices, faces)
end

function draw_js(jsctx, jsscene, mscene::Scene, plot::Surface)
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
        tris = decompose(GLTriangleFace, Rect2D(0f0, 0f0, 1f0, 1f0), size(z))
        convert(Vector{GeometryBasics.TriangleFace{Cuint}}, tris)
    end)
    uv = Buffer(lift(pz) do z
        decompose(UV{Float32}, Rect2D(0f0, 0f0, 1f0, 1f0), size(z))
    end)
    pcolor = if haskey(plot, :color) && plot.color[] isa AbstractArray
        plot.color
    else
        pz
    end
    color = Sampler(lift(
        (args...)-> (array2color(args...)'),
        pcolor, plot.colormap, plot.colorrange
    ))
    normals = Buffer(lift(surface_normals, px, py, pz))
    vertices = GeometryBasics.meta(
        positions; texturecoordinates = uv, normals = normals
    )
    mesh = GeometryBasics.Mesh(vertices, faces)

    draw_mesh(jsctx, jsscene, mscene, mesh, "surface", plot;
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

function draw_js(jsctx, jsscene, mscene::Scene, plot::Union{Heatmap, Image})
    image = plot[3]
    colored = lift(
        (args...)-> array2color(args...)',
        image, plot.colormap, get(plot, :colorrange, nothing)
    )
    color = Sampler(
        colored,
        minfilter = to_value(get(plot, :interpolate, false)) ? :linear : :nearest
    )
    mesh = limits_to_uvmesh(plot)
    draw_mesh(jsctx, jsscene, mscene, mesh, "heatmap", plot;
        uniform_color = color,
        color = Vec4f0(0),
        normals = Vec3f0(0),
        shading = false,
        ambient = plot.ambient,
        diffuse = plot.diffuse,
        specular = plot.specular,
        shininess = plot.shininess,
        lightposition = plot.lightposition
    )
end


function draw_js(jsctx, jsscene, mscene::Scene, plot::Volume)
    x, y, z, vol = plot[1], plot[2], plot[3], plot[4]
    box = ShaderAbstractions.VertexArray(GLPlainMesh(FRect3D(Vec3f0(0), Vec3f0(1))))
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

    program = Program(
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
        absorption = lift(Float32, plot.absorption),

        algorithm = algorithm,
        eyeposition = eyepos,
        ambient = plot.ambient,
        diffuse = plot.diffuse,
        specular = plot.specular,
        shininess = plot.shininess,
        lightposition = lightposition,
    )

    debug_shader("volume", program)

    three_geom = wgl_convert(mscene, jsctx, program)
    three_geom.matrixAutoUpdate = false
    three_geom.matrix.set(model2[]'...)
    on(model2) do model
        three_geom.matrix.set((model')...)
    end
    three_geom.material.side = jsctx.FrontSide
    jsscene.add(three_geom)
end
