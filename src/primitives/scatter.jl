
const _marker_map = KW(
    :rect => '■',
    :star5 => '★',
    :diamond => '◆',
    :hexagon => '⬢',
    :cross => '✚',
    :xcross => '❌',
    :utriangle => '▲',
    :dtriangle => '▼',
    :ltriangle => '◀',
    :rtriangle => '▶',
    :pentagon => '⬟',
    :octagon => '⯄',
    :star4 => '✦',
    :star6 => '🟋',
    :star8 => '✷',
    :vline => '┃',
    :hline => '━',
    :+ => '+',
    :x => 'x',
    :circle => '●'
)
function extract_marker(d, kw_args)
    dim = Plots.is3d(d) ? 3 : 2
    scaling = dim == 3 ? 0.003 : 2
    if haskey(d, :markershape)
        shape = d[:markershape]
        shape = marker(shape)
        if shape != :none
            kw_args[:primitive] = shape
        end
    end
    dim = isa(kw_args[:primitive], GLVisualize.Sprites) ? 2 : 3
    if haskey(d, :markersize)
        msize = d[:markersize]
        kw_args[:scale] = to_vec(GeometryTypes.Vec{dim, Float32}, msize .* scaling)
    end
    if haskey(d, :offset)
        kw_args[:offset] = d[:offset]
    end
    # get the color
    key = :markercolor
    haskey(d, key) || return
    c = color(d[key])
    if isa(c, AbstractVector) && d[:marker_z] != nothing
        extract_colornorm(d, kw_args)
        kw_args[:color] = nothing
        kw_args[:color_map] = c
        kw_args[:intensity] = convert(Vector{Float32}, d[:marker_z])
    else
        kw_args[:color] = c
    end
    key = :markerstrokecolor
    haskey(d, key) || return
    c = color(d[key])
    if c != nothing
        if !(isa(c, Colorant) || (isa(c, Vector) && eltype(c) <: Colorant))
            error("Stroke Color not supported: $c")
        end
        kw_args[:stroke_color] = c
        kw_args[:stroke_width] = Float32(d[:markerstrokewidth])
    end
end

function marker(shape)
    shape
end

function marker(shape::Shape)
    points = Point2f0[GeometryTypes.Vec{2, Float32}(p) for p in zip(shape.x, shape.y)]
    bb = GeometryTypes.AABB(points)
    mini, maxi = minimum(bb), maximum(bb)
    w3 = maxi-mini
    origin, width = Point2f0(mini[1], mini[2]), Point2f0(w3[1], w3[2])
    map!(p -> ((p - origin) ./ width) - 0.5f0, points, points) # normalize and center
    GeometryTypes.GLNormalMesh(points)
end
# create a marker/shape type
function marker(shape::Vector{Symbol})
    String(map(shape) do sym
        get(_marker_map, sym, '●')
    end)
end

function marker(shape::Symbol)
    if shape == :rect
        GeometryTypes.HyperRectangle(Vec2f0(0), Vec2f0(1))
    elseif shape == :circle || shape == :none
        GeometryTypes.HyperSphere(Point2f0(0), 1f0)
    elseif haskey(_marker_map, shape)
        _marker_map[shape]
    elseif haskey(_shapes, shape)
        marker(_shapes[shape])
    else
        error("Shape $shape not supported by GLVisualize")
    end
end

function scatter(points; kw_args...)
    scene = get_global_scene()
    kw_args = map(x-> (x[1], to_signal(x[2])), kw_args)
    points = to_signal(points)
    viz = visualize((Circle(Point2f0(0), 10f0), points); kw_args...).children[]
    name = unique_predictable_name(scene, :scatter)
    attributes = map(viz.uniforms) do kv
        if kv[1] in (:preferred_camera, :fxaa)
            # this is silly, the system needs a rework. But for now we special case this!
            kv[1] => kv[2] # make sure all are signal
        else
            kv[1] => to_signal(kv[2])
        end
    end
    viz.uniforms = attributes
    scene.data[name] = attributes
    _view(viz, scene[:screen])
    viz
end
