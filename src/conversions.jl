
# a few shortcut functions to make attribute conversion easier
@inline function get_attribute(dict, key)
    convert_attribute(value(dict[key]), Key{key}())
end

"""
    to_color(color)

Converts a `color` symbol (e.g. `:blue`) to a color RGBA.
"""
to_color(color) = convert_attribute(color, key"color"())

"""
    to_colormap(cm[, N = 20])

Converts a colormap `cm` symbol (e.g. `:Spectral`) to a colormap RGB array, where `N` specifies the number of color points.
"""
to_colormap(color) = convert_attribute(color, key"colormap"())
to_rotation(color) = convert_attribute(color, key"rotation"())
to_font(color) = convert_attribute(color, key"font"())
to_align(color) = convert_attribute(color, key"align"())
to_textsize(color) = convert_attribute(color, key"textsize"())

convert_attribute(x, key::Key, ::Key) = convert_attribute(x, key)
convert_attribute(s::SceneLike, x, key::Key, ::Key) = convert_attribute(s, x, key)
convert_attribute(s::SceneLike, x, key::Key) = convert_attribute(x, key)
convert_attribute(x, key::Key) = x

# By default, don't apply any conversions
convert_arguments(P, args...) = args

const PointBased = Union{MeshScatter, Scatter, Lines, LineSegments}
const XYBased = PointBased

function convert_arguments(::Type{<: PointBased}, positions::AbstractVector{<: VecTypes{N, <: Number}}) where N
    (convert(Vector{Point{N, Float32}}, positions),)
end

function convert_arguments(::Type{<: PointBased}, positions::SubArray{<: VecTypes, 1})
    # TODO figure out a good subarray solution
    (positions,)
end

