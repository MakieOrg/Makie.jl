"""
    convert_arguments(::Type{PlotType}, args...) where PlotType

Converts the arguments to a plot function to a homogenous final type.
Can be specialized by plotting type
"""
function convert_arguments(P::Type, args::Vararg{Signal, N}) where N
    args_c = map(args...) do args...
        convert_arguments(P, args...)
    end
    ntuple(Val{N}) do i
        map(x-> x[i], args_c)
    end
end

# a few shortcut functions to make attribute conversion easier
@inline function get_attribute(dict, key)
    convert_attribute(value(dict[key]), Key{key}())
end

to_color(color) = convert_attribute(color, key"color"())
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

convert_arguments(P, y::RealVector) = convert_arguments(0 .. length(y), y)
convert_arguments(P, x::RealVector, y::RealVector) = (Point2f0.(x, y),)
convert_arguments(P, x::RealVector, y::RealVector, z::RealVector) = (Point3f0.(x, y, z),)
convert_arguments(::Type{Text}, x::AbstractString) = (String(x),)
convert_arguments(P, x::AbstractVector{<: VecTypes}) = (x,)
convert_arguments(P, x::GeometryPrimitive) = (decompose(Point, x),)


"""
Accepts a Vector of Pair of Points (e.g. [Point(0, 0) => Point(1, 1), ...])
to encode e.g. linesegments or directions.
"""
function convert_arguments(P, x::AbstractVector{Pair{Point{N, T}, Point{N, T}}}) where {N, T}
    (reinterpret(Point{N, T}, x),)
end

function convert_arguments(P, x::AbstractMatrix, y::AbstractMatrix, z::AbstractMatrix)
    (Float32.(x), Float32.(y), Float32.(z))
end
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (x, y, z)
end
# function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
#     (x, y, z)
# end

# function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z)
#     convert_arguments(P, to_range(x), to_range(y), z)
# end

function convert_arguments(P, data::AbstractMatrix)
    n, m = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, data)
end

function convert_arguments(P, data::Array{T, 3}) where T
    n, m, k = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, 0.0 .. k, data)
end
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractVector, i::AbstractArray{T, 3}) where T
    (x, y, z, i)
end
# function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::ClosedInterval, i::AbstractArray{T, 3}) where T
#     (x, y, z, i)
# end
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Function)
    _x, _y, _z = ntuple(Val{3}) do i
        A = (x, y, z)[i]
        reshape(A, ntuple(j-> j != i ? 1 : length(A), Val{3}))
    end
    (x, y, z, f.(_x, _y, _z))
end

