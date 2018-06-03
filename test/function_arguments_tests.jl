using Plots
using Colors, StaticArrays
using StaticArrays.FixedSizeArrays

const FuncOrFuncs{F} = F

# ==========================================================
"""
    plot_funcs

shorthands for plot functions from Plots.jl
"""
plot_funcs = [
bar,
barh,
barhist,
boxplot,
contour,
contour3d,
contourf,
curves,
density,
heatmap,
hexbin,
histogram,
histogram2d,
hline,
hspan,
ohlc,
path3d,
plots_heatmap,
quiver,
scatter,
scatter3d,
scatterhist,
stephist,
sticks,
surface,
violin,
vline,
vspan,
wireframe
]

# ==========================================================
"""
    signatures

function signatures from Plots.jl
"""
signatures = [
    # 1 argument

    # An AbstractMatrix where the type is the union of Integer and AbstractFloat.
    Tuple{AbstractMatrix{T} where T<:Union{Integer,AbstractFloat},},
    # --> supported by function convert_arguments(P, data::AbstractMatrix)

    # Tuple{Formatted{T} where T<:AbstractMatrix,},

    # An AbstractArray where the type is Number, and the dimension is 3
    Tuple{AbstractArray{T,3} where T<:Number,},
    # --> supported by function convert_arguments(MT::Type{Mesh, xyz::AbstractVector{<: VecTypes{3, T}})

    # An AbstractMatrix where the type is of a ColorTypes.Gray
    Tuple{AbstractMatrix{T} where T<:Gray,},
    # --> handled by convert_attribute

    # An AbstractMatrix where the type is of a ColorTypes.Colorant
    Tuple{AbstractMatrix{T} where T<:Colorant,},
    # --> handled by convert_attribute

    # plotting arbitrary shapes/polygons
    #Tuple{Shape,},
    #Tuple{AbstractVector{Shape},},
    #Tuple{AbstractMatrix{Shape},},

    # function without range... use the current range of the x-axis

    # A function
    Tuple{F} where F<:Function,

    # 2 arguments

    # A function and a number
    Tuple{F, Number} where F<:Function,

    # 3 arguments
    # 3d line or scatter

    # Three AbstractVector's
    Tuple{AbstractVector,AbstractVector,AbstractVector,},
    # --> supported by function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractVector, i::AbstractArray{T, 3}) where T

    # Three AbstractMatrix's
    Tuple{AbstractMatrix,AbstractMatrix,AbstractMatrix,},
    # --> supported by function convert_arguments(P, x::AbstractMatrix, y::AbstractMatrix, z::AbstractMatrix)

    # Two AbstractVector's and a function
    Tuple{AbstractVector,AbstractVector,Function,},

    # Two AbstractVector's and an AbstractMatrix
    Tuple{AbstractVector,AbstractVector,AbstractMatrix,},
    # --> supported by function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)

    # Two AbstractVector's and an AbstractMatrix with the type ColorTypes.Gray
    Tuple{AbstractVector,AbstractVector,AbstractMatrix{T} where T<:Gray},
    # --> supported like above with AVeC, AVec, AMat

    # Two AbstractVector's and an AbstractMatrix with the type ColorTypes.Colorant
    Tuple{AbstractVector,AbstractVector,AbstractMatrix{T} where T<:Colorant},
    # --> supported like above with AVeC, AVec, AMat

    #parametric functions

    # A function and two numbers
    Tuple{Function, Number, Number,},

    # An AbstractArray of functions, and two numbers
    Tuple{AbstractArray{F}, Number, Number,} where F<:Function,

    # Tuple{FuncOrFuncs{F}, FuncOrFuncs{G}, AbstractVector}  where {F<:Function,G<:Function},
    # Tuple{FuncOrFuncs{F}, FuncOrFuncs{G}, Number, Number, Number} where {F<:Function,G<:Function},
    # Tuple{FuncOrFuncs{F}, FuncOrFuncs{G}, FuncOrFuncs{H}, AbstractVector} where {F<:Function,G<:Function,H<:Function},
    # Tuple{FuncOrFuncs{F}, FuncOrFuncs{G}, FuncOrFuncs{H}, Number, Number, Number} where {F<:Function,G<:Function,H<:Function},

    # Lists of tuples and Tuple{FixedSizeArrays,},
    # Tuple{Tuple},

    # (x,y) tuples

    # An AbstractVector of the Tuple of R1 and R2, where both R1 and R2 are numbers
    Tuple{AbstractVector{Tuple{R1,R2}}} where {R1<:Number,R2<:Number},

    # A Tuple of R1 and R2, where both R1 and R2 are numbers
    Tuple{Tuple{R1,R2}} where {R1<:Number,R2<:Number},

    # (x,y,z) tuples

    # An AbstractVector of the Tuple of R1, R2 and R3, where R1, R2 and R3 are numbers
    Tuple{AbstractVector{Tuple{R1,R2,R3}}} where {R1<:Number,R2<:Number,R3<:Number},

    # A Tuple of R1, R2 and R3, where R1, R2 and R3 are numbers
    Tuple{Tuple{R1,R2,R3}} where {R1<:Number,R2<:Number,R3<:Number},

    # these might be points+velocity, or OHLC or something else

    # An AbstractVector of the Tuple of R1, R2, R3 and R4, where R1, R2, R3 and R4 are numbers
    Tuple{AbstractVector{Tuple{R1,R2,R3,R4}}} where {R1<:Number,R2<:Number,R3<:Number,R4<:Number},

    # A Tuple of R1, R2, R3 and R4, where R1, R2, R3 and R4 are numbers
    Tuple{Tuple{R1,R2,R3,R4}} where {R1<:Number,R2<:Number,R3<:Number,R4<:Number},

    # 2D Tuple{FixedSizeArrays,},

    # An AbstractVector of a Vector of a fixed size, with the type Number and dimension 2
    Tuple{AbstractVector{FixedSizeArrays.Vec{2,T}}} where {T<:Number},

    # A Vector of a fixed size, with the type Number and dimension 2
    Tuple{FixedSizeArrays.Vec{2,T}} where {T<:Number},

    # 3D Tuple{FixedSizeArrays,},

    # An AbstractVector of a Vector of a fixed size, with the type Number and dimension 3
    Tuple{AbstractVector{FixedSizeArrays.Vec{3,T}}} where {T<:Number},

    # A Vector of a fixed size, with the type Number and dimension 3
    Tuple{FixedSizeArrays.Vec{3,T}} where {T<:Number}
]

# ==========================================================
# basic generator function

basic_generator(x) = sin(x)
basic_generator(x, y) = sin(x) + cos(y)
basic_generator(x, y, z) = sin(x) + cos(y) + (cos(z) * sin(z))

# convert Types and assign values
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


# for signature in signatures
#     # println(to_values(signature))
#     Plots.scatter(to_values(signature))
# end
#
# Plots.scatter(to_values(signatures[1]))
# generated_values = to_values.(signatures)

# ==========================================================
# batch testing

plots = []
for func in plot_funcs
    for signature in signatures
        generated_values = to_values(signature)
        # println("Testing $func with $signature")
        try
            plt = func(generated_values...)
            push!(plots, (func, generated_values, plt))
            println("No errors thrown for $func with $signature")
        catch
            println("FAILED: $func with $signature")
        end
    end
end

plots

# ==========================================================

# displaying outputs
plt = plot(plots[60:64][3]...) #the "..." means squashing

# to show plots
plot(plots[N][3])

# to show the generated values
plots[N][2]

# to show the function
plots[N][1]
