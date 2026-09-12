using Mmap, TextParse
using TextParse: Record, Field, Numeric, tryparsenext, isnull

struct MMapString{T} <: AbstractVector{Char}
    x::T
end
MMapString(path::String) = MMapString(Mmap.mmap(open(path), Vector{UInt8}))
# we only need to overload the iteration protocol for TextParse to work!
Base.Base.@propagate_inbounds Base.getindex(x::MMapString, i) = Char(x.x[i])
Base.Base.@propagate_inbounds function Base.iterate(x::MMapString, state...)
    result = iterate(x.x, state...)
    result === nothing && return nothing
    return Char(result[1]), result[2]
end
Base.length(x::MMapString) = length(x.x)
Base.size(x::MMapString) = (length(x),)

# less generic, but faster version of Base.write
function uuwrite(io, ref::Base.RefValue{T}) where {T}
    return ccall(:ios_write, Csize_t, (Ptr{Nothing}, Ptr{T}, Csize_t), io.ios, ref, sizeof(T))
end

function save2bin(path, n=typemax(Int))
    str = MMapString(path)
    # Parser descriptor of 'num,num,num\n' which is the format in the csv
    rec = Record((Field(Numeric(Float32)),
                  Field(Numeric(Float32)),
                  Field(Numeric(Float32); eoldelim=true)))
    # skip the header...
    pos = findfirst(x -> x == '\n', str) + 1 # Nice thing is Julia's findfirst works with any iterator
    io = open("gpspoints.bin", "w")
    ref = Base.RefValue{NTuple{2,Float32}}()
    @inbounds while pos < length(str)
        p_or_null, pos = tryparsenext(rec, str, pos, length(str))
        isnull(p_or_null) && continue
        t = get(p_or_null)
        ref[] = (t[1], t[2])
        uuwrite(io, ref)
    end
    return close(io)
end

# Download csv from https://planet.osm.org/gps/simple-gps-points-120604.csv.xz
path = "simple-gps-points-120604.csv"

@time save2bin(path); # 370s
using Mmap
path = "gpspoints.bin"
points = Mmap.mmap(open(path, "r"), Vector{Point2f});
# ~ 26s
@time begin
    f, ax, pl = datashader(points;
                           # For a big dataset its interesting to see how long each aggregation takes
                           show_timings=true,
                           # Use a local operation which is faster to calculate and looks good!
                           local_post=x -> log10(x + 1),
                           #=
                               in the code we used to save the binary, we had the points in the wrong order.
                               A good chance to demonstrate the `point_func` argument,
                               Which gets applied to every point before aggregating it
                           =#
                           point_func=reverse,
                           axis=(; type=Axis, autolimitaspect=1),
                           figure=(; figure_padding=0, resolution=(1200, 600)))
    hidedecorations!(ax)
    hidespines!(ax)
    display(f)
end
