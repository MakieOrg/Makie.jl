module CEnum

abstract type Cenum{T} end

Base.:|(a::T, b::T) where {T<:Cenum{UInt32}} = UInt32(a) | UInt32(b)
Base.:|(a::T, b::UInt32) where {T<:Cenum{UInt32}} = UInt32(a) | b
Base.:|(a::UInt32, b::T) where {T<:Cenum{UInt32}} = b | a

Base.:&(a::T, b::T) where {T<:Cenum{UInt32}} = UInt32(a) & UInt32(b)
Base.:&(a::T, b::UInt32) where {T<:Cenum{UInt32}} = UInt32(a) & b
Base.:&(a::UInt32, b::T) where {T<:Cenum{UInt32}} = b & a

Base.:(==)(a::Integer, b::Cenum{T}) where {T<:Integer} = a == T(b)
Base.:(==)(a::Cenum, b::Integer) = b == a

Base.:+(a::S, b::T) where {S<:Integer,T<:Cenum} = a + S(b)
Base.:+(a::T, b::S) where {S<:Integer,T<:Cenum} = S(a) + b
Base.:-(a::S, b::T) where {S<:Integer,T<:Cenum} = a - S(b)
Base.:-(a::T, b::S) where {S<:Integer,T<:Cenum} = S(a) - b

# typemin and typemax won't change for an enum, so we might as well inline them per type
Base.typemax(::Type{T}) where {T<:Cenum} = last(enum_values(T))
Base.typemin(::Type{T}) where {T<:Cenum} = first(enum_values(T))

Base.convert(::Type{Integer}, x::Cenum{T}) where {T<:Integer} = Base.bitcast(T, x)
Base.convert(::Type{T}, x::Cenum{T2}) where {T<:Integer,T2<:Integer} = convert(T, Base.bitcast(T2, x))

(::Type{T})(x::Cenum{T2}) where {T<:Integer,T2<:Integer} = T(Base.bitcast(T2, x))::T
(::Type{T})(x) where {T<:Cenum} = convert(T, x)

Base.write(io::IO, x::Cenum) = write(io, Int32(x))
Base.read(io::IO, ::Type{T}) where {T<:Cenum} = T(read(io, Int32))

enum_values(::T) where {T<:Cenum} = enum_values(T)
enum_names(::T) where {T<:Cenum} = enum_names(T)

is_member(::Type{T}, x::Integer) where {T<:Cenum} = is_member(T, enum_values(T), x)

@inline is_member(::Type{T}, r::UnitRange, x::Integer) where {T<:Cenum} = x in r
@inline function is_member(::Type{T}, values::Tuple, x::Integer) where {T<:Cenum}
    lo, hi = typemin(T), typemax(T)
    x<lo || x>hi && return false
    for val in values
        val == x && return true
        val > x && return false # is sorted
    end
    return false
end

function enum_name(x::T) where {T<:Cenum}
    index = something(findfirst(isequal(x), enum_values(T)), 0)
    if index != 0
        return enum_names(T)[index]
    end
    error("Invalid enum: $(Int(x)), name not found")
end

Base.show(io::IO, x::Cenum) = print(io, enum_name(x), "($(Int(x)))")

function islinear(array)
    isempty(array) && return false # false, really? it's kinda undefined?
    lastval = first(array)
    for val in Iterators.rest(array, 2)
        val-lastval == 1 || return false
    end
    return true
end


macro cenum(name, args...)
    if Meta.isexpr(name, :curly)
        typename, type = name.args
        typename = esc(typename)
        typesize = 8*sizeof(getfield(Base, type))
        typedef_expr = :(primitive type $typename <: CEnum.Cenum{$type} $typesize end)
    elseif isa(name, Symbol)
        # default to UInt32
        typename = esc(name)
        type = UInt32
        typedef_expr = :(primitive type $typename <: CEnum.Cenum{UInt32} 32 end)
    else
        error("Name must be symbol or Name{Type}. Found: $name")
    end
    lastval = -1
    name_values = map([args...]) do arg
        if isa(arg, Symbol)
            lastval += 1
            val = lastval
            sym = arg
        elseif arg.head == :(=) || arg.head == :kw
            sym,val = arg.args
            lastval = val
        else
            error("Expression of type $arg not supported. Try only symbol or name = value")
        end
        (sym, val)
    end
    sort!(name_values, by=last) # sort for values
    values = map(last, name_values)

    if islinear(values) # optimize for linear values
        values = :($(first(values)):$(last(values)))
    else
        values = :(tuple($(values...)))
    end
    value_block = Expr(:block)

    for (ename, value) in name_values
        push!(value_block.args, :(const $(esc(ename)) = $typename($value)))
    end

    expr = quote
        $typedef_expr
        function Base.convert(::Type{$typename}, x::Integer)
            is_member($typename, x) || Base.Enums.enum_argument_error($(Expr(:quote, name)), x)
            Base.bitcast($typename, convert($type, x))
        end
        CEnum.enum_names(::Type{$typename}) = tuple($(map(x-> Expr(:quote, first(x)), name_values)...))
        CEnum.enum_values(::Type{$typename}) = $values
        $value_block
    end
    expr
end
export @cenum


end # module
