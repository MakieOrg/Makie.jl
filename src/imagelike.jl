


get_dim(x::AbstractVector, ind, dim) = x[Tuple(ind)[dim]]
get_dim(x::AbstractMatrix, ind, dim) = x[ind]
function surface_normals(x, y, z)
    vec(map(CartesianIndices(z)) do i
        i1, imax = CartesianIndex(1, 1), CartesianIndex(size(z))
        ci(x, y) = min(max(i + CartesianIndex(x, y), i1), imax)
        offsets = (ci(-1, -1), ci(1, -1), ci(-1, 1), ci(1, 1))
        normalize(mapreduce(+, init = Vec3f0(0), offsets) do off
            Vec3f0(get_dim(x, off, 1), get_dim(y, off, 2), z[off])
        end)
    end)
end

function draw_mesh(jsscene, mscene::Scene, mesh, name, plot; uniforms...)
    program = Program(
        WebGL(),
        lasset("mesh.vert"),
        lasset("mesh.frag"),
        VertexArray(mesh);
        uniforms...
    )
    write(joinpath(@__DIR__, "..", "debug", "$(name).vert"), program.vertex_source)
    write(joinpath(@__DIR__, "..", "debug", "$(name).frag"), program.fragment_source)
    three_geom = wgl_convert(jsscene, program)
    update_model!(three_geom, plot)
    three_geom.name = name
    jsscene.add(three_geom)
end


function draw_js(jsscene, mscene::Scene, plot::Surface)
    # TODO OWN OPTIMIZED SHADER ... Or at least optimize this a bit more ...
    px, py, pz = plot[1], plot[2], plot[3]
    positions = Buffer(lift(px, py, pz) do x, y, z
        vec(map(CartesianIndices(z)) do i
            GeometryBasics.Point{3, Float32}(
                get_dim(x, i, 1),
                get_dim(y, i, 2),
                z[i]
            )
        end)
    end)
    faces = Buffer(lift(pz) do z
        tris = decompose(GLTriangle, SimpleRectangle(0f0, 0f0, 1f0, 1f0), size(z))
        convert(Vector{GeometryBasics.TriangleFace{Cuint}}, tris)
    end)
    uv = Buffer(lift(pz) do z
        decompose(UV{Float32}, SimpleRectangle(0f0, 0f0, 1f0, 1f0), size(z))
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

    draw_mesh(jsscene, mscene, mesh, "surface", plot;
        uniform_color = color,
        color = Vec4f0(0),
        shading = plot.shading,
    )
end


function draw_js(jsscene, mscene::Scene, plot::Image)
    px, py, image = plot[1], plot[2], plot[3]
    rectangle = lift(px, py) do x, y
        xmin, xmax = extrema(x)
        ymin, ymax = extrema(y)
        SimpleRectangle(xmin, ymin, xmax - xmin, ymax - ymin)
    end
    positions = Buffer(lift(rectangle) do rect
        ps = decompose(Point2f0, rect)
        reinterpret(GeometryBasics.Point{2, Float32}, ps)
    end)
    faces = Buffer(lift(rectangle) do rect
        tris = decompose(GLTriangle, rect)
        convert(Vector{GeometryBasics.TriangleFace{Cuint}}, tris)
    end)
    uv = Buffer(lift(rectangle) do rect
        decompose(UV{Float32}, rect)
    end)

    color = Sampler(lift(x-> x', image))
    vertices = GeometryBasics.meta(
        positions; texturecoordinates = uv
    )
    mesh = GeometryBasics.Mesh(vertices, faces)

    draw_mesh(jsscene, mscene, mesh, "image", plot;
        uniform_color = color,
        color = Vec4f0(0),
        normals = Vec3f0(0),
        shading = false,
    )
end
