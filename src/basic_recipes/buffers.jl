#=
Buffers are just normal plots, with the benefit of being setup correctly to
efficiently append + push new values to them
=#

function LinesegmentBuffer(
        scene::SceneLike, ::Type{Point{N}} = Point{2};
        color = RGBAf0[], linewidth = Float32[], raw = true,
        kw_args...
    ) where N
    linesegments!(
        scene, Point{N, Float32}[]; color = color,
        linewidth = linewidth, raw = raw, kw_args...
    ).plots[end]
end

function append!(lsb::LineSegments, positions::Vector{Point{N, Float32}}; color = :black, linewidth = 1.0) where N
    thickv = same_length_array(positions, linewidth, key"linewidth"())
    colorv = same_length_array(positions, color, key"color"())
    append!(lsb[1][], positions)
    append!(lsb[:color][], colorv)
    append!(lsb[:linewidth][], thickv)
    return
end

function push!(tb::LineSegments, positions::Point{N, Float32}; kw_args...) where N
    append!(tb, [positions]; kw_args...)
end

function start!(lsb::LineSegments)
    resize!(lsb[1][], 0)
    resize!(lsb[:color][], 0)
    resize!(lsb[:linewidth][], 0)
    return
end

function finish!(lsb::LineSegments)
    # update the signal!
    lsb[1][] = lsb[1][]
    lsb[:color][] = lsb[:color][]
    lsb[:linewidth][] = lsb[:linewidth][]
    # Yield to allow Reactive to update values...
    # TODO checkout if this is the savest and best way
    return
end

function TextBuffer(
        scene::SceneLike, ::Type{Point{N}} = Point{2};
        rotation = [Quaternionf0(0,0,0,1)],
        color = RGBAf0[RGBAf0(0,0,0,0)],
        textsize = Float32[0],
        font = [to_font("default")],
        align = [Vec2f0(0)],
        raw = true,
        kw_args...
    ) where N
    annotations!(
        scene, String[" "], [Point{N, Float32}(0)];
        rotation = rotation,
        color = color,
        textsize = textsize,
        font = font,
        align = align,
        raw = raw,
        kw_args...
    ).plots[end]
end

function start!(tb::Annotations)
    for i = 1:2
        resize!(tb[i][], 0)
    end
    for key in (:color, :rotation, :textsize, :font, :align)
        resize!(tb[key][], 0)
    end
    return
end

function finish!(tb::Annotations)
    #update the signal!
    for i = 1:2
        tb[i][] = tb[i][]
    end
    for key in (:color, :rotation, :textsize, :font, :align)
        tb[key][] = tb[key][]
    end
    return
end


function push!(tb::Annotations, text::String, position; kw_args...)
    N = length(position)
    append!(tb, [text], Point{N, Float32}[position]; kw_args...)
end

function append!(tb::Annotations, text::Vector{String}, positions::Vector{Point{N, Float32}}; kw_args...) where N
    append!(tb[1][], text)
    append!(tb[2][], positions)
    kw = Dict(kw_args)
    for key in (:color, :rotation, :textsize, :font, :align)
        val = get(kw, key) do
            isempty(tb[key][]) && error("please provide default for $key")
            last(tb[key][])
        end
        val_vec = same_length_array(text, val, Key{key}())
        append!(tb[key][], val_vec)
    end
    return
end