"""
Enables to use scatter like a surface plot with x::Vector, y::Vector, z::Matrix
spanning z over the grid spanned by x y
"""
function convert_arguments(::Type{<: PointBased}, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (vec(Point3f0.(x, y', z)),)
end
"""
    convert_arguments(P, x, y, z)::(Vector)

Takes vectors `x`, `y`, and `z` and turns it into a vector of 3D points of the values
from `x`, `y`, and `z`.
`P` is the plot Type (it is optional).
"""
convert_arguments(::Type{<: PointBased}, x::RealVector, y::RealVector, z::RealVector) = (Point3f0.(x, y, z),)

"""
    convert_arguments(P, x)::(Vector)

Takes an input GeometryPrimitive `x` and decomposes it to points.
`P` is the plot Type (it is optional).
"""
convert_arguments(::Type{<: PointBased}, x::GeometryPrimitive) = (decompose(Point, x),)

function convert_arguments(::Type{<: PointBased}, pos::AbstractMatrix{<: Number})
    (to_vertices(pos),)
end



"""
Accepts a Vector of Pair of Points (e.g. `[Point(0, 0) => Point(1, 1), ...]`)
to encode e.g. linesegments or directions.
"""
function convert_arguments(::Type{<: LineSegments}, positions::AbstractVector{E}) where E <: Union{Pair{A, A}, Tuple{A, A}} where A <: VecTypes{N, T} where {N, T}
    (convert(Vector{Point{N, Float32}}, reinterpret(Point{N, T}, positions)),)
end


"""
    convert_arguments(P, y)::Vector
Takes vector `y` and generates a range from 1 to the length of `y`, for plotting on
an arbitrary `x` axis.

`P` is the plot Type (it is optional).
"""
convert_arguments(P::Type{<: XYBased}, y::RealVector) = convert_arguments(P, 1:length(y), y)

"""
    convert_arguments(P, x, y)::(Vector)

Takes vectors `x` and `y` and turns it into a vector of 2D points of the values
from `x` and `y`.

`P` is the plot Type (it is optional).
"""
convert_arguments(::Type{<: PointBased}, x::RealVector, y::RealVector) = (Point2f0.(x, y),)
convert_arguments(::Type{<: XYBased}, x::ClosedInterval, y::RealVector) = convert_arguments(range(minimum(x), stop=maximum(x), length=length(y)), y)
to_linspace(interval, N) = range(minimum(interval), stop=maximum(interval), length=N)
"""
    convert_arguments(P, x, y, z)::Tuple{ClosedInterval, ClosedInterval, Matrix}

Takes 2 ClosedIntervals's `x`, `y`, and an AbstractMatrix `z`, and converts the closed range to
linspaces with size(z, 1/2)
`P` is the plot Type (it is optional).
"""
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    convert_arguments(P, to_linspace(x, size(z, 1)), to_linspace(y, size(z, 2)), z)
end


"""
    convert_arguments(x)::(String)

Takes an input `AbstractString` `x` and converts it to a string.
"""
convert_arguments(::Type{Text}, x::AbstractString) = (String(x),)


"""
    convert_arguments(P, x)::(Vector)

Takes an input `HyperRectangle` `x` and decomposes it to points.

`P` is the plot Type (it is optional).
"""
function convert_arguments(P::Type{<: PointBased}, x::Rect2D)
    # TODO fix the order of decompose
    convert_arguments(P, decompose(Point2f0, x)[[1, 2, 4, 3, 1]])
end
function convert_arguments(P::Type{<: PointBased}, x::Rect3D)
    inds = [
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 5, 5, 7, 7, 3, 1, 3,
        4, 8, 8, 6, 2, 4, 2, 6
    ]
    convert_arguments(P, decompose(Point3f0, x)[inds])
end


const SurfaceLike = Union{Surface, Heatmap, Image}

"""
    convert_arguments(P, x, y, z)::Tuple{Matrix, Matrix, Matrix}

Takes 3 `AbstractMatrix` `x`, `y`, and `z`, converts them to `Float32` and
outputs them in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::Type{<: SurfaceLike}, x::AbstractMatrix, y::AbstractMatrix, z::AbstractMatrix)
    (convert(Matrix{Float32}, x), convert(Matrix{Float32}, y), convert(Matrix{Float32}, z))
end

"""
    convert_arguments(P, x, y, z)::Tuple{Vector, Vector, Matrix}

Takes 2 `AbstractVector` `x`, `y`, and an AbstractMatrix `z`, and puts them in a Tuple.
`P` is the plot Type (it is optional).
"""
function convert_arguments(::Type{<: SurfaceLike}, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (x, y, z)
end

"""
    convert_arguments(P, Matrix)::Tuple{ClosedInterval, ClosedInterval, Matrix}

Takes an `AbstractMatrix`, converts the dimesions `n` and `m` into `ClosedInterval`,
and stores the `ClosedInterval` to `n` and `m`, plus the original matrix in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::Type{<: SurfaceLike}, data::AbstractMatrix)
    n, m = Float64.(size(data))
    (0.0 .. m, 0.0 .. n, data)
end

"""
    convert_arguments(P, x, y, f)::(Vector, Vector, Matrix)

Takes vectors `x` and `y` and the function `f`, and applies `f` on the grid that `x` and `y` span.
This is equivalent to `f.(x, y')`.
`P` is the plot Type (it is optional).
"""
function convert_arguments(::Type{<: SurfaceLike}, x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function) where {T1, T2}
    if !applicable(f, x[1], y[1])
        error("You need to pass a function with signature f(x::$T1, y::$T2). Found: $f")
    end
    T = typeof(f(x[1], y[1]))
    z = similar(x, T, (length(x), length(y)))
    z .= f.(x, y')
    (x, y, z)
end

const VolumeLike = Union{Volume}
"""
    convert_arguments(P, Matrix)::Tuple{ClosedInterval, ClosedInterval, ClosedInterval, Matrix}

Takes an array of `{T, 3} where T`, converts the dimesions `n`, `m` and `k` into `ClosedInterval`,
and stores the `ClosedInterval` to `n`, `m` and `k`, plus the original array in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::Type{<: VolumeLike}, data::Array{T, 3}) where T
    n, m, k = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, 0.0 .. k, data)
end

"""
    convert_arguments(P, x, y, z, i)::(Vector, Vector, Vector, Matrix)

Takes 3 `AbstractVector` `x`, `y`, and `z` and the `AbstractMatrix` `i`, and puts everything in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::Type{<: VolumeLike}, x::AbstractVector, y::AbstractVector, z::AbstractVector, i::AbstractArray{T, 3}) where T
    (x, y, z, i)
end
# function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::ClosedInterval, i::AbstractArray{T, 3}) where T
#     (x, y, z, i)
# end

"""
    convert_arguments(P, x, y, z, f)::(Vector, Vector, Vector, Matrix)

Takes `AbstractVector` `x`, `y`, and `z` and the function `f`, evaluates `f` on the volume
spanned by `x`, `y` and `z`, and puts `x`, `y`, `z` and `f(x,y,z)` in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::Type{<: VolumeLike}, x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Function)
    if !applicable(f, x[1], y[1], z[1])
        error("You need to pass a function with signature f(x, y, z). Found: $f")
    end
    _x, _y, _z = ntuple(Val(3)) do i
        A = (x, y, z)[i]
        reshape(A, ntuple(j-> j != i ? 1 : length(A), Val(3)))
    end
    (x, y, z, f.(_x, _y, _z))
end




"""
    convert_arguments(Mesh, x, y, z)::GLNormalMesh

Takes real vectors x, y, z and constructs a mesh out of those, under the assumption that
every 3 points form a triangle.
"""
function convert_arguments(
        T::Type{<:Mesh},
        x::RealVector, y::RealVector, z::RealVector
    )
    convert_arguments(T, Point3f0.(x, y, z))
end
"""
    convert_arguments(Mesh, xyz::AbstractVector)::GLNormalMesh

Takes an input mesh and a vector `xyz` representing the vertices of the mesh, and
creates indices under the assumption, that each triplet in `xyz` forms a triangle.
"""
function convert_arguments(
        MT::Type{<:Mesh},
        xyz::AbstractVector
    )
    faces = reinterpret(GLTriangle, UInt32[0:(length(xyz)-1);])
    convert_arguments(MT, xyz, faces)
end
# # ambigious case
# function convert_arguments(
#         MT::Type{<:Mesh},
#         xyz::AbstractVector{<: VecTypes{N, T}}
#     ) where {T, N}
#     faces = reinterpret(GLTriangle, UInt32[0:(length(xyz)-1);])
#     convert_arguments(MT, xyz, faces)
# end
function convert_arguments(MT::Type{<:Mesh}, geom::GeometryPrimitive)
    (GLNormalMesh(geom),)
end
"""
    convert_arguments(Mesh, x, y, z, indices)::GLNormalMesh

Takes real vectors x, y, z and constructs a triangle mesh out of those, using the
faces in `indices`, which can be integers (every 3 -> one triangle), or GeometryTypes.Face{N, <: Integer}.
"""
function convert_arguments(
        T::Type{<: Mesh},
        x::RealVector, y::RealVector, z::RealVector,
        indices::AbstractVector
    )
    convert_arguments(T, Point3f0.(x, y, z), indices)
end

function to_triangles(x::AbstractVector{Int})
    idx0 = UInt32.(x .- 1)
    to_triangles(idx0)
end
function to_triangles(idx0::AbstractVector{UInt32})
    reinterpret(GLTriangle, idx0)
end
function to_triangles(faces::AbstractVector{Face{3, T}}) where T
    convert(Vector{GLTriangle}, faces)
end
function to_triangles(faces::AbstractMatrix{T}) where T <: Integer
    let N = Val(size(faces, 2)), lfaces = faces
        broadcast(1:size(faces, 1), N) do fidx, n
            to_ndim(GLTriangle, ntuple(i-> lfaces[fidx, i], n), 0.0)
        end
    end
end

function to_vertices(verts::AbstractVector{<: VecTypes{3, T}}) where T
    vert3f0 = T != Float32 ? Point3f0.(verts) : verts
    reinterpret(Point3f0, vert3f0)
end

function to_vertices(verts::AbstractVector{<: VecTypes})
    to_vertices(map(x-> Point3f0(x[1], x[2], 0.0), verts))
end

function to_vertices(verts::AbstractMatrix{<: Number})
    if size(verts, 1) in (2, 3)
        to_vertices(verts, Val(1))
    elseif size(verts, 2) in (2, 3)
        to_vertices(verts, Val(2))
    else
        error("You are using a matrix for vertices which uses neither dimension to encode the dimension of the space. Please have either size(verts, 1/2) in the range of 2-3. Found: $(size(verts))")
    end
end
function to_vertices(verts::AbstractMatrix{T}, ::Val{1}) where T <: Number
    reinterpret(Point{size(verts, 1), T}, convert(Vector{T}, vec(verts)), (size(verts, 2),))
end
function to_vertices(verts::AbstractMatrix{T}, ::Val{2}) where T <: Number
    let N = Val(size(verts, 2)), lverts = verts
        broadcast(1:size(verts, 1), N) do vidx, n
            to_ndim(Point3f0, ntuple(i-> lverts[vidx, i], n), 0.0)
        end
    end
end

"""
    convert_arguments(Mesh, vertices, indices)::GLNormalMesh

Takes `vertices` and `indices`, and creates a triangle mesh out of those.
See [to_vertices](@ref) and [to_triangles](@ref) for more informations about
accepted types.
"""
function convert_arguments(
        ::Type{<:Mesh},
        vertices::AbstractArray,
        indices::AbstractArray
    )
    m = GLNormalMesh(to_vertices(vertices), to_triangles(indices))
    (m,)
end



convert_attribute(c::Colorant, ::key"color") = convert(RGBA{Float32}, c)
convert_attribute(c::Symbol, k::key"color") = convert_attribute(string(c), k)
function convert_attribute(c::String, ::key"color")
    c in all_gradient_names && return to_colormap(c)
    parse(RGBA{Float32}, c)
end
convert_attribute(c::Union{Tuple, AbstractArray}, k::key"color") = convert_attribute.(c, k)
function convert_attribute(c::Tuple{T, F}, k::key"color") where {T, F <: Number}
    col = convert_attribute(c[1], k)
    RGBAf0(Colors.color(col), c[2])
end
convert_attribute(c::Billboard, ::key"rotations") = Quaternionf0(0, 0, 0, 1)
convert_attribute(r::AbstractArray, ::key"rotations") = to_rotation.(r)
convert_attribute(r::StaticVector, ::key"rotations") = to_rotation(r)

convert_attribute(c, ::key"markersize", ::key"scatter") = to_2d_scale(c)
convert_attribute(c, k1::key"markersize", k2::key"meshscatter") = to_3d_scale(c)

to_2d_scale(x::Number) = Vec2f0(x)
to_2d_scale(x::VecTypes) = to_ndim(Vec2f0, x, 1)
to_2d_scale(x::AbstractVector) = to_2d_scale.(x)

to_3d_scale(x::Number) = Vec3f0(x)
to_3d_scale(x::VecTypes) = to_ndim(Vec3f0, x, 1)
to_3d_scale(x::AbstractVector) = to_3d_scale.(x)

convert_attribute(c::Number, ::key"glowwidth") = Float32(c)
convert_attribute(c, ::key"glowcolor") = to_color(c)
convert_attribute(c, ::key"strokecolor") = to_color(c)
convert_attribute(c::Number, ::key"strokewidth") = Float32(c)

convert_attribute(x::Nothing, ::key"linestyle") = x

"""
    `AbstractVector{<:AbstractFloat}` for denoting sequences of fill/nofill. e.g.

[0.5, 0.8, 1.2] will result in 0.5 filled, 0.3 unfilled, 0.4 filled. 1.0 unit is one linewidth!
"""
convert_attribute(A::AbstractVector, ::key"linestyle") = A

"""
    A `Symbol` equal to `:dash`, `:dot`, `:dashdot`, `:dashdotdot`
"""
function convert_attribute(ls::Symbol, ::key"linestyle")
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
        error("Unkown line style: $ls. Available: :dash, :dot, :dashdot, :dashdotdot or a sequence of numbers enumerating the next transparent/opaque region")
    end
end


convert_attribute(c::Tuple{<: Number, <: Number}, ::key"position") = Point2f0(c[1], c[2])
convert_attribute(c::Tuple{<: Number, <: Number, <: Number}, ::key"position") = Point3f0(c)
convert_attribute(c::VecTypes{N}, ::key"position") where N = Point{N, Float32}(c)

"""
    Text align, e.g.:
"""
convert_attribute(x::Tuple{Symbol, Symbol}, ::key"align") = Vec2f0(alignment2num.(x))
convert_attribute(x::Vec2f0, ::key"align") = x
const _font_cache = Dict{String, NativeFont}()

"""
    font conversion

a string naming a font, e.g. helvetica
"""
function convert_attribute(x::Union{Symbol, String}, k::key"font")
    str = string(x)
    get!(_font_cache, str) do
        str == "default" && return convert_attribute("Dejavu Sans", k)
        fontpath = joinpath(@__DIR__, "..", "assets", "fonts")
        font = FreeTypeAbstraction.findfont(str, additional_fonts = fontpath)
        if font == nothing
            warn("Could not find font $str, using Dejavu Sans")
            if "dejavu sans" == lowercase(str)
                # since we fall back to dejavu sans, we need to check for recursion
                error("recursion, font path seems to not contain dejavu sans: $fontpath")
            end
            return convert_attribute("dejavu sans", k)
        end
        [font] # TODO do we really need the array around it!??!?
    end
end
convert_attribute(x::Vector{String}, k::key"font") = convert_attribute.(x, k)
convert_attribute(x::NativeFont, k::key"font") = x



"""
    rotation accepts:
    to_rotation(b, quaternion)
    to_rotation(b, tuple_float)
    to_rotation(b, vec4)
"""
convert_attribute(s::Quaternion, ::key"rotation") = s
function convert_attribute(s::VecTypes{N}, ::key"rotation") where N
    if N == 4
        Quaternion(s...)
    elseif N == 3
        rotation_between(Vec3f0(0, 0, 1), to_ndim(Vec3f0, s, 0.0))
    elseif N == 2

        rotation_between(Vec3f0(0, 1, 0), to_ndim(Vec3f0, s, 0.0))
    else
        error("$N dimensional vector $s can't be converted to a rotation")
    end
end

function convert_attribute(s::Tuple{VecTypes, AbstractFloat}, ::key"rotation")
    qrotation(to_ndim(Vec3f0, s[1], 0.0), s[2])
end
convert_attribute(angle::AbstractFloat, ::key"rotation") = qrotation(Vec3f0(0, 0, 1), angle)
convert_attribute(r::AbstractVector, k::key"rotation") = to_rotation.(r)


convert_attribute(x, k::key"colorrange") = Vec2f0(x)

convert_attribute(x, k::key"textsize") = Float32(x)
convert_attribute(x::AbstractVector{T}, k::key"textsize") where T <: Number = Float32.(x)
convert_attribute(x::AbstractVector{T}, k::key"textsize") where T <: VecTypes = Vec2f0.(x)
convert_attribute(x, k::key"linewidth") = Float32(x)
convert_attribute(x::AbstractVector, k::key"linewidth") = Float32.(x)

const colorbrewer_names = Symbol.([
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

    #The number of colors a qualitative color scheme can have depends on the scheme.
    #Accent, Dark2, Pastel2, and Set2 only support 8 colors.
    #The available qualitative color schemes are:
    :Set1,
    :Set2,
    :Set3,
    :Dark2,
    :Accent,
    :Paired,
    :Pastel1,
    :Pastel2
])

const colorbrewer_8color_names = String.([
    #Accent, Dark2, Pastel2, and Set2 only support 8 colors, so put them in a special-case list.
    :Accent,
    :Dark2,
    :Pastel2,
    :Set2
])

const all_gradient_names = Set(vcat(string.(colorbrewer_names), "viridis"))

"""
    available_gradients()

Prints all available gradient names.
"""
function available_gradients()
    println("Gradient Symbol/Strings:")
    for name in sort(collect(all_gradient_names))
        println("    ", name)
    end
end

"""
    to_colormap(b, x)

An `AbstractVector{T}` with any object that [`to_color`](@ref) accepts.
"""
convert_attribute(cm::AbstractVector, ::key"colormap") = to_color.(cm)

"""
Tuple(A, B) or Pair{A, B} with any object that [`to_color`](@ref) accepts
"""
function convert_attribute(cs::Union{Tuple, Pair}, ::key"colormap")
    [to_color.(cs)...]
end

to_colormap(x::Union{String, Symbol}, n::Integer) = convert_attribute(x, key"colormap"(), n)

"""
A Symbol/String naming the gradient. For more on what names are available please see: `available_gradients()
"""
function convert_attribute(cs::Union{String, Symbol}, ::key"colormap", n::Integer = 20)
    cs_string = string(cs)

    if lowercase(cs_string) == "viridis"
        cm = [
            to_color("#440154FF"),
            to_color("#481567FF"),
            to_color("#482677FF"),
            to_color("#453781FF"),
            to_color("#404788FF"),
            to_color("#39568CFF"),
            to_color("#33638DFF"),
            to_color("#2D708EFF"),
            to_color("#287D8EFF"),
            to_color("#238A8DFF"),
            to_color("#1F968BFF"),
            to_color("#20A387FF"),
            to_color("#29AF7FFF"),
            to_color("#3CBB75FF"),
            to_color("#55C667FF"),
            to_color("#73D055FF"),
            to_color("#95D840FF"),
            to_color("#B8DE29FF"),
            to_color("#DCE319FF"),
            to_color("#FDE725FF"),
        ]
        return resample(cm, n)
    elseif cs_string in all_gradient_names
        if cs_string in colorbrewer_8color_names
            return resample(ColorBrewer.palette(cs_string, 8), n)
        else
            return resample(ColorBrewer.palette(cs_string, 9), n)
        end
    else
        #TODO integrate PlotUtils color gradients
        error("There is no color gradient named: $cs")
    end
end



"""
    to_volume_algorithm(b, x)

Enum values: `IsoValue` `Absorption` `MaximumIntensityProjection` `AbsorptionRGBA` `IndexedAbsorptionRGBA`
"""
function convert_attribute(value, ::key"algorithm")
    if isa(value, RaymarchAlgorithm)
        return Int32(value)
    elseif isa(value, Int32) && value in 0:5
        return value
    elseif value == 7
        return value # makie internal contour implementation
    else
        error("$value is not a valid volume algorithm. Please have a look at the documentation of `to_volume_algorithm`")
    end
end

"""
Symbol/String: iso, absorption, mip, absorptionrgba, indexedabsorption
"""
function convert_attribute(value::Union{Symbol, String}, k::key"algorithm")
    vals = Dict(
        :iso => IsoValue,
        :absorption => Absorption,
        :mip => MaximumIntensityProjection,
        :absorptionrgba => AbsorptionRGBA,
        :indexedabsorption => IndexedAbsorptionRGBA,
    )
    convert_attribute(get(vals, Symbol(value)) do
        error("$value not a valid volume algorithm. Needs to be in $(keys(vals))")
    end, k)
end



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

Displays all available marker symbols.
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
to_spritemarker(x::Circle) = x

"""
    to_spritemarker(b, ::Type{Circle})

`Type{GeometryTypes.Circle}`
"""
to_spritemarker(::Type{<: Circle}) = Circle(Point2f0(0), 1f0)
"""
    to_spritemarker(b, ::Type{Rectangle})

`Type{GeometryTypes.Rectangle}`
"""
to_spritemarker(::Type{<: Rectangle}) = HyperRectangle(Vec2f0(0), Vec2f0(1))
to_spritemarker(::Type{<: Rect}) = HyperRectangle(Vec2f0(0), Vec2f0(1))
to_spritemarker(x::HyperRectangle) = x
"""
    to_spritemarker(b, marker::Char)

Any `Char`, including unicode
"""
to_spritemarker(marker::Char) = marker

"""
Matrix of AbstractFloat will be interpreted as a distancefield (negative numbers outside shape, positive inside)
"""
to_spritemarker(marker::Matrix{<: AbstractFloat}) = Float32.(marker)

"""
Any AbstractMatrix{<: Colorant} or other image type
"""
to_spritemarker(marker::AbstractMatrix{<: Colorant}) = marker

"""
A `Symbol` - Available options can be printed with `available_marker_symbols()`
"""
function to_spritemarker(marker::Symbol)
    if haskey(_marker_map, marker)
        return to_spritemarker(_marker_map[marker])
    else
        warn("Unsupported marker: $marker, using ● instead")
        return '●'
    end
end


to_spritemarker(marker::String) = marker
to_spritemarker(marker::AbstractVector{Char}) = String(marker)

"""
Vector of anything that is accepted as a single marker will give each point it's own marker.
Note that it needs to be a uniform vector with the same element type!
"""
function to_spritemarker(marker::AbstractVector)
    marker = map(marker) do sym
        to_spritemarker(sym)
    end
    if isa(marker, AbstractVector{Char})
        String(marker)
    else
        marker
    end
end

convert_attribute(value, ::key"marker", ::key"scatter") = to_spritemarker(value)
convert_attribute(value, ::key"isovalue", ::key"volume") = Float32(value)
