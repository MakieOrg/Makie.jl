##############
# A lot of mess in Makie comes from the fact, that we have single
# functions as entry points to a lot of functionality,
# that then need to guess where to put the attributes.
#
# The new goal is to keep keyword arguments where they end up:
# e.g. stop doing:
# scatter(x, y, resolution = (200, 200), axis = :log)
# and instead do:
# Scene(Scatter(x, y), resolution = (200, 200), axis = :log)

# again, there is no reason why we shouldn't get the previous behaviour in a higher level api!
# As a matter of fact, since we start creating types (Scatter vs scatter)
# the old names are still free and could just stay to as that high level API!

# Now, that we only need to deal with objects, that encapsulate their own
# arguments & attributes, we can make a pritty simple conversion pipeline:
# convert_arguments --> translate ... Name open for discussion!
#
# @recipe Scatter begin
#     color = :red
# end
#
# @recipe Histogram begin
#     color = :red
# end
#
# function translate(context::Plotting, h::StatsBase.Histogram)
#     return Makie.Histogram(h.edges, h.weights, gap=0)
# end
#
# function translate(context::Plotting, corrplot::Corplot)
#     return GridLayout(...)
# end

# Now you may ask, but how does this get further custom attributes?

# struct Plot
#     argument
#     attributes::Dict{Symbol, Any}
# end
# Plot(argument; kw...) = Plot(argument, Dict(kw))
#
# function translate(context::Plotting, kw::Plot)
#     translated = translate(context, kw.argument)
#     fill_in_themes!(translated, kw)
#     return translated
# end

# Et voila, this should "just work":
# Scene(Plot(histogram, color = :red))

# Observables will be passed between new plots!
# e.g.
# struct Test
#     color::Observable
# end
#
# function translate(context::Plotting, test::Test)
#     return Scatter(rand(10), rand(10), color = test.color)
# end

# And you will be able to return Observables!
# struct Test2
#     type::Observable
#     data
# end
#
# function translate(context::Plotting, test::Test2)
#     map(test.type) do type
#         if type == :scatter
#             return Scatter(test.data)
#         elseif type == :lines
#             return Lines(test.data)
#         end
#     end
# end

# Of course, this will also work with observables as argument!
# The default will be, to just lift translate for observables as argument!
# function translate(context::Plotting, observable::Observable)
#     map(observable) do value
#         return translate(context, value)
#     end
# end

# At this point, you may wonder what the context is doing.
# First of all, it can contain things like window events, to
# be able to make interactive recipes!

# Second, it can be used to apply different translations / recursion depths
# depending on the context.
# E.g. the plotting context could do only high level transformations
# while a rendering backend could split up the objects much further!
# function translate(context::GLMakie, image::Image)
#     return translate(context, Mesh(image.geometry, color = image))
# end
# function translate(context::GLMakie, mesh::Mesh)
#     # SOME Complex OpenGL VOoDOo MAGIC
# end

# The nice property about this is, that it's lazy!
# So a rendering backend can consume whatever high level objects it wants to!
# We can also allow to e.g. share implementations.
# E.g. WGLMakie can try to render things in a HTML context first,
# to e.g. turn slider into html, and then render the rest with WebGL

##############

const XYBased = Union{MeshScatter, Scatter, Lines, LineSegments}
const RangeLike = Union{AbstractRange, AbstractVector, ClosedInterval}

abstract type ConversionTrait end

struct NoConversion <: ConversionTrait end
# No conversion by default
conversion_trait(::Type) = NoConversion()
convert_arguments(::NoConversion, args...) = args

struct PointBased <: ConversionTrait end
conversion_trait(x::Type{<: XYBased}) = PointBased()

struct SurfaceLike <: ConversionTrait end
conversion_trait(::Type{<: Union{Surface, Heatmap, Image}}) = SurfaceLike()

function convert_arguments(T::PlotFunc, args...; kw...)
    ct = conversion_trait(T)
    try
        convert_arguments(ct, args...; kw...)
    catch e
        if e isa MethodError
            @show e
            error("No overload for $T and also no overload for trait $ct found! Arguments: $(typeof.(args))")
        else
            rethrow(e)
        end
    end
end

function convert_arguments(::PointBased, positions::AbstractVector{<: VecTypes{N, <: Number}}) where N
    (elconvert(Point{N, Float32}, positions),)
