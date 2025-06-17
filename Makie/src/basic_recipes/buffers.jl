#=
Buffers are just normal plots, with the benefit of being setup correctly to
efficiently append + push new values to them
=#

function LinesegmentBuffer(
        scene::SceneLike, ::Type{Point{N}} = Point{2};
        color = RGBAf[], linewidth = Float32[],
        kw_args...
    ) where {N}
    return linesegments!(
        scene, Point{N, Float32}[]; color = color,
        linewidth = linewidth, kw_args...
    )
end

function append!(lsb::LineSegments, positions::Vector{Point{N, Float32}}; color = :black, linewidth = 1.0) where {N}
    attr = lsb.attributes
    thickv = same_length_array(positions, linewidth, key"linewidth"())
    colorv = same_length_array(positions, color, key"color"())
    append!(attr.inputs[:arg1].value, positions)
    append!(attr.inputs[:color].value, colorv)
    append!(attr.inputs[:linewidth].value, thickv)
    return
end

function push!(tb::LineSegments, positions::Point{N, Float32}; kw_args...) where {N}
    return append!(tb, [positions]; kw_args...)
end

function start!(lsb::LineSegments)
    attr = lsb.attributes
    resize!(attr.inputs[:arg1].value, 0)
    resize!(attr.inputs[:color].value, 0)
    resize!(attr.inputs[:linewidth].value, 0)
    return
end

function finish!(lsb::LineSegments)
    # update the signal!
    attr = lsb.attributes
    ComputePipeline.mark_dirty!(attr.inputs[:arg1])
    ComputePipeline.mark_dirty!(attr.inputs[:color])
    ComputePipeline.mark_dirty!(attr.inputs[:linewidth])
    ComputePipeline.update_observables!(attr)
    return
end

function TextBuffer(
        scene::SceneLike, ::Type{Point{N}} = Point{2};
        rotation = [Quaternionf(0, 0, 0, 1)],
        color = RGBAf[RGBAf(0, 0, 0, 0)],
        fontsize = Float32[0],
        font = [defaultfont()],
        align = [Vec2f(0)],
        kw_args...
    ) where {N}
    return text!(
        scene, tuple.(String[" "], [Point{N, Float32}(0)]);
        rotation = rotation,
        color = color,
        fontsize = fontsize,
        font = font,
        align = align,
        kw_args...
    )
end

function start!(tb::Makie.Text)
    attr = tb.attributes
    for key in (:arg1, :color, :rotation, :fontsize, :font, :align)
        empty!(attr.inputs[key].value)
    end
    return
end

function finish!(tb::Makie.Text)
    attr = tb.attributes
    # now update all callbacks
    if length(attr.inputs[:arg1].value) != length(attr.inputs[:fontsize].value)
        error("Inconsistent buffer state for $(attr.inputs[:arg1].value)")
    end
    for key in (:arg1, :text, :color, :rotation, :fontsize, :font, :align)
        ComputePipeline.mark_dirty!(attr.inputs[key])
    end
    ComputePipeline.update_observables!(attr)
    return
end

function push!(tb::Makie.Text, text::String, position::VecTypes{N}; kw_args...) where {N}
    return append!(tb, [(String(text), Point{N, Float32}(position))]; kw_args...)
end

function append!(tb::Makie.Text, text::Vector{String}, positions::Vector{Point{N, Float32}}; kw_args...) where {N}
    text_positions = convert_arguments(Makie.Text, tuple.(text, positions))[1]
    append!(tb, text_positions; kw_args...)
    return
end

function append!(tb::Makie.Text, text_positions::Vector{Tuple{String, Point{N, Float32}}}; kw_args...) where {N}
    attr = tb.attributes
    append!(attr.inputs[:arg1].value, text_positions)
    kw = Dict(kw_args)
    for key in (:color, :rotation, :fontsize, :font, :align)
        val = get(kw, key) do
            isempty(attr.inputs[key].value) && error("please provide default for $key")
            return last(attr.inputs[key].value)
        end
        val_vec = if key === :font
            same_length_array(text_positions, to_font(tb.fonts[], val))
        else
            same_length_array(text_positions, val, Key{key}())
        end
        append!(attr.inputs[key].value, val_vec)
    end
    return
end

function append!(tb::Text, text_positions::Vector{Tuple{String, <:VecTypes{N}}}; kw_args...) where {N}
    append!(tb, first.(text_positions), last.(text_positions); kw_args...)
    return
end
