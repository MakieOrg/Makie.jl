#to_([a-z0-9_]+)\(b, ([::a-zA-Z0-9\.\{\}_]+)\) where


"""
3 Numbers for each dimension
"""
to_3floats(b, x::Tuple) = to_float.(b, x)
to_3floats(b, x::Number) = ntuple(i-> x, Val{3})

to_2floats(b, x::Tuple) = to_float.(b, x)
to_2floats(b, x::Number) = ntuple(i-> to_float(b, x), Val{2})



"""
    to_scale(b, s::Number)::Vec
"""
to_scale(b, s::Number) = Vec3f0(s)
"""
    to_scale(b, s::VecLike)::Point
"""
to_scale(b, s::VecLike{2}) = Vec3f0(s[1], s[2], 1)
to_scale(b, s::VecLike{3}) = Vec3f0(s)

"""
    to_offset(b, s::Number)::Point
"""
to_offset(b, s::Number) = Point3f0(s)
"""
    to_scale(b, s::VecLike)::Point
"""
to_offset(b, s::VecLike{2}) = Point3f0(s[1], s[2], 0)
to_offset(b, s::VecLike{3}) = Point3f0(s)


"""
    to_rotation(b, vec4)
"""
to_rotation(b, s::VecLike{4}) = Vec4f0(s)
"""
    to_rotation(b, quaternion)
"""
to_rotation(b, s::Quaternion) = Vec4f0(s.v1, s.v2, s.v3, s.s)

"""
    to_rotation(b, tuple_float)
"""
to_rotation(b, s::Tuple{<:VecLike{3}, <: AbstractFloat}) = qrotation(s[1], s[2])
to_rotation(b, s::Tuple{<:VecLike{2}, <: AbstractFloat}) = qrotation(Vec3f0(s[1][1], s[1][2], 0), s[2])
to_rotation(b, angle::AbstractFloat) = qrotation(Vec3f0(0, 0, 1), angle)
to_rotation(b, r::AbstractVector) = to_rotation.(b, r)



"""

    to_index_buffer(b, x::GLBuffer{UInt32})
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
    to_interval(b, x)
`Tuple{<: Number, <: Number}`
"""
function to_interval(b, x)
    if isa(x, Tuple{<: Number, <: Number})
        return x
    else
        error("Not an accepted value for interval. Please have a look at the documentation for to_interval")
    end
end

"""
Pair{<: Number, <: Number} e.g. 2 => 100
"""
to_interval(b, x::Pair{<: Number, <: Number}) = to_interval(b, (x...,))

"""
`AbstractVector` will be interpreted as an interval from minimum to maximum
"""
to_interval(b, x::AbstractVector) = to_interval(b, (minimum(x), maximum(x)))
