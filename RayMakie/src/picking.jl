# Picking reads the metadata of the last completed raster frame. It never
# changes the camera, advances animation or renders an extra geometry pass.

function raster_pick_data(screen::Screen)
    data = screen.fb_readback_buf
    data === nothing && return nothing
    return data.frame
end

function decode_pick(frame, value)
    id = Int(value[1] >> 1)
    1 <= id <= length(frame.plots) || return (nothing, 0)
    return (frame.plots[id], Int(value[2]))
end

function Makie.pick(scene::Scene, screen::Screen, xy::Vec{2, Float64})
    frame = raster_pick_data(screen)
    return pick_frame(frame, xy)
end

"Read one pixel from a completed raster view, in that view's logical coordinates."
function pick_frame(frame, xy)
    frame === nothing && return (nothing, 0)
    w, h = frame.size
    ppu = frame.ppu
    all(isfinite, xy) || return (nothing, 0)
    x, y = floor.(Int, ppu .* xy)
    0 <= x < w && 0 <= y < h || return (nothing, 0)
    index = (h - 1 - y) * w + x + 1
    value = only(Array(view(Mantle.storage(frame.pixels), index:index)))
    return decode_pick(frame, value)
end

function Makie.pick(scene::Scene, screen::Screen, rect::Rect2i)
    frame = raster_pick_data(screen)
    frame === nothing && return Matrix{Tuple{Union{Nothing, Plot}, Int}}(undef, 0, 0)
    w, h = frame.size
    x, y = rect.origin; rw, rh = rect.widths
    ppu = frame.ppu
    x0, y0 = floor.(Int, ppu .* (x, y));x1, y1 = ceil.(Int, ppu .* (x + rw, y + rh)) .- 1
    0 <= x0 <= x1 < w && 0 <= y0 <= y1 < h ||
        throw(ArgumentError("pick region $rect lies outside the displayed frame"))
    pixels = reshape(Mantle.storage(frame.pixels), w, h)
    values = Array(view(pixels, (x0 + 1):(x1 + 1), (h - y1):(h - y0)))
    return map(value -> decode_pick(frame, value), reverse(values; dims = 2))
end

function Makie.pick_closest(scene::Scene, screen::Screen, xy, range)
    results = Makie.pick_sorted(scene, screen, xy, range)
    return isempty(results) ? (nothing, 0) : first(results)
end

function Makie.pick_sorted(scene::Scene, screen::Screen, xy, range)
    frame = raster_pick_data(screen)
    frame === nothing && return Tuple{Plot, Int}[]
    range >= 0 || throw(ArgumentError("picking range must be nonnegative"))
    w, h = floor.(Int, frame.size ./ frame.ppu)
    x0, y0 = max.(0, floor.(Int, xy .- range))
    x1, y1 = min.((w, h), ceil.(Int, xy .+ range .+ 1))
    x1 > x0 && y1 > y0 || return Tuple{Plot, Int}[]
    results = Makie.pick(scene, screen, Rect2i(x0, y0, x1 - x0, y1 - y0))
    distances = Dict{Tuple{Plot, Int}, Float64}()
    for i in CartesianIndices(results)
        results[i][1] === nothing && continue
        pos = (Vec2f(floor.(Int, frame.ppu .* (x0, y0))) + Vec2f(Tuple(i) .- 1)) ./ frame.ppu
        d = sum(abs2, pos - xy)
        d <= range^2 || continue
        distances[results[i]] = min(get(distances, results[i], Inf), d)
    end
    return sort!(collect(keys(distances)); by = p -> distances[p])
end