end

function convert_arguments(::PointBased, positions::SubArray{<: VecTypes, 1})
    # TODO figure out a good subarray solution
    (positions,)
end

"""
Enables to use scatter like a surface plot with x::Vector, y::Vector, z::Matrix
spanning z over the grid spanned by x y
"""
function convert_arguments(::PointBased, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (vec(Point3f0.(x, y', z)),)
end
"""
    convert_arguments(P, x, y, z)::(Vector)

Takes vectors `x`, `y`, and `z` and turns it into a vector of 3D points of the values
from `x`, `y`, and `z`.
`P` is the plot Type (it is optional).
"""
convert_arguments(::PointBased, x::RealVector, y::RealVector, z::RealVector) = (Point3f0.(x, y, z),)

"""
    convert_arguments(P, x)::(Vector)

Takes an input GeometryPrimitive `x` and decomposes it to points.
`P` is the plot Type (it is optional).
"""
convert_arguments(::PointBased, x::GeometryPrimitive) = (decompose(Point, x),)

function convert_arguments(::PointBased, pos::AbstractMatrix{<: Number})
    (to_vertices(pos),)
end

# Trait for categorical values
struct Categorical end
struct Continous end

categorical_trait(::Type) = Categorical()
categorical_trait(::Type{<: Number}) = Continous()

categoric_labels(x::AbstractVector{T}) where T = categoric_labels(categorical_trait(T), x)

categoric_labels(::Categorical, x) = unique(x)
categoric_labels(::Continous, x) = automatic # we let them be automatic

categoric_range(range::Automatic) = range
categoric_range(range) = 1:length(range)

function categoric_position(x, labels)
    findfirst(l -> l == x, labels)
end

categoric_position(x, labels::Automatic) = x

convert_arguments(P::PointBased, x::AbstractVector, y::AbstractVector) = convert_arguments(P, (x, y))
convert_arguments(P::PointBased, x::AbstractVector, y::AbstractVector, z::AbstractVector) = convert_arguments(P, (x, y, z))

function convert_arguments(::PointBased, positions::NTuple{N, AbstractVector}) where N
    x = first(positions)
    if any(n-> length(x) != length(n), positions)
        error("all vector need to be same length. Found: $(length.(positions))")
    end
    labels = categoric_labels.(positions)
    xyrange = categoric_range.(labels)
    points = map(zip(positions...)) do p
        Point{N, Float32}(categoric_position.(p, labels))
    end
    PlotSpec(points, tickranges = xyrange, ticklabels = labels)
end

function convert_arguments(
        SL::SurfaceLike,
        x::AbstractVector, y::AbstractVector, z::AbstractMatrix{<: Number}
    )
    n, m = size(z)
    positions = (x, y)
    labels = categoric_labels.(positions)
    xyrange = categoric_range.(labels)
    args = convert_arguments(SL, 0..n, 0..m, z)
    xyranges = (
        to_linspace(0.5..(n-0.5), n),
        to_linspace(0.5..(m-0.5), m)
    )
    return PlotSpec(
        args...,
        tickranges = xyranges, ticklabels = labels
    )
end

convert_arguments(::SurfaceLike, x::AbstractMatrix, y::AbstractMatrix) = (x, y, zeros(size(y)))

"""
Accepts a Vector of Pair of Points (e.g. `[Point(0, 0) => Point(1, 1), ...]`)
to encode e.g. linesegments or directions.
"""
function convert_arguments(::Type{<: LineSegments}, positions::AbstractVector{E}) where E <: Union{Pair{A, A}, Tuple{A, A}} where A <: VecTypes{N, T} where {N, T}
    (elconvert(Point{N, Float32}, reinterpret(Point{N, T}, positions)),)
end


"""
    convert_arguments(P, y)::Vector
Takes vector `y` and generates a range from 1 to the length of `y`, for plotting on
an arbitrary `x` axis.

`P` is the plot Type (it is optional).
"""
convert_arguments(P::PointBased, y::RealVector) = convert_arguments(P, 1:length(y), y)

"""
    convert_arguments(P, x, y)::(Vector)

Takes vectors `x` and `y` and turns it into a vector of 2D points of the values
from `x` and `y`.

`P` is the plot Type (it is optional).
"""
convert_arguments(::PointBased, x::RealVector, y::RealVector) = (Point2f0.(x, y),)
convert_arguments(P::PointBased, x::ClosedInterval, y::RealVector) = convert_arguments(P, LinRange(extrema(x)..., length(y)), y)
convert_arguments(P::PointBased, x::RealVector, y::ClosedInterval) = convert_arguments(P, x, LinRange(extrema(y)..., length(x)))

to_linspace(interval, N) = range(minimum(interval), stop = maximum(interval), length = N)
"""
    convert_arguments(P, x, y, z)::Tuple{ClosedInterval, ClosedInterval, Matrix}

Takes 2 ClosedIntervals's `x`, `y`, and an AbstractMatrix `z`, and converts the closed range to
linspaces with size(z, 1/2)
`P` is the plot Type (it is optional).
"""
function convert_arguments(P::SurfaceLike, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    convert_arguments(P, to_linspace(x, size(z, 1)), to_linspace(y, size(z, 2)), z)
end


"""
    convert_arguments(x)::(String)

Takes an input `AbstractString` `x` and converts it to a string.
"""
convert_arguments(::Type{<: Text}, x::AbstractString) = (String(x),)


"""
    convert_arguments(P, x)::(Vector)

Takes an input `HyperRectangle` `x` and decomposes it to points.

`P` is the plot Type (it is optional).
"""
function convert_arguments(P::PointBased, x::Rect2D)
    # TODO fix the order of decompose
    return convert_arguments(P, decompose(Point2f0, x)[[1, 2, 4, 3, 1]])
end

function convert_arguments(P::PointBased, x::SimpleRectangle)
    # TODO fix the order of decompose
    return convert_arguments(P, decompose(Point2f0, x)[[1, 2, 4, 3, 1]])
end

function convert_arguments(P::PointBased, mesh::AbstractMesh)
    return convert_arguments(P, decompose(Point3f0, mesh))
end

function convert_arguments(::Type{<: LineSegments}, x::Rect2D)
    # TODO fix the order of decompose
    points = decompose(Point2f0, x)
    return (points[[1, 2, 2, 4, 4, 3, 3, 1]],)
end

function convert_arguments(P::PointBased, x::Rect3D)
    inds = [
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 5, 5, 7, 7, 3, 1, 3,
        4, 8, 8, 6, 2, 4, 2, 6
    ]
    convert_arguments(P, decompose(Point3f0, x)[inds])
end


"""
    convert_arguments(P, x::VecOrMat, y::VecOrMat, z::Matrix)

Takes 3 `AbstractMatrix` `x`, `y`, and `z`, converts them to `Float32` and
outputs them in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::SurfaceLike, x::AbstractVecOrMat{<: Number}, y::AbstractVecOrMat{<: Number}, z::AbstractMatrix{<: Union{Number, Colorant}})
    return (el32convert(x), el32convert(y), el32convert(z))
end
function convert_arguments(::SurfaceLike, x::AbstractVecOrMat{<: Number}, y::AbstractVecOrMat{<: Number}, z::AbstractMatrix{<:Number})
    return (el32convert(x), el32convert(y), el32convert(z))
end

"""
Converts the elemen array type to `T1` without making a copy if the element type matches
"""
elconvert(::Type{T1}, x::AbstractArray{T2, N}) where {T1, T2, N} = convert(AbstractArray{T1, N}, x)
float32type(x::Type) = Float32
float32type(::Type{<: RGB}) = RGB{Float32}
float32type(::Type{<: RGBA}) = RGBA{Float32}
float32type(::Type{<: Colorant}) = RGBA{Float32}
float32type(x::AbstractArray{T}) where T = float32type(T)
float32type(x::T) where T = float32type(T)
el32convert(x::AbstractArray) = elconvert(float32type(x), x)
el32convert(x) = convert(float32type(x), x)

function el32convert(x::AbstractArray{T, N}) where {T<:Union{Missing, <: Number}, N}
    return map(x) do elem
        return (ismissing(elem) ? NaN32 : convert(Float32, elem))::Float32
    end::Array{Float32, N}
end

"""
    convert_arguments(P, Matrix)::Tuple{ClosedInterval, ClosedInterval, Matrix}

Takes an `AbstractMatrix`, converts the dimesions `n` and `m` into `ClosedInterval`,
and stores the `ClosedInterval` to `n` and `m`, plus the original matrix in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::SurfaceLike, data::AbstractMatrix)
    n, m = Float32.(size(data))
    (0f0 .. n, 0f0 .. m, el32convert(data))
end

"""
    convert_arguments(P, x, y, f)::(Vector, Vector, Matrix)

Takes vectors `x` and `y` and the function `f`, and applies `f` on the grid that `x` and `y` span.
This is equivalent to `f.(x, y')`.
`P` is the plot Type (it is optional).
"""
function convert_arguments(::SurfaceLike, x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function) where {T1, T2}
    if !applicable(f, x[1], y[1])
        error("You need to pass a function with signature f(x::$T1, y::$T2). Found: $f")
    end
    T = typeof(f(x[1], y[1]))
    z = similar(x, T, (length(x), length(y)))
    z .= f.(x, y')
    (x, y, z)
end

struct VolumeLike end
conversion_trait(::Type{<: Volume}) = VolumeLike()
"""
    convert_arguments(P, Matrix)::Tuple{ClosedInterval, ClosedInterval, ClosedInterval, Matrix}

Takes an array of `{T, 3} where T`, converts the dimesions `n`, `m` and `k` into `ClosedInterval`,
and stores the `ClosedInterval` to `n`, `m` and `k`, plus the original array in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::VolumeLike, data::AbstractArray{T, 3}) where T
    n, m, k = Float32.(size(data))
    return (0f0 .. n, 0f0 .. m, 0f0 .. k, el32convert(data))
end

function convert_arguments(::VolumeLike, x::RangeLike, y::RangeLike, z::RangeLike, data::AbstractArray{T, 3}) where T
    return (x, y, z, el32convert(data))
end
"""
    convert_arguments(P, x, y, z, i)::(Vector, Vector, Vector, Matrix)

Takes 3 `AbstractVector` `x`, `y`, and `z` and the `AbstractMatrix` `i`, and puts everything in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::VolumeLike, x::AbstractVector, y::AbstractVector, z::AbstractVector, i::AbstractArray{T, 3}) where T
    (x, y, z, el32convert(i))
end


"""
    convert_arguments(P, x, y, z, f)::(Vector, Vector, Vector, Matrix)

Takes `AbstractVector` `x`, `y`, and `z` and the function `f`, evaluates `f` on the volume
spanned by `x`, `y` and `z`, and puts `x`, `y`, `z` and `f(x,y,z)` in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::VolumeLike, x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Function)
    if !applicable(f, x[1], y[1], z[1])
        error("You need to pass a function with signature f(x, y, z). Found: $f")
    end
    _x, _y, _z = ntuple(Val(3)) do i
        A = (x, y, z)[i]
        reshape(A, ntuple(j-> j != i ? 1 : length(A), Val(3)))
    end
    return (x, y, z, el32convert.(f.(_x, _y, _z)))
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
function convert_arguments(
        MT::Type{<:Mesh},
        meshes::AbstractVector{<: AbstractMesh}
    )
    (meshes,)
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
    # we convert to UV mesh as default, because otherwise the uv informations get lost
    # - we can still drop them, but we can't add them later on
    (GLNormalUVMesh(geom),)
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
    elconvert(GLTriangle, faces)
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
    to_vertices(to_ndim.(Point3f0, verts, 0.0))
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
    reinterpret(Point{size(verts, 1), T}, elconvert(T, vec(verts)), (size(verts, 2),))
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



function convert_arguments(P::PlotFunc, r::AbstractVector, f::Function)
    ptype = plottype(P, Lines)
    to_plotspec(ptype, convert_arguments(ptype, r, f.(r)))
end

function convert_arguments(P::PlotFunc, i::AbstractInterval, f::Function)
    x, y = PlotUtils.adapted_grid(f, endpoints(i))
    ptype = plottype(P, Lines)
    to_plotspec(ptype, convert_arguments(ptype, x, y))
end

to_tuple(t::Tuple) = t
to_tuple(t) = (t,)

function convert_arguments(P::PlotFunc, f::Function, args...; kwargs...)
    tmp =to_tuple(f(args...; kwargs...))
    convert_arguments(P, tmp...)
end
