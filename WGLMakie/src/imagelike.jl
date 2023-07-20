using Makie: el32convert, surface_normals, get_dim

# Somehow we started using Nothing for some colors in Makie,
# but the convert leaves them at nothing -.-
# TODO clean this up in Makie
nothing_or_color(c) = to_color(c)
nothing_or_color(c::Nothing) = RGBAf(0, 0, 0, 1)

lift_or(f, x) = f(x)
lift_or(f, x::Observable) = lift(f, x)

function create_shader(mscene::Scene, plot::Surface)
    # TODO OWN OPTIMIZED SHADER ... Or at least optimize this a bit more ...
    px, py, pz = plot[1], plot[2], plot[3]
    grid(x, y, z, trans, space) = Makie.matrix_grid(p-> apply_transform(trans, p, space), x, y, z)

    positions = Buffer(lift(grid, px, py, pz, transform_func_obs(plot), get(plot, :space, :data)))
    rect = lift(z -> Tesselation(Rect2(0f0, 0f0, 1f0, 1f0), size(z)), pz)
    faces = Buffer(lift(r -> decompose(GLTriangleFace, r), rect))
    uv = Buffer(lift(decompose_uv, rect))
    normals = Buffer(lift(surface_normals, px, py, pz))
    per_vertex = Dict(:positions => positions, :faces => faces, :uv => uv, :normals => normals)

    plot_attributes = copy(plot.attributes)

    uniforms = Dict(:uniform_color => color, :color => false)
    return draw_mesh(mscene, per_vertex, plot, uniforms)
end

function create_shader(mscene::Scene, plot::Union{Heatmap, Image})
    minfilter = to_value(get(plot, :interpolate, false)) ? :linear : :nearest
    mesh = limits_to_uvmesh(plot)

    uniforms = Dict(
        :normals => Vec3f(0),
        :shading => false,
        :diffuse => Vec3f(0),
        :specular => Vec3f(0),
        :shininess => 0.0f0,
        :backlight => 0.0f0,
    )

    return draw_mesh(mscene, mesh, plot, uniforms)
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

    diffuse = lift(x -> convert_attribute(x, Key{:diffuse}()), plot.diffuse)
    specular = lift(x -> convert_attribute(x, Key{:specular}()), plot.specular)
    shininess = lift(x -> convert_attribute(x, Key{:shininess}()), plot.shininess)



    uniforms = Dict{Symbol, Any}(
        :modelinv => modelinv,
        :isovalue => lift(Float32, plot.isovalue),
        :isorange => lift(Float32, plot.isorange),
        :absorption => lift(Float32, get(plot, :absorption, Observable(1.0f0))),
        :algorithm => algorithm,
        :diffuse => diffuse,
        :specular => specular,
        :shininess => shininess,
        :model => model2,
        :depth_shift => get(plot, :depth_shift, Observable(0.0f0)),
        # these get filled in later by serialization, but we need them
        # as dummy values here, so that the correct uniforms are emitted
        :lightposition => Vec3f(1),
        :eyeposition => Vec3f(1),
        :ambient => Vec3f(1),
        :picking => false,
        :object_id => UInt32(0)
    )

    handle_color!(plot, uniforms, nothing, :volumedata; permute_tex=false)
    return Program(WebGL(), lasset("volume.vert"), lasset("volume.frag"), box, uniforms)
end



xy_convert(x::AbstractArray{Float32}, n) = copy(x)
xy_convert(x::AbstractArray, n) = el32convert(x)
xy_convert(x, n) = Float32[LinRange(extrema(x)..., n + 1);]

# TODO, speed up GeometryBasics
function fast_faces(nvertices)
    w, h = nvertices
    idx = LinearIndices(nvertices)
    nfaces = 2 * (w - 1) * (h - 1)
    faces = Vector{GLTriangleFace}(undef, nfaces)
    face_idx = 1
    @inbounds for i in 1:(w - 1)
        for j in 1:(h - 1)
            a, b, c, d = idx[i, j], idx[i + 1, j], idx[i + 1, j + 1], idx[i, j + 1]
            faces[face_idx] = GLTriangleFace(a, b, c)
            face_idx += 1
            faces[face_idx] = GLTriangleFace(a, c, d)
            face_idx += 1
        end
    end
    return faces
end

# TODO, speed up GeometryBasics
function fast_uv(nvertices)
    xrange, yrange = LinRange.((0, 1), (1, 0), nvertices)
    return [Vec2f(x, y) for y in yrange for x in xrange]
end

function limits_to_uvmesh(plot)
    px, py, pz = plot[1], plot[2], plot[3]
    px = map((x, z) -> xy_convert(x, size(z, 1)), px, pz; ignore_equal_values=true)
    py = map((y, z) -> xy_convert(y, size(z, 2)), py, pz; ignore_equal_values=true)
    # Special path for ranges of length 2 which
    # can be displayed as a rectangle
    t = Makie.transform_func_obs(plot)[]

    # TODO, this branch is only hit by Image, but not for Heatmap with stepranges
    # because convert_arguments converts x/y to Vector{Float32}
    if px[] isa StepRangeLen && py[] isa StepRangeLen && Makie.is_identity_transform(t)
        rect = lift(px, py) do x, y
            xmin, xmax = extrema(x)
            ymin, ymax = extrema(y)
            return Rect2(xmin, ymin, xmax - xmin, ymax - ymin)
        end
        positions = Buffer(lift(rect -> decompose(Point2f, rect), rect))
        faces = Buffer(lift(rect -> decompose(GLTriangleFace, rect), rect))
        uv = Buffer(lift(decompose_uv, rect))
    else
        function grid(x, y, trans, space)
            return Makie.matrix_grid(p -> apply_transform(trans, p, space), x, y, zeros(length(x), length(y)))
        end
        resolution = lift((x, y) -> (length(x), length(y)), px, py; ignore_equal_values=true)
        positions = Buffer(lift(grid, px, py, t, get(plot, :space, :data)))
        faces = Buffer(lift(fast_faces, resolution))
        uv = Buffer(lift(fast_uv, resolution))
    end
    vertices = GeometryBasics.meta(positions; uv=uv)
    return Dict(:positions => positions, :faces => faces, :uv => uv)
end
