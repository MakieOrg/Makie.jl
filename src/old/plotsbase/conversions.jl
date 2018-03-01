#to_([a-z0-9_]+)\(b, ([::a-zA-Z0-9\.\{\}_]+)\) where
const VecLike{N, T} = Union{NTuple{N, T}, StaticVector{N, T}}


"""
Any GLAbstraction.Camera
"""
function to_camera(b, x::GLAbstraction.Camera)
    x
end
"""
Takes a camera symbol, one of :auto, :perspective, :orthographic, :pixel
"""
function to_camera(b, x::Symbol)
    if x in (:auto, :perspective, :orthographic, :pixel)
        return x
    else
        error(":$x is not a supported camera symbol. Try one of :auto, :perspective, :orthographic, :pixel")
    end
end










"""
Converts a Vec like to a position (Point)
"""
function to_position(b, x::VecLike{N}) where N
    Point{N, Float32}(x)
end

function to_position(b, x, y)
    Point{2, Float32}(to_absolute(b, x), to_absolute(b, y))
end


"""
    to_array(b, arraylike)
`AbstractArray`
"""
to_array(b, x) = collect(x)

"""
    to_scalefunc(b, x)
`Function`
"""
to_scalefunc(b, x) = x # TODO implement it

"""
    to_text(b, x)
All text
"""
to_text(b, x) = x# TODO implement it

to_string(scene, x::String) = x
to_string(scene, x) = string(x)


"""
Text align, e.g. :
"""
to_textalign(b, x::Tuple{Symbol, Symbol}) = Vec2f0(alignment2num.(x))
to_textalign(b, x::Vec2f0) = x

"""
    to_colornorm(b, norm, intensity)
anything that can be converted to `Vec2f0` (e.g. `Tuple`, `Vector`)
"""
to_colornorm(b, norm, intensity) = Vec2f0(norm)

"""
If colornorm is `nothing` will default to calculate the extrema from `intensity`
"""
function to_colornorm(b, norm::Void, intensity)
    nan_extrema(intensity)
end

"""
`AbstractArray`
"""
to_intensity(b, x::AbstractArray) = x # TODO implement

"""
    to_surface(b, x::Range)
`Range`
"""
to_surface(b, x::Range) = x
"""
    to_surface(b, arraylike)
Anything that can be converted to Matrix/Vector of Float32
"""
to_surface(b, x) = Float32.(x)


const Image = Matrix{T} where T <: Colorant

