using CRC32c

# Seems like crc32c is slow enough, that it's worthwhile to memoize the hashes
const MEMOIZED_HASHES = Dict{Tuple{UInt64, String}, UInt32}()

function fast_stable_hash(x::Tuple{UInt64, String})
    return get!(MEMOIZED_HASHES, x) do
        return hash_crc32(x)
    end
end

# Anything writeable to IO can be hashed
function hash_crc32(arrays::Union{AbstractVector, Tuple})
    io = IOBuffer()
    for array in arrays
        write(io, array)
    end
    seekstart(io)
    return CRC32c.crc32c(io)
end
