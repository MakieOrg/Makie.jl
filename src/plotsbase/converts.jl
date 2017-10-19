

"""
All kinds of images
"""
to_image(b, image) = image

"""
All kinds of images
"""
to_bool(b, bool) = Bool(bool)

"""
`GLBuffer{UInt32}`
"""
to_index_buffer(b, x::GLBuffer) = x

"""
`TOrSignal{Int}, AbstractVector{UnitRange{Int}}, TOrSignal{UnitRange{Int}}`
"""
to_index_buffer(b, x::Union{TOrSignal{Int}, VecOrSignal{UnitRange{Int}}, TOrSignal{UnitRange{Int}}}) = x

"""
`AbstractVector{<:Integer}` assumend 1-based indexing
"""
function to_index_buffer(b, x::AbstractVector{I}) where I <: Integer
    gpu_mem = GLBuffer(Cuint.(to_value(x) .- 1), buffertype = GL_ELEMENT_ARRAY_BUFFER)
    x = lift_node(to_node(x)) do x
        val = Cuint[i-1 for i = x]
        update!(gpu_mem, val)
     end
    gpu_mem
end

"""
`AbstractVector{<:Face{2}}` for linesegments
"""
function to_index_buffer(b, x::AbstractVector{I}) where I <: Face{2}
    Face{2, GLIndex}.(x)
end

"""
`AbstractVector{UInt32}`, is assumed to be 0 based
"""
function to_index_buffer(b, x::AbstractVector{UInt32})
    gpu_mem = GLBuffer(to_value(x), buffertype = GL_ELEMENT_ARRAY_BUFFER)
    lift_node(to_node(x)) do x
        update!(gpu_mem, x)
    end
    gpu_mem
end

to_index_buffer(b, x) = error(
    "Not a valid index type: $(typeof(x)).
    Please choose from Int, Vector{UnitRange{Int}}, Vector{Int} or a signal of either of them"
)


"""
`NTuple{2, AbstractArray{Float}}` for 2D points
"""
function to_positions(b, x::Tuple{<: AbstractArray, <: AbstractArray})
    Point{2, Float32}.(x...)
end

"""
`NTuple{3, AbstractArray{Float}}` for 3D points
"""
function to_positions(b, x::Tuple{<: AbstractArray, <: AbstractArray, <: AbstractArray})
    Point{3, Float32}.(x...)
end

"""
`view(AbstractArray{Point}, idx)` for a subset of points. Can be shared (so you can plot subsets of the same data)!
"""
function to_positions(b, x::SubArray)
    view(to_positions(b, x.parent), x.indexes...)
end

"""
`AbstractArray{T}` where T needs to have `length` defined and must be convertible to a Point
"""
function to_positions(b, x::AbstractArray{T}) where T
    N = if applicable(length, T)
        length(T)
    else
        error("Point type needs to have length defined and needs to be convertible to GeometryTypes point (e.g. tuples, abstract arrays etc.)")
    end
    Point{N, Float32}.(x)
end


function to_positions(b, x)
    error("Not a valid position type: $(typeof(x)). Try one of: $position_types")
end

"""
`AbstractArray`
"""
to_array(b, x) = collect(x)

"""
`Function`
"""
to_scalefunc(b, x) = x# TODO implement it

"""
All text
"""
to_text(b, x) = x# TODO implement it
"""
All fonts
"""
to_font(b, x) = x # TODO implement it

"""
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
`Range`
"""
to_surface(b, x::Range) = x
"""
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
`GeometryTypes.Circle(Point2(...), radius)`
"""
to_spritemarker(b, x::Circle) = x

"""
`Type{GeometryTypes.Circle}`
"""
to_spritemarker(b, ::Type{Circle}) = Circle(Point2f0(0), 1f0)
"""
`Type{GeometryTypes.Rectangle}`
"""
to_spritemarker(b, ::Type{Rectangle}) = HyperRectangle(Vec2f0(0), Vec2f0(1))
"""
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


to_spritemarker(b, marker::Vector{Char}) = String(marker)

"""
Vector of anything that is accepted as a single marker will give each point it's own marker.
Note that it needs to be a uniform vector with the same element type!
"""
function to_spritemarker(b, marker::Vector)
    marker = map(marker) do sym
        to_spritemarker(b, sym)
    end
    if isa(marker, Vector{Char})
        to_spritemarker(b, marker)
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
`Billboard()` for a rotation that will always face the camera
"""
to_rotations(b, x::Billboard) = x

"""
Any AbstractArray which elements can be converted to Vec4 (as a quaternion x, y, z, w)
"""
to_rotations(b, x::AbstractVector) = to_static_vec(x)

"""
Anything that can be converted to `Vec2f0` for x, y scale
"""
to_markersize(b, x) = Vec2f0(x)
to_markersize(b, x::AbstractVector) = Vec2f0.(x)

"""
`Nothing` for no style
"""
to_linestyle(b, ls::Void) = nothing

"""
`AbstractVector{<:AbstractFloat}` for denoting sequences of fill/nofill. E.g.
[0.5, 0.8, 1.2] will result in 0.5 filled, 0.3 unfilled, 0.4 filled
"""
to_linestyle(b, ls::AbstractVector{<:AbstractFloat}) = ls

"""
A `Symbol` equal to `:dash`, `:dot`, `:dashdot`, `:dashdotdot`
"""
to_linestyle(b, ls::Symbol) = ls

"""
Same as `to_linestyle`
"""
to_pattern(b, ::Node{Void}, linewidth) = nothing
to_pattern(b, A::AbstractVector, linewidth) = A
function to_pattern(b, ls::Node{Symbol}, linewidth)
    lift_node(ls, lw) do ls, lw
        points = if ls == :dash
            [0.0, lw, 2lw, 3lw, 4lw]
        elseif ls == :dot
            tick, gap = lw/2, lw/4
            [0.0, tick, tick+gap, 2tick+gap, 2tick+2gap]
        elseif ls == :dashdot
            dtick, dgap = lw, lw
            ptick, pgap = lw/2, lw/4
            [0.0, dtick, dtick+dgap, dtick+dgap+ptick, dtick+dgap+ptick+pgap]
        elseif ls == :dashdotdot
            dtick, dgap = lw, lw
            ptick, pgap = lw/2, lw/4
            [0.0, dtick, dtick+dgap, dtick+dgap+ptick, dtick+dgap+ptick+pgap, dtick+dgap+ptick+pgap+ptick,  dtick+dgap+ptick+pgap+ptick+pgap]
        else
            error("Unkown line style: $linestyle. Available: :dash, :dot, :dashdot, :dashdotdot or a sequence of numbers enumerating the next transparent/opaque region")
        end
        points
    end
end

"""
Vector{Normal{3}}
"""
to_normals(b, x) = x

"""
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

"""
Index into Mesh attributes, Vector{Integer}
"""
to_attribut_id(backend, x) = x
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
Any Object convertible to Floatingpoint
"""
to_float(b, x) = Float32(x)

to_color(c) = to_color(current_backend[], c)

"""
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
An `AbstractVector{T}` with any object that [to_color](@ref) accepts
"""
to_colormap(b, cm::AbstractVector) = RGBAf0.(cm)

"""
Tuple(A, B) or Pair{A, B} with any object that [to_color](@ref) accepts
"""
function to_colormap(b, cs::Union{Tuple, Pair})
    [to_color.(cs)...]
end

to_colormap(val) = to_colormap(current_backend[], val)

"""
A Symbol/String naming the gradient. For more on what names are available please see: `available_gradients()`
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
