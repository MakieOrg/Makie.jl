using TextParse
using TextParse: Record, Field, Numeric, tryparsenext

# Helper type to memory map a file as a string
struct MMapString{T} <: AbstractArray{T, 1}
    # using Type parameter, too lazy to write out the result type of mmap,
    # but also don't want to loose performance
    x::T
end
MMapString(path::String) = MMapString(Mmap.mmap(open(path), Vector{UInt8}))
# we only need to overload the iteration protocol for TextParse to work!
Base.getindex(x::MMapString, i) = Char(x.x[i])
Base.next(x::MMapString, i) = Char(x.x[i]), i + 1
Base.done(x::MMapString, i) = i > length(x.x)
Base.start(x::MMapString) = 1
Base.size(x::MMapString) = size(x.x)

# Base.write creates a mutable container (Ref) for its argument to savely pass it to C.
# Even Base.unsafe_write that directly takes a pointer still has a check that allocates 128 bytes.
# Be ready for unsafe_unsafe_write, short uuwrite.
# This saves us 40 seconds && 3.5 gb less memory allocation!
# This is actually a great example of how Julia currently fails, and how one can claw back the performance.
# We just call the C library directly and use the almost deprecated syntax (`&`) to directly take a pointer from the tuple.
# in Julia 0.7 this is likely no issue and we should be able to just use `write`,
# since the compiler got a lot better at stack allocating and eliminating mutable containers.
uuwrite(io, ptr::T) where T = Int(ccall(:ios_write, Csize_t, (Ptr{Void}, Ptr{T}, Csize_t), io.ios, &ptr, sizeof(T)))

function save2bin(path, n = typemax(Int))
    str = MMapString(path)
    # Parser descriptor of 'num,num\n' which is the format in the csv
    rec = Record((
        Field(Numeric(Float32), delim = ','),
        Field(Numeric(Float32), eoldelim = true)
    ))
    # skip the header...
    pos = findfirst(str, '\n') + 1 # Nice thing is Julia's findfirst works with any iterator
    io = open(homedir()*"/gpspoints.bin", "w")
    i = 0
    while !done(str, pos) && i <= n
        p_or_null, pos = tryparsenext(
            rec, str, pos, length(str)
        )
        isnull(p_or_null) && continue
        p = get(p_or_null)
        uuwrite(io, p)
        i += 1
    end
    close(io)
    i
end

tic()
save2bin(homedir() * "/Downloads/gps-points.csv");
toc()

"""
Transforms from longitude/latitude to pixel on screen, with `dims` refering to
the dimensions of the screen in pixel
"""
@inline function gps2pixel(point, dims)
    lon, lat = point[1], point[2]
    x = ((dims[1] / 180.0) * (90.0 + (lon / 10^7)))
    y = ((dims[2] / 360.0) * (180.0 - (lat / 10^7)))
    (x, y)
end

function to_image_inner!(img, points, start, stop)
    dims = size(img)
    for i = start:stop
        @inbounds begin
            p0 = gps2pixel(points[i], dims)
            idx = Int.(round.(p0))
            xidx, yidx = dims[1] - idx[1], dims[2] - idx[2]
            if checkbounds(Bool, img, xidx, yidx)
                # we should give each point a radius and then add the coverage to each pixel
                # for a smoother image
                # this does well enough for this short example:
                img[xidx, yidx] += 0.001f0
            end
        end
    end
end
function to_image!(img, points, range)
    N = length(range)
    NT = Threads.nthreads()
    slices = floor(Int, N / NT)
    offset = minimum(range)
    Threads.@threads for i = 1:NT
        # @threads creates a closure, which sometimes introduces type stabilities.
        # this is why it's a good practise to move the loop body behind a function barrier
        # (https://docs.julialang.org/en/latest/manual/performance-tips/#kernal-functions-1)
        to_image_inner!(img, points, offset + ((i-1) * slices + 1), offset + (i * slices))
    end
    return img
end

# Simply saving the image
using FileIO, Colors
img = zeros(Float32, 600, 960)
io = open(homedir() * "/gpspoints.bin")
points = Mmap.mmap(io, Vector{NTuple{2, Float32}})
tic()
to_image!(img, points, 1:length(points))
toc()
FileIO.save("gps.png", Gray.(clamp.(1f0 .- img, 0, 1)))
close(io)

# Or an interactive version
using Makie, Images
io = open(homedir() * "/gpspoints.bin")
# Now that we have the data as a binary blob, we can just memory map
# it as a Vector of points (NTuple{2, Float32})
points = Mmap.mmap(io, Vector{NTuple{2, Float32}})
resolution = (600, 960)
scene = Scene(resolution = reverse(resolution))
img = zeros(Float32, resolution)
imviz = heatmap(img, colornorm = (0, 1))
center!(scene)
fill!(img, 0f0)
slice = 10^7
range = slice:slice:length(points)
stop = 1
vio = VideoStream(scene, homedir()*"/Desktop/", "gps")
while true
    start = stop
    stop = min(stop + slice, length(points))
    to_image!(img, points, start:stop)
    imviz[:heatmap] = img # update image in place
    recordframe!(vio)
    stop == length(points) && break
end
finish(vio, "gif") # finish streaming and export as gif!


using Matcha


function test(str, pattern)
    res = matchat(str, 1, pattern)
    for i = 2:length(str)
        match, res = matchat(str, i, pattern)
        match && return res
    end
    res
end

mf(x) = x in ('h', 'y', 'e')

str = MMapString(homedir() * "/gpspoints.bin")

pattern = (Greed(x-> x in ('h', 'y', 'e'), 3:3),)
@time matchone(str, pattern)
