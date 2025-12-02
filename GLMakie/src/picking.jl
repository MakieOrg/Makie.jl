################################################################################
### Point picking
################################################################################

function pick_native(screen::Screen, rect::Rect2i)
    isopen(screen) || return Matrix{SelectionID{Int}}(undef, 0, 0)
    gl_switch_context!(screen.glscreen)
    fb = screen.framebuffer
    buff = fb.buffers[:objectid]
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1])
    glReadBuffer(GL_COLOR_ATTACHMENT1)
    rx, ry = minimum(rect)
    rw, rh = widths(rect)
    w, h = size(screen.scene)
    ppu = screen.px_per_unit[]
    if rx >= 0 && ry >= 0 && rx + rw <= w && ry + rh <= h
        rx, ry, rw, rh = round.(Int, ppu .* (rx, ry, rw, rh))
        sid = zeros(SelectionID{UInt32}, rw, rh)
        glReadPixels(rx, ry, rw, rh, buff.format, buff.pixeltype, sid)
        return sid
    else
        error("Pick region $rect out of screen bounds ($w, $h).")
    end
end

function pick_native(screen::Screen, xy::Vec{2, Float64})
    isopen(screen) || return SelectionID{Int}(0, 0)
    gl_switch_context!(screen.glscreen)
    fb = screen.framebuffer
    buff = fb.buffers[:objectid]
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1])
    glReadBuffer(GL_COLOR_ATTACHMENT1)
    x, y = floor.(Int, xy)
    w, h = size(screen.scene)
    ppu = screen.px_per_unit[]
    if x > 0 && y > 0 && x <= w && y <= h
        x, y = round.(Int, ppu .* (x, y))
        sid = Base.RefValue{SelectionID{UInt32}}()
        glReadPixels(x, y, 1, 1, buff.format, buff.pixeltype, sid)
        return convert(SelectionID{Int}, sid[])
    end
    return SelectionID{Int}(0, 0)
end

function Makie.pick(scene::Scene, screen::Screen, xy::Vec{2, Float64})
    sid = pick_native(screen, xy)
    if haskey(screen.cache2plot, sid.id)
        plot = screen.cache2plot[sid.id]
        return (plot, sid.index)
    else
        return (nothing, 0)
    end
end

function Makie.pick(scene::Scene, screen::Screen, rect::Rect2i)
    return map(pick_native(screen, rect)) do sid
        if haskey(screen.cache2plot, sid.id)
            (screen.cache2plot[sid.id], sid.index)
        else
            (nothing, sid.index)
        end
    end
end


# Skips one set of allocations
function Makie.pick_closest(scene::Scene, screen::Screen, xy, range)
    isopen(screen) || return (nothing, 0)
    w, h = size(screen.scene) # unitless dimensions
    ((1.0 <= xy[1] <= w) && (1.0 <= xy[2] <= h)) || return (nothing, 0)

    fb = screen.framebuffer
    ppu = screen.px_per_unit[]
    w, h = size(fb) # pixel dimensions
    x0, y0 = max.(1, floor.(Int, ppu .* (xy .- range)))
    x1, y1 = min.((w, h), ceil.(Int, ppu .* (xy .+ range)))
    dx = x1 - x0; dy = y1 - y0

    gl_switch_context!(screen.glscreen)
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1])
    glReadBuffer(GL_COLOR_ATTACHMENT1)
    buff = fb.buffers[:objectid]
    sids = zeros(SelectionID{UInt32}, dx, dy)
    glReadPixels(x0, y0, dx, dy, buff.format, buff.pixeltype, sids)

    min_dist = ppu * ppu * range * range
    id = SelectionID{Int}(0, 0)
    x, y = xy .* ppu .+ 1 .- Vec2f(x0, y0)
    for i in 1:dx, j in 1:dy
        d = (x - i)^2 + (y - j)^2
        sid = sids[i, j]
        if (d < min_dist) && (sid.id > 0) && haskey(screen.cache2plot, sid.id)
            min_dist = d
            id = convert(SelectionID{Int}, sid)
        end
    end

    if haskey(screen.cache2plot, id.id)
        return (screen.cache2plot[id.id], id.index)
    else
        return (nothing, 0)
    end
end

# Skips some allocations
function Makie.pick_sorted(scene::Scene, screen::Screen, xy, range)
    isopen(screen) || return Tuple{AbstractPlot, Int}[]
    w, h = size(screen.scene) # unitless dimensions
    if !((1.0 <= xy[1] <= w) && (1.0 <= xy[2] <= h))
        return Tuple{AbstractPlot, Int}[]
    end

    fb = screen.framebuffer
    ppu = screen.px_per_unit[]
    w, h = size(fb) # pixel dimensions
    x0, y0 = max.(1, floor.(Int, ppu .* (xy .- range)))
    x1, y1 = min.((w, h), ceil.(Int, ppu .* (xy .+ range)))
    dx = x1 - x0; dy = y1 - y0

    gl_switch_context!(screen.glscreen)
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1])
    glReadBuffer(GL_COLOR_ATTACHMENT1)
    buff = fb.buffers[:objectid]
    picks = zeros(SelectionID{UInt32}, dx, dy)
    glReadPixels(x0, y0, dx, dy, buff.format, buff.pixeltype, picks)

    selected = filter(x -> x.id > 0 && haskey(screen.cache2plot, x.id), unique(vec(picks)))
    distances = Float32[floatmax(Float32) for _ in selected]
    x, y = xy .* ppu .+ 1 .- Vec2f(x0, y0)
    for i in 1:dx, j in 1:dy
        if picks[i, j].id > 0
            d = (x - i)^2 + (y - j)^2
            idx = findfirst(isequal(picks[i, j]), selected)
            if idx === nothing
                continue
            elseif distances[idx] > d
                distances[idx] = d
            end
        end
    end

    idxs = sortperm(distances)
    permute!(selected, idxs)
    return map(id -> (screen.cache2plot[id.id], id.index), selected)
end