function convert_arguments(P, x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function) where {T1, T2}
    if !applicable(f, x[1], y[1])
        error("You need to pass a function with signature f(x::$T1, y::$T2). Found: $f")
    end
    T = typeof(f(x[1], y[1]))
    z = similar(x, T, (length(x), length(y)))
    z .= f.(x, y')
    (x, y, z)
end


function convert_arguments(P, x::Rect)
    # TODO fix the order of decompose
    convert_arguments(P, decompose(Point2f0, x)[[1, 2, 4, 3, 1]])
end


convert_arguments(::Type{Mesh}, m::AbstractMesh) = (m,)
function convert_arguments(
        T::Type{<:Mesh},
        x::RealVector, y::RealVector, z::RealVector,
        indices::AbstractVector
    )
    convert_arguments(T, Point3f0.(x, y, z), indices)
end
function convert_arguments(
        ::Type{<:Mesh},
        vertices::AbstractVector{<: VecTypes{3, T}},
        indices::AbstractVector
    ) where T
    vert3f0 = T != Float32 ? Point3f0.(vertices) : vertices
    vertp3f0 = reinterpret(Point3f0, vert3f0)
    m = GLNormalMesh(vertp3f0, indices)
    (m,)
end

function convert_arguments(
        MT::Type{<:Mesh},
        x::RealVector, y::RealVector, z::RealVector
    )
    convert_arguments(MT, Point3f0.(x, y, z))
end
function convert_arguments(
        MT::Type{<:Mesh},
        xyz::AbstractVector{<: VecTypes{3, T}}
    ) where T
    faces = reinterpret(GLTriangle, UInt32[0:(length(xyz)-1);])
    convert_arguments(MT, xyz, faces)
end
function convert_arguments(MT::Type{<:Mesh}, xy::AbstractVector{<: VecTypes{2, T}}) where T
    convert_arguments(MT, Point3f0.(first.(xy), last.(xy), 0.0))
end

using ColorBrewer

convert_attribute(c::Colorant, ::key"color") = RGBA{Float32}(c)
convert_attribute(c::Symbol, k::key"color") = convert_attribute(string(c), k)
convert_attribute(c::String, ::key"color") = parse(RGBA{Float32}, c)
convert_attribute(c::Union{Tuple, AbstractArray}, k::key"color") = convert_attribute.(c, k)
function convert_attribute(c::Tuple{T, F}, k::key"color") where {T, F <: Number}
    col = convert_attribute(c[1], k)
    RGBAf0(Colors.color(col), c[2])
end
convert_attribute(c::Billboard, ::key"rotations") = Quaternionf0(0, 0, 0, 1)
convert_attribute(c, ::key"markersize", ::key"scatter") = Vec2f0(c)
convert_attribute(c::Vector, ::key"markersize", ::key"scatter") = convert(Array{Vec2f0}, c)
convert_attribute(c, ::key"markersize", ::key"meshscatter") = Vec3f0(c)
convert_attribute(c::Vector, ::key"markersize", ::key"meshscatter") = convert(Array{Vec3f0}, c)
convert_attribute(c, ::key"glowcolor") = to_color(c)
convert_attribute(c, ::key"strokecolor") = to_color(c)
convert_attribute(c, ::key"strokewidth") = Float32(c)

convert_attribute(x::Void, ::key"linestyle") = x

"""
`AbstractVector{<:AbstractFloat}` for denoting sequences of fill/nofill. E.g.
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
Text align, e.g. :
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
        str == "default" && return convert_attribute("DejaVuSans", k)
        newface(format(match(Fontconfig.Pattern(string(x))), "%{file}"))
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
convert_attribute(s::VecTypes{4}, ::key"rotation") = Quaternion(s...)
convert_attribute(s::Tuple{<:VecTypes{3}, <: AbstractFloat}, ::key"rotation") = qrotation(s[1], s[2])
convert_attribute(s::Tuple{<:VecTypes{2}, <: AbstractFloat}, ::key"rotation") = qrotation(Vec3f0(s[1][1], s[1][2], 0), s[2])
convert_attribute(angle::AbstractFloat, ::key"rotation") = qrotation(Vec3f0(0, 0, 1), angle)
convert_attribute(r::AbstractVector, k::key"rotation") = convert_attribute.(r, k)


convert_attribute(x, k::key"colorrange") = Vec2f0(x)

convert_attribute(x, k::key"textsize") = Float32(x)
convert_attribute(x::AbstractVector{T}, k::key"textsize") where T <: Number = Float32.(x)
convert_attribute(x::AbstractVector{T}, k::key"textsize") where T <: VecTypes = Vec2f0.(x)
convert_attribute(x, k::key"linewidth") = Float32(x)
convert_attribute(x::AbstractVector, k::key"linewidth") = Float32.(x)

using ColorBrewer

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
    println("    ", "Viridis")
end

"""
    to_colormap(b, x)
An `AbstractVector{T}` with any object that [`to_color`](@ref) accepts
"""
convert_attribute(cm::AbstractVector, ::key"colormap") = RGBAf0.(cm)

"""
Tuple(A, B) or Pair{A, B} with any object that [`to_color`](@ref) accepts
"""
function convert_attribute(cs::Union{Tuple, Pair}, ::key"colormap")
    [to_color.(cs)...]
end

"""
A Symbol/String naming the gradient. For more on what names are available please see: `available_gradients()
"""
function convert_attribute(cs::Union{String, Symbol}, ::key"colormap")
    cs_sym = Symbol(cs)
    if cs_sym in colorbrewer_names
        return ColorBrewer.palette(string(cs_sym), 9)
    elseif lowercase(string(cs_sym)) == "viridis"
        return [
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
