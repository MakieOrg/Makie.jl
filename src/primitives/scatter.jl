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

function available_marker_symbols()
    println("Marker Symbols:")
    for (k, v) in _marker_map
        println("    ", k, " => ", v)
    end
end

"""
Sprite marker. Allowed values:
 * GeometryTypes.Circle
 * Symbol. Available options can be printed with `available_marker_symbols()`
 * Any unicode Char
 * A shape/polygon
 * An Image
 * A distancefield (Matrix{Float}-> annotating the distance from a contour with negative distances being outside and positves inside)/
 * An array of any of the above, to give each marker it's own shape
"""
to_spritemarker(::Type{Circle}) = Circle(Point2f0(0), 1f0)
to_spritemarker(::Type{Rectangle}) = HyperRectangle(Vec2f0(0), Vec2f0(1))

to_spritemarker(marker::Char) = marker
to_spritemarker(marker::Matrix{<: AbstractFloat}) = Float32.(marker)
to_spritemarker(marker::Image) = to_image(marker)

function to_spritemarker(marker::Symbol)
    if haskey(_marker_map, marker)
        return to_spritemarker(_marker_map[marker])
    else
        warn("Unsupported marker: $marker, using ● instead")
        return '●'
    end
end

function to_spritemarker(shape::Shape)
    points = Point2f0[GeometryTypes.Vec{2, Float32}(p) for p in zip(shape.x, shape.y)]
    bb = GeometryTypes.AABB(points)
    mini, maxi = minimum(bb), maximum(bb)
    w3 = maxi-mini
    origin, width = Point2f0(mini[1], mini[2]), Point2f0(w3[1], w3[2])
    map!(p -> ((p - origin) ./ width) - 0.5f0, points, points) # normalize and center
    GeometryTypes.GLNormalMesh(points)
end
# create a marker/shape type
to_spritemarker(marker::Vector{Char}) = String(marker)
function to_spritemarker(marker::Vector)
    marker = map(marker) do sym
        to_spritemarker(sym)
    end
    if isa(marker, Vector{Char})
        to_spritemarker(marker)
    else
        marker
    end
end

"""
Billboard attribute to always have a primitive face the camera.
Can be used for rotation.
"""
immutable Billboard end

function to_static_vec(x::AbstractArray)
    Vec(ntuple(length(x)) do i
        x[i]
    end)
end

to_static_array(x::SVector) = Vec(x)
to_static_array(x::NTuple{N}) = Vec(x)

function to_static_array(x::AbstractArray{T}) where T <: Union{Tuple, SVector, AbstractArray}
    to_static_array.(x)
end

to_rotations(x::Vector) = to_static_array(x)


@default function sprite_defaults(scene, kw_args)
    positions = to_positions(positions)

    # Either you give a color, or a colormap.
    # For a colormap, you'll also need intensities
    xor(
        begin
            color = to_color(color)
        end,
        begin
            colormap = to_colormap(colormap)
            intensity = to_intensity(intensity)
            colornorm = to_colornorm(colornorm, intensity)
        end
    )
    marker = to_marker(marker)

    stroke_color = to_color(stroke_color)
    stroke_thickness = stroke_thickness::Float32

    glow_color = to_color(stroke_color)
    glow_thickness = stroke_thickness::Float32

    scales = to_scale(scales)

    rotations = to_rotations(rotations)
end

function expand_kwargs(kw_args)
    # TODO get in all the shorthands from Plots.jl
    Dict{Symbol, Any}(kw_args)
end


function insert_scene!(scene, name, viz, attributes)
    name = unique_predictable_name(scene, :scatter)
    viz.uniforms = attributes
    scene.data[name] = attributes
    _view(viz, scene[:screen])
end

function scatter(points; kw_args...)
    kw_args = expand_kwargs(kw_args)
    scene = get_global_scene()
    kw_args[:positions] = to_signal(points)
    attributes, attribute_syms = if is_sprites(kw_args)
        sprite_defaults(scene, kw_args)
    else
        meshparticle_defaults(scene, kw_args)
    end
    main = (attributes[:marker], attributes[:position])
    viz = visualize(main, Style(:default), attributes).children[]
    insert_scene!(scene, :scatter, viz, attributes)
    viz
end
