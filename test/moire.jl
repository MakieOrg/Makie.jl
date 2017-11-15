using GeometryTypes
using Makie, Colors

struct Ring
    movement::Float32
    radius::Float32
    speed::Float32
    spin::Vec2f0
end
function cartesian(ll::Point2)
    return Point3(
        cos(ll[1]) * sin(ll[2]),
        sin(ll[1]) * sin(ll[2]),
        cos(ll[2])
    )
end
fract(x) = x - floor(x)
function positions(rings, index, time, audio)
    position = Point3f0(0.0)
    precision = 0.2f0
    for ring in rings
        position += ring.radius * cartesian(
            precision *
            index *
            Point2f0(ring.spin + Point2f0(sin(time * ring.speed), cos(time * ring.speed)) * ring.movement)
        )
    end
    amplitude = audio[round(Int, clamp(fract(position[1] * 0.1), 0, 1) * (25000-1)) + 1]; # index * 0.002
    position *= 1.0 + amplitude * 0.5;
    position
end
scene = Scene()
rings = [Ring(0.1, 1.0, 0.00001, (0.2, 0.1)), Ring(0.1, 0.0, 0.0002, (0.052, 0.05))]
N = 25000
t_audio = sin.(linspace(0, 10pi, N)) .+ (cos.(linspace(-3, 7pi, N)) .* 0.6) .+ (rand(Float32, N) .* 0.1) ./ 2f0
start = time()
t = (time() - start) * 100
pos = positions.((rings,), 1:N, t, (t_audio,))
l = lines(pos, color = map(x-> RGBA{Float32}(x, 0.6), colormap("RdBu", N)), thickness = 0.6f0)
center!(scene)
io = VideoStream(scene, homedir() * "/Desktop/", "moire")
for i = 1:1000
    t = (time() - start) * 100
    pos .= positions.((rings,), 1:N, t, (t_audio,))
    l[:positions] = pos
    recordframe!(io)
    sleep(1/60)
end
finish(io, "mp4")
