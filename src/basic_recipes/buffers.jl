#=
Buffers are just normal plots, with the benefit of being setup correctly to
efficiently append + push new values to them
=#

function LinesegmentBuffer(
        scene::SceneLike, ::Type{Point{N}} = Point{2};
        color = RGBAf[], linewidth = Float32[],
        kw_args...
    ) where N
    linesegments!(
        scene, Point{N, Float32}[]; color = color,
        linewidth = linewidth, kw_args...
    )
end

function append!(lsb::LineSegments, positions::Vector{Point{N, Float32}}; color = :black, linewidth = 1.0) where N
    thickv = same_length_array(positions, linewidth, key"linewidth"())
    colorv = same_length_array(positions, color, key"color"())
    append!(lsb[:arg1][], positions)
    append!(lsb[:color][], colorv)
    append!(lsb[:linewidth][], thickv)
    return
end

function push!(tb::LineSegments, positions::Point{N, Float32}; kw_args...) where N
    append!(tb, [positions]; kw_args...)
end

function start!(lsb::LineSegments)
    resize!(lsb[:arg1][], 0)
    resize!(lsb[:color][], 0)
    resize!(lsb[:linewidth][], 0)
    return
end

function finish!(lsb::LineSegments)
    # update the signal!
    ComputePipeline.mark_dirty_and_notify!(lsb[:arg1])
    ComputePipeline.mark_dirty_and_notify!(lsb[:color])
    ComputePipeline.mark_dirty_and_notify!(lsb[:linewidth])
    notify(lsb.attributes.onchange)
    return
end

function TextBuffer(
        scene::SceneLike, ::Type{Point{N}} = Point{2};
        rotation = [Quaternionf(0,0,0,1)],
        color = RGBAf[RGBAf(0,0,0,0)],
        fontsize = Float32[0],
        font = [defaultfont()],
        align = [Vec2f(0)],
        kw_args...
    ) where N
    text!(
        scene, [Point{N, Float32}(0)];
        text = String[" "],
        rotation = rotation,
        color = color,
        fontsize = fontsize,
        font = font,
        align = align,
        kw_args...
    )
end

function start!(tb::Text)
    attr = tb.attributes
    for key in (:arg1, :text, :color, :rotation, :fontsize, :font, :align)
        empty!(attr.inputs[key].value)
    end
    return
end

function finish!(tb::Text)
    # now update all callbacks
    attr = tb.attributes
    for key in (:arg1, :text, :color, :rotation, :fontsize, :font, :align)
        ComputePipeline.mark_dirty_and_notify!(attr.inputs[key])
    end
    if length(tb[1][]) != length(tb.fontsize[])
        error("Inconsistent buffer state for $(tb[1][])")
    end
    notify(attr.onchange)
    return
end

function push!(tb::Text, text::String, position::VecTypes{N}; kw_args...) where N
    append!(tb, [text], [position]; kw_args...)
end

function append!(tb::Text, text::Vector{String}, positions::Vector{<: VecTypes{N}}; kw_args...) where N
    attr = tb.attributes

    textv = same_length_array(positions, text)
    append!(attr.inputs[:text].value, textv)
    append!(attr.inputs[:arg1].value, positions)

    kw = Dict(kw_args)
    for key in (:color, :rotation, :fontsize, :font, :align)
        val = get(kw, key) do
            isempty(attr.inputs[key].value) && error("please provide default for $key")
            return last(attr.inputs[key].value)
        end
        val_vec = if key === :font
            same_length_array(positions, to_font(tb.fonts[], val))
        else
            same_length_array(positions, val, Key{key}())
        end
        append!(attr.inputs[key].value, val_vec)
    end
    return
end

function append!(tb::Text, text_positions::Vector{Tuple{String, <: VecTypes{N}}}; kw_args...) where N
    append!(tb, first.(text_positions), last.(text_positions); kw_args...)
    return
end
