
function readline!(io, buffer)
    i = 1
    while !eof(io) && !done(buffer, i)
        elem = read(io, UInt8)
        if elem == UInt8('\n')
            return i
        end
        buffer[i] = elem
        i += 1
    end
    return 0
end

function parse_line(io, stringwrap, buffer)
    nbytes = readline!(io, buffer)
    l = findfirst(buffer, UInt8(','))
    f1 = parse(Float32, SubString(stringwrap, 1, (l - 1)))
    l2 = findnext(buffer, UInt8(','), l + 1)
    f2 = parse(Float32, SubString(stringwrap, l+1, l2-1))
    Point2f0(f1, f2)
end

io = open()
readline(io)

using GeometryTypes, BenchmarkTools

function getbb(io)
    bb = HyperRectangle{2, Float32}()
    seekstart(io)
    readline(io)
    str = String("0"^(12*3+3))
    buffer = Vector{UInt8}(str)
    while !eof(io)
        p = parse_line(io, str, buffer)
        bb = update(bb, Vec2f0(p))
    end
    return bb
end
bb = getbb(io)

Point2f0(8, 8f9), Point2f0(1.80901f9, 3.6f9)

@btime parse_line($io, $str, $buffer)

using TextParse, GeometryTypes
using TextParse: Record, Field, Numeric, tryparsenext
immutable MMapString{T}
    x::T
end
MMapString(io::IO) = MMapString(Mmap.mmap(io, Vector{UInt8}))
MMapString(path::String) = MMapString(Mmap.mmap(open(path), Vector{UInt8}))
Base.next(x::MMapString, i) = Char(x.x[i]), i + 1
Base.done(x::MMapString, i) = i > length(x.x)
Base.start(x::MMapString, i) = 1
Base.length(x::MMapString) = length(x.x)

function to_newline(x::MMapString, pos)
    while !done(x, pos)
        elem, pos = next(x, pos)
        elem == '\n' && return pos
    end
    pos
end
str = MMapString(homedir() * "/Downloads/gpspoints.csv")

function parse_line(io, rec, pos)
    pos = to_newline(io, pos)
    field, pos = tryparsenext(rec, io, pos, pos + (13*3+3))
    p = get(field)
    x = (180 + p[1])) / 360
    y = (90 - p[2])) / 180
    Point2f0(p[1], p[2]), pos # to newline since there is a 3rd coordinate which is always 0, which I don't want to parse
end


function getpoints(io, n = ((10^6) * 10))
    rec = Record((Field(Numeric(Float32), delim = ','), Field(Numeric(Float32), eoldelim=true)))
    pos = to_newline(io, 1) # skip first line which is the header
    points = Vector{Point2f0}(n)
    for i = 1:n
        p, pos = parse_line(io, rec, pos)
        points[i] = p
    end
    return points
end

function getbb(io, n = ((10^6) * 10))
    rec = Record((Field(Numeric(Float32), delim = ','), Field(Numeric(Float32), eoldelim=true)))
    pos = to_newline(io, 1)
    bb = HyperRectangle{2, Float32}()
    for i = 1:n
        p, pos = parse_line(io, rec, pos)
        bb = update(bb, Vec2f0(p))
    end
    return bb
end

bb = getbb(str, 10^8)

function to_image(io, bb, n = ((10^6) * 10))
    dims = 2^12, 2^12
    img = zeros(Float32, dims)
    dimsf0 = Point2f0(dims) .- 1f0
    rec = Record((Field(Numeric(Float32), delim = ','), Field(Numeric(Float32), eoldelim=true)))
    pos = to_newline(io, 1)
    mini, w = minimum(bb), widths(bb)
    for i = 1:n
        p, pos = parse_line(io, rec, pos)
        p0 = (((p .- mini) ./ w) .* dimsf0) .+ 1f0
        idxf0 = round.(p0)
        frac = norm((idxf0 .- p0))
        idx = Int.(idxf0)
        @inbounds img[idx[1], idx[2]] += frac
    end
    return img
end
@time to_image(str, bb, 10^7)
sizeof(img) / 10^6
Profile.print()
nothing

nothing

using MakiE

scene = Scene()


bb = HyperRectangle{2, Float32}(AABB(points))
function getsmall(points, bb)
    points_small = map(points) do p 
        mini = 
        ((p .- minimum(bb)) ./ widths(bb)) .* 1000f0
    end
end
points_small = getsmall(points, bb)
AABB(points_small)
using MakiE
scene = Scene()
img2 = clamp.(img, 0f0, 1f0)
heatmap(img2)
center!(scene)
nothing
extrema(img)
mean(img2)