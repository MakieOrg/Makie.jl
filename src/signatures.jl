using Colors, StaticArrays
using StaticArrays.FixedSizeArrays

const FuncOrFuncs{F} = F


signatures = [
    # 1 argument
    Tuple{AbstractMatrix{T} where T<:Union{Integer,AbstractFloat},},
    # Tuple{Formatted{T} where T<:AbstractMatrix,},
    Tuple{AbstractArray{T,3} where T<:Number,},
    Tuple{AbstractMatrix{T} where T<:Gray,},
    Tuple{AbstractMatrix{T} where T<:Colorant,},

    # plotting arbitrary shapes/polygons
    #Tuple{Shape,},
    #Tuple{AbstractVector{Shape},},
    #Tuple{AbstractMatrix{Shape},},

    # function without range... use the current range of the x-axis
    Tuple{F} where F<:Function,

    # 2 arguments
    Tuple{F, Number} where F<:Function,

    # 3 arguments
    # 3d line or scatter
    Tuple{AbstractVector,AbstractVector,AbstractVector,},
    Tuple{AbstractMatrix,AbstractMatrix,AbstractMatrix,},
    Tuple{AbstractVector,AbstractVector,Function,},
    Tuple{AbstractVector,AbstractVector,AbstractMatrix,},
    Tuple{AbstractVector,AbstractVector,AbstractMatrix{T} where T<:Gray},
    Tuple{AbstractVector,AbstractVector,AbstractMatrix{T} where T<:Colorant},
    #parametric functions
    Tuple{Function, Number, Number,},
    Tuple{AbstractArray{F}, Number, Number,} where F<:Function,
    # Tuple{FuncOrFuncs{F}, FuncOrFuncs{G}, AbstractVector}  where {F<:Function,G<:Function},
    # Tuple{FuncOrFuncs{F}, FuncOrFuncs{G}, Number, Number, Number} where {F<:Function,G<:Function},
    # Tuple{FuncOrFuncs{F}, FuncOrFuncs{G}, FuncOrFuncs{H}, AbstractVector} where {F<:Function,G<:Function,H<:Function},
    # Tuple{FuncOrFuncs{F}, FuncOrFuncs{G}, FuncOrFuncs{H}, Number, Number, Number} where {F<:Function,G<:Function,H<:Function},

    # Lists of tuples and Tuple{FixedSizeArrays,},
    # Tuple{Tuple},

    # (x,y) tuples
    Tuple{AbstractVector{Tuple{R1,R2}}} where {R1<:Number, R2<:Number},
    Tuple{Tuple{R1,R2}} where {R1<:Number,R2<:Number},

    # (x,y,z) tuples
    Tuple{AbstractVector{Tuple{R1,R2,R3}}} where {R1<:Number,R2<:Number,R3<:Number},
    Tuple{Tuple{R1,R2,R3}} where {R1<:Number,R2<:Number,R3<:Number},

    # these might be points+velocity, or OHLC or something else
    Tuple{AbstractVector{Tuple{R1,R2,R3,R4}}} where {R1<:Number,R2<:Number,R3<:Number,R4<:Number},
    Tuple{Tuple{R1,R2,R3,R4}} where {R1<:Number,R2<:Number,R3<:Number,R4<:Number},

    # 2D Tuple{FixedSizeArrays,},
    Tuple{AbstractVector{FixedSizeArrays.Vec{2,T}}} where {T<:Number},
    Tuple{FixedSizeArrays.Vec{2,T}} where {T<:Number},

    # 3D Tuple{FixedSizeArrays,},
    Tuple{AbstractVector{FixedSizeArrays.Vec{3,T}}} where {T<:Number},
    Tuple{FixedSizeArrays.Vec{3,T}} where {T<:Number}
]


basic_generator(x) = sin(x)
basic_generator(x, y) = sin(x) + cos(y)
basic_generator(x, y, z) = sin(x) + cos(y) + (cos(z) * sin(z))


function to_values(::Type{Union{T1, T2, T3}}) where {T1, T2, T3}
    T1
end
to_values(::Type{T}) where T <: Function = basic_generator
function to_values(::Type{<: AbstractArray{T, N} where T}) where N
    rand(ntuple(i->10, N)...)
end
function to_values(::Type{<: AbstractArray{<: Function, N}}) where N
    fill(basic_generator, ntuple(i->10, N)...)
end
function to_values(::Type{<: AbstractArray{<: Function}})
    fill(basic_generator, 10)
end
# function to_values(::Type{A}) where A <: AbstractArray{<: Function, N} where N
#     rand(basic_generator, ntuple(i->10, N)...)
# end
to_values(::Type{Number}) = rand()
to_values(::Type{T}) where T <: Number = rand(T)
to_values(::Type{Tuple{}}) = ()
function to_values(::Type{T}) where T <: Tuple
    T1 = Base.tuple_type_head(T)
    Ttail = Base.tuple_type_tail(T)
    (to_values(T1), to_values(Ttail)...)
end


for signature in signatures
    println(to_values(signature))
end
