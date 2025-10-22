# BufferFormat abstracts GPU buffers like color buffers.
# This handles compatibility checks between buffer element types and merging of
# element types. E.g. `2x Float16` and `4x Float8` can merge to `4x Float16`

import FixedPointNumbers: N0f8

module BFT # BufferFormatType
    import FixedPointNumbers: N0f8

    # This does compatibility checks based on bits.
    # The 2 least significant bits map to the byte size of type,
    # i.e. (0, 1, 2, 3) -> (8, 16, 24, 32) bit
    # The remaining bits are used for types, i.e. 4 * (0, 1, 2, ...) map to types
    @enum BufferFormatType::UInt8 begin
        float8 = 0; float16 = 1; float32 = 3
        int8 = 4; int16 = 5; int32 = 7
        uint8 = 8; uint16 = 9; uint32 = 11
        stencil = 12
        depth24_stencil = 18; depth32_stencil = 19
        depth16 = 20; depth24 = 22; depth32 = 23
    end

    is_depth_stencil(x::BufferFormatType) = x == depth24_stencil || x == depth32_stencil
    is_depth(x::BufferFormatType) = x == stencil
    is_stencil(x::BufferFormatType) = depth16 < x < depth32

    # lowest 2 bits do variation between 8, 16 and 32 bit types, others do variation of base type
    function is_compatible(a::BufferFormatType, b::BufferFormatType)
        base_type_compatible = (UInt8(a) & 0b11111100) == (UInt8(b) & 0b11111100)
        stencil_compatible =(stencil <= a <= depth32_stencil) && (stencil <= b <= depth32_stencil)
        depth_compatible = (depth24_stencil <= a <= depth32) && (depth24_stencil <= b <= depth32)
        return base_type_compatible || stencil_compatible || depth_compatible
    end

    # assuming compatible types (max is a bitwise thing here btw)
    function _promote(a::BufferFormatType, b::BufferFormatType)
        if is_depth_stencil(a) || is_depth_stencil(b)
            byte = max(UInt8(a) & 0b00000011, UInt8(b) & 0b00000011)
            base = UInt8(16) # depth_stencil bits with 00 for byte bits
            return BufferFormatType(base + byte)
        else
            return BufferFormatType(max(UInt8(a), UInt8(b)))
        end
    end


    # we matched the lowest 2 bits to bytesize
    bytesize(x::BufferFormatType) = Int((UInt8(x) & 0b11) + 1)

    struct Float24 end
    struct Depth24Stencil8 end
    struct Depth32Stencil8 end

    const type_lookup = (
        N0f8, Float16, Nothing, Float32,
        Int8, Int16, Nothing, Int32,
        UInt8, UInt16, Nothing, UInt32,
        UInt8, Nothing, Nothing, Nothing,
        Nothing, Nothing, Depth24Stencil8, Depth32Stencil8,
        Nothing, Float16, Nothing, Float32,
    )
    to_type(t::BufferFormatType) = type_lookup[Int(t) + 1]
end


struct BufferFormat
    dims::Int
    type::BFT.BufferFormatType

    minfilter::Symbol
    magfilter::Symbol
    repeat::NTuple{2, Symbol}
    mipmap::Bool
    # anisotropy::Float32 # useless for this context?
    # local_read::Bool # flag so stage can mark that it only reads the pixel it will write to, i.e. allows using input as output
    # multisample # for MSAA
end

"""
    BufferFormat([dims = 4, type = N0f8]; [texture_parameters...])

Creates a `BufferFormat` which encodes requirements for an input or output of a
`Stage`. For example, a color output may require 3 (RGB) N0f8's (8 bit "float"
normalized to a 0..1 range).

The `BufferFormat` may also specify texture parameters for the buffer:
- `minfilter = :any`: How are pixels combined (:linear, :nearest, :nearest_mipmap_nearest, :linear_mipmap_nearest, :nearest_mipmap_linear, :linear_mipmap_linear)
- `magfilter = :any`: How are pixels interpolated (:linear, :nearest)
- `repeat = :clamp_to_edge`: How are pixels sampled beyond the boundary? (:clamp_to_edge, :mirrored_repeat, :repeat)
- `mipmap = false`: Should mipmaps be used?
"""
function BufferFormat(
        dims::Integer, type::BFT.BufferFormatType;
        minfilter = :any, magfilter = :any,
        repeat = (:clamp_to_edge, :clamp_to_edge),
        mipmap = false
    )
    _repeat = ifelse(repeat isa Symbol, (repeat, repeat), repeat)
    return BufferFormat(dims, type, minfilter, magfilter, _repeat, mipmap)
end
BufferFormat(dims = 4, type = N0f8; kwargs...) = BufferFormat(dims, type; kwargs...)
@generated function BufferFormat(dims::Integer, ::Type{T}; kwargs...) where {T}
    type = BFT.BufferFormatType(UInt8(findfirst(x -> x === T, BFT.type_lookup)) - 0x01)
    return :(BufferFormat(dims, $type; kwargs...))
end

function Base.:(==)(f1::BufferFormat, f2::BufferFormat)
    return (f1.dims == f2.dims) && (f1.type == f2.type) &&
        (f1.minfilter == f2.minfilter) && (f1.magfilter == f2.magfilter) &&
        (f1.repeat == f2.repeat) && (f1.mipmap == f2.mipmap)
end

"""
    BufferFormat(f1::BufferFormat, f2::BufferFormat)

Creates a new `BufferFormat` combining two given formats. For this the formats
need to be compatible, but not the same.

Rules:
- The output size is `dims = max(f1.dims, f2.dims)`
- Types must come from the same base type (AbstractFloat, Signed, Unsigned) where N0f8 counts as a float.
- The output type is the larger one of the two
- minfilter and magfilter must match (if one is :any, the other is used)
- repeat must match
- mipmap = true takes precedence
"""
function BufferFormat(f1::BufferFormat, f2::BufferFormat)
    if is_compatible(f1, f2)
        dims = max(f1.dims, f2.dims)
        type = BFT._promote(f1.type, f2.type)
        # currently don't allow different min/magfilters
        minfilter = ifelse(f1.minfilter == :any, f2.minfilter, f1.minfilter)
        magfilter = ifelse(f1.magfilter == :any, f2.magfilter, f1.magfilter)
        repeat = f1.repeat
        mipmap = f1.mipmap || f2.mipmap
        return BufferFormat(dims, type, minfilter, magfilter, repeat, mipmap)
    else
        error("Failed to merge BufferFormat: $f1 and $f2 are not compatible.")
    end
end

function is_compatible(f1::BufferFormat, f2::BufferFormat)
    return BFT.is_compatible(f1.type, f2.type) &&
        (f1.minfilter == :any || f2.minfilter == :any || f1.minfilter == f2.minfilter) &&
        (f1.magfilter == :any || f2.magfilter == :any || f1.magfilter == f2.magfilter) &&
        (f1.repeat == f2.repeat)
end

function format_to_type(format::BufferFormat)
    eltype = BFT.to_type(format.type)
    return format.dims == 1 ? eltype : Vec{format.dims, eltype}
end

is_depth_format(format::BufferFormat) = BFT.is_depth(format.type)
is_stencil_format(format::BufferFormat) = BFT.is_stencil(format.type)
is_depth_stencil_format(format::BufferFormat) = BFT.is_depth_stencil(format.type)