const _marker_map = Dict(
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


"""
    available_marker_symbols()
Displays all available marker symbols
"""
function available_marker_symbols()
    println("Marker Symbols:")
    for (k, v) in _marker_map
        println("    ", k, " => ", v)
    end
end


"""
    to_spritemarker(b, x::Circle)
`GeometryTypes.Circle(Point2(...), radius)`
"""
to_spritemarker(b, x::Circle) = x

"""
    to_spritemarker(b, ::Type{Circle})
`Type{GeometryTypes.Circle}`
"""
to_spritemarker(b, ::Type{Circle}) = Circle(Point2f0(0), 1f0)
"""
    to_spritemarker(b, ::Type{Rectangle})
`Type{GeometryTypes.Rectangle}`
"""
to_spritemarker(b, ::Type{Rectangle}) = HyperRectangle(Vec2f0(0), Vec2f0(1))
"""
    to_spritemarker(b, marker::Char)
Any `Char`, including unicode
"""
to_spritemarker(b, marker::Char) = marker

"""
Matrix of AbstractFloat will be interpreted as a distancefield (negative numbers outside shape, positive inside)
"""
to_spritemarker(b, marker::Matrix{<: AbstractFloat}) = Float32.(marker)

"""
Any AbstractMatrix{<: Colorant} or other image type
"""
to_spritemarker(b, marker::Image) = to_image(marker)

"""
A `Symbol` - Available options can be printed with `available_marker_symbols()`
"""
function to_spritemarker(b, marker::Symbol)
    if haskey(_marker_map, marker)
        return to_spritemarker(b, _marker_map[marker])
    else
        warn("Unsupported marker: $marker, using ● instead")
        return '●'
    end
end


to_spritemarker(b, marker::String) = marker
to_spritemarker(b, marker::AbstractVector{Char}) = String(marker)

"""
Vector of anything that is accepted as a single marker will give each point it's own marker.
Note that it needs to be a uniform vector with the same element type!
"""
function to_spritemarker(b, marker::AbstractVector)
    marker = map(marker) do sym
        to_spritemarker(b, sym)
    end
    if isa(marker, AbstractVector{Char})
        String(marker)
    else
        marker
    end
end


# function to_spritemarker(shape::Shape)
#     points = Point2f0[GeometryTypes.Vec{2, Float32}(p) for p in zip(shape.x, shape.y)]
#     bb = GeometryTypes.AABB(points)
#     mini, maxi = minimum(bb), maximum(bb)
#     w3 = maxi-mini
#     origin, width = Point2f0(mini[1], mini[2]), Point2f0(w3[1], w3[2])
#     map!(p -> ((p - origin) ./ width) - 0.5f0, points, points) # normalize and center
#     GeometryTypes.GLNormalMesh(points)
# end
# create a marker/shape type

"""
    to_static_vec(b, x)
`AbstractArray`
"""
function to_static_vec(b, x::AbstractArray)
    Vec(ntuple(length(x)) do i
        x[i]
    end)
end

"""
Any `StaticVector`
"""
to_static_vec(b, x::StaticVector) = Vec(x)

"""
`NTuple`
"""
to_static_vec(b, x::NTuple{N}) where N = Vec(x)

"""
Abstract array of which the elements can be converted to vec
"""
function to_static_vec(b, x::AbstractArray{T}) where T <: Union{Tuple, SVector, AbstractArray}
    to_static_vec.(b, x)
end

"""
    to_rotations(b, x)
`Billboard()` for a rotation that will always face the camera
"""
to_rotations(b, x::Billboard) = x

"""
Any AbstractArray which elements can be converted to Vec4 (as a quaternion x, y, z, w)
"""
to_rotations(b, x::AbstractVector) = to_static_vec(b, x)

"""
    to_markersize2d(b, x)
Anything that can be converted to `Vec2f0` for x, y scale
"""
to_markersize2d(b, x::Number) = Vec2f0(x)
to_markersize2d(b, x::Tuple) = Vec2f0(x)
to_markersize2d(b, x::StaticVector) = Vec2f0(x)
to_markersize2d(b, x::AbstractVector) = Vec2f0.(x)


# TODO generically implement these to share implementation with to_position etc
"""
    to_markersize3d(b, x)
Anything that can be converted to `Vec3f0` for x, y, z scale
"""
to_markersize3d(b, x::Number) = Vec3f0(x)
to_markersize3d(b, x::Tuple) = Vec3f0(x)
to_markersize3d(b, x::StaticVector) = Vec3f0(x)
to_markersize3d(b, x::AbstractVector) = Vec3f0.(x)

"""
    to_linestyle(b, x)
`Nothing` for no style
"""
to_linestyle(b, x::Void) = x

"""
`AbstractVector{<:AbstractFloat}` for denoting sequences of fill/nofill. E.g.
[0.5, 0.8, 1.2] will result in 0.5 filled, 0.3 unfilled, 0.4 filled. 1.0 unit is one linewidth!
"""
to_linestyle(b, A::AbstractVector) = A
"""
A `Symbol` equal to `:dash`, `:dot`, `:dashdot`, `:dashdotdot`
"""
function to_linestyle(b, ls::Symbol)
    return if ls == :dash
        [0.0, 1.0, 2.0, 3.0, 4.0]
    elseif ls == :dot
        tick, gap = 1/2, 1/4
        [0.0, tick, tick+gap, 2tick+gap, 2tick+2gap]
    elseif ls == :dashdot
        dtick, dgap = 1.0, 1.0
        ptick, pgap = 1/2, 1/4
        [0.0, dtick, dtick+dgap, dtick+dgap+ptick, dtick+dgap+ptick+pgap]
    elseif ls == :dashdotdot
        dtick, dgap = 1.0, 1.0
        ptick, pgap = 1/2, 1/4
        [0.0, dtick, dtick+dgap, dtick+dgap+ptick, dtick+dgap+ptick+pgap, dtick+dgap+ptick+pgap+ptick,  dtick+dgap+ptick+pgap+ptick+pgap]
    else
        error("Unkown line style: $linestyle. Available: :dash, :dot, :dashdot, :dashdotdot or a sequence of numbers enumerating the next transparent/opaque region")
    end
end

"""
    to_normals(b, x)
Vector{Normal{3}}
"""
to_normals(b, x) = x

"""
    to_faces(b, x)
Any array of NTuple/GeometryTypes.Face
"""
function to_faces(b, x::AbstractVector{NTuple{N, TI}}) where {N, TI <: Integer}
    to_faces(reinterpret(Face{N, TI}, x))
end

function to_faces(b, faces::AbstractVector{<: Face})
    decompose(GLTriangle, faces)
end
function to_faces(b, faces::AbstractVector{GLTriangle})
    faces
end

function to_faces(b, x::Void)
    x
end

function to_faces(b, x::Vector{Int})
    if length(x) % 3 != 0
        error("Int indices need to represent triangles, therefore need to be a multiple of three. Found: $(length(x))")
    end
    reinterpret(GLTriangle, UInt32.(x .- 1))
end


"""
    to_mesh(b, meshlike)
`AbstractMesh`
"""
function to_mesh(b, mesh::AbstractMesh)
    mesh
end

function to_mesh(b, geom::GeometryPrimitive)
    GLNormalMesh(geom)
end

function to_mesh(b, verts, faces, colors, attribute_id::Node{Void})
    lift_node(verts, faces) do v, f
        GLPlainMesh(v, f)
    end
end
function to_mesh(b, verts, faces, colors::Node{<:Colorant}, attribute_id::Node{Void})
    lift_node(verts, faces) do v, f
        GLNormalMesh(vertices = v, faces = f)
    end
end

function to_mesh(b, verts, faces, colors::AbstractVector, attribute_id::Node{Void})
    lift_node(verts, faces, colors) do v, f, c
        if length(c) != length(v)
            error("You need one color per vertex. Found: $(length(v)) vertices, and $(length(c)) colors")
        end
        GLNormalVertexcolorMesh(vertices = v, faces = f, color = c)
    end
end
function to_mesh(verts, faces, colors::AbstractVector, attribute_id::AbstractVector)
    lift_node(verts, faces, colors, attribute_id) do v, f, c, id
        if length(id) != length(v)
            error("You need one attribute per vertex. Found: $(length(v)) vertices, and $(length(id)) attributes")
        end
        GLNormalAttributeMesh(
            vertices = v, faces = f,
            attributes = c, attribute_id = id
        )
    end
end

"""
    to_attribut_id(b, x)
Index into Mesh attributes, Vector{Integer}
"""
to_attribut_id(backend, x) = x



"""
    to_float(b, x)
Any Object convertible to Floatingpoint
"""
to_float(b, x) = Float32(x)
#
to_color(c) = to_color(current_backend[], c)

"""
    to_color(b, x)
`Colors.Colorants`
"""
to_color(b, c::Colorant) = RGBA{Float32}(c)
"""
A `Symbol` naming a color, e.g. `:black`
"""
to_color(b, c::Symbol) = to_color(b, string(c))
"""
A `String` naming a color, e.g. `:black` or html style `#rrggbb`
"""
to_color(b, c::String) = parse(RGBA{Float32}, c)
to_color(b, c::UniqueColorIter) = to_color(b, next(c))

"""
A Tuple or Array with elements that `to_color` accepts.
If Array is a Matrix it will get interpreted as an Image
"""
to_color(b, c::Union{Tuple, AbstractArray}) = to_color.(b, c)


"""
Tuple{<: ColorLike, <: AbstractFloat} for a transparent color
"""
to_color(b, c::Tuple{T, F}) where {T, F <: AbstractFloat} = RGBAf0(Colors.color(to_color(b, c[1])), c[2])


const colorbrewer_names = Symbol[
    # All sequential color schemes can have between 3 and 9 colors. The available sequential color schemes are:
    :Blues,
    :Oranges,
    :Greens,
    :Reds,
    :Purples,
    :Greys,
    :OrRd,
    :GnBu,
    :PuBu,
    :PuRd,
    :BuPu,
    :BuGn,
    :YlGn,
    :RdPu,
    :YlOrBr,
    :YlGnBu,
    :YlOrRd,
    :PuBuGn,

    # All diverging color schemes can have between 3 and 11 colors. The available diverging color schemes are:
    :Spectral,
    :RdYlGn,
    :RdBu,
    :PiYG,
    :PRGn,
    :RdYlBu,
    :BrBG,
    :RdGy,
    :PuOr,

    #The number of colors a qualitative color scheme can have depends on the scheme. The available qualitative color schemes are:
    :Name,
    :Set1,
    :Set2,
    :Set3,
    :Dark2,
    :Accent,
    :Paired,
    :Pastel1,
    :Pastel2
]

"""
    available_gradients()

Prints all available gradient names
"""
function available_gradients()
    println("Gradient Symbol/Strings:")
    for name in colorbrewer_names
        println("    ", name)
    end
end

"""
    to_colormap(b, x)
An `AbstractVector{T}` with any object that [`to_color`](@ref) accepts
"""
to_colormap(b, cm::AbstractVector) = RGBAf0.(cm)

"""
Tuple(A, B) or Pair{A, B} with any object that [`to_color`](@ref) accepts
"""
function to_colormap(b, cs::Union{Tuple, Pair})
    [to_color.(cs)...]
end

to_colormap(val) = to_colormap(current_backend[], val)

"""
A Symbol/String naming the gradient. For more on what names are available please see: `available_gradients()
"""
function to_colormap(b, cs::Union{String, Symbol})
    cs_sym = Symbol(cs)
    if cs_sym in colorbrewer_names
        ColorBrewer.palette(string(cs_sym), 9)
    else
        #TODO integrate PlotUtils color gradients
        error("There is no color gradient named: $cs")
    end
end



"""
    to_spatial_order(b, x)
"xy" or "yx"
"""
function to_spatial_order(b, x)
    if !(x in ("yx", "xy"))
        error("Spatial order must be \"yx\" or \"xy\". Found: $x")
    end
    x
end

"""
:xy or :yx
"""
to_spatial_order(b, x::Symbol) = to_spatial_order(b, string(x))




using GLVisualize: IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA
export IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA

"""
    to_volume_algorithm(b, x)
Enum values: `IsoValue` `Absorption` `MaximumIntensityProjection` `AbsorptionRGBA` `IndexedAbsorptionRGBA`
"""
function to_volume_algorithm(b, value)
    if isa(value, GLVisualize.RaymarchAlgorithm)
        return Int32(value)
    elseif isa(value, Int32) && value in 0:5
        return value
    else
        error("$value is not a valid volume algorithm. Please have a look at the documentation of `to_volume_algorithm`")
    end
end

"""
Symbol/String: iso, absorption, mip, absorptionrgba, indexedabsorption
"""
function to_volume_algorithm(b, value::Union{Symbol, String})
    vals = Dict(
        :iso => IsoValue,
        :absorption => Absorption,
        :mip => MaximumIntensityProjection,
        :absorptionrgba => AbsorptionRGBA,
        :indexedabsorption => IndexedAbsorptionRGBA,
    )
    to_volume_algorithm(b, get(vals, Symbol(value)) do
        error("$value not a valid volume algorithm. Needs to be in $(keys(vals))")
    end)
end
