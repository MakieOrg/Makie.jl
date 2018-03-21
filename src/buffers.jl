function LinesegmentBuffer(
        scene::Scene, ::Type{Point{N}} = Point{2};
        color = RGBAf0[], linewidth = Float32[], raw = true
    ) where N
    linesegments!(scene, Point{N, Float32}[]; color = color, linewidth = linewidth, raw = raw)
end

function Base.append!(lsb::Linesegments, positions::Vector{Point{N, Float32}}; color = :black, linewidth = 1.0) where N
    thickv = same_length_array(positions, linewidth, key"linewidth"())
    colorv = same_length_array(positions, color, key"color"())
    append!(lsb.args[1][], positions)
    append!(lsb[:color][], colorv)
    append!(lsb[:linewidth][], thickv)
    return
end

function Base.push!(tb::Linesegments, positions::Point{N, Float32}; kw_args...) where N
    append!(tb, [positions]; kw_args...)
end

function start!(lsb::Linesegments)
    resize!(lsb.args[1][], 0)
    resize!(lsb[:color][], 0)
    resize!(lsb[:linewidth][], 0)
    return
end

function finish!(lsb::Linesegments)
    # update the signal!
    lsb.args[1][] = lsb.args[1][]
    lsb[:color][] = lsb[:color][]
    lsb[:linewidth][] = lsb[:linewidth][]
    return
end

function TextBuffer(
        scene, ::Type{Point{N}} = Point{2};
        rotation = Vec4f0[(0,0,0,1)],
        color = RGBAf0[RGBAf0(0,0,0,0)],
        textsize = Float32[0],
        camera = :false,
        font = [attribute_convert("default", key"font"())],
        align = [Vec2f0(0)],
        raw = true
    ) where N
    annotations!(
        scene, String[" "], Point{N, Float32}[(0, 0)],
        rotation = rotation,
        color = color,
        textsize = textsize,
        font = font,
        align = align,
        raw = raw
    )
end

function start!(tb::Annotations)
    for i = 1:2
        resize!(tb.args[i][], 0)
    end
    for key in (:color, :rotation, :textsize, :font, :align)
        resize!(tb[key][], 0)
    end
    return
end

function finish!(tb::Annotations)
    # update the signal!
    for i = 1:2
        tb.args[i][] = tb.args[i][]
    end
    for key in (:color, :rotation, :textsize, :font, :align)
        tb[key][] = tb[key][]
    end
    return
end


function Base.push!(tb::Annotations, text::String, position; kw_args...)
    N = length(position)
    append!(tb, [text], Point{N, Float32}[position]; kw_args...)
end
function Base.append!(tb::Annotations, text::Vector{String}, positions::Vector{Point{N, Float32}}; kw_args...) where N
    append!(tb.args[1][], text)
    append!(tb.args[2][], positions)
    kw = Dict(kw_args)
    for key in (:color, :rotation, :textsize, :font, :align)
        val = get(kw, key) do
            isempty(tb[key][]) && error("plz provide default for $key")
            last(tb[key][])
        end
        val_vec = same_length_array(text, val, Key{key}())
        append!(tb[key][], val_vec)
    end
    return
end
