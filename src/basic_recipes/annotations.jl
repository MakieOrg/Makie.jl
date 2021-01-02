"""
    annotations(strings::Vector{String}, positions::Vector{Point})

Plots an array of texts at each position in `positions`.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Annotations, text, position) do scene
    default_theme(scene, Text)
end

function convert_arguments(::Type{<: Annotations},
                           strings::AbstractVector{<: AbstractString},
                           text_positions::AbstractVector{<: Point{N}}) where N
    return (map(strings, text_positions) do str, pos
        (String(str), Point{N, Float32}(pos))
    end,)
end

function plot!(plot::Annotations)
    sargs = (
        plot.model, plot.font,
        plot[1],
        getindex.(plot, (:color, :textsize, :align, :rotation, :justification, :lineheight))...,
    )
    atlas = get_texture_atlas()
    combinedpos = [Point3f0(0)]
    colors = RGBAf0[RGBAf0(0,0,0,0)]
    textsize = Float32[0]
    fonts = [defaultfont()]
    rotations = Quaternionf0[Quaternionf0(0,0,0,0)]

    tplot = text!(plot, " ",
        align = Vec2f0(0), model = Mat4f0(I),
        position = combinedpos, color = colors, visible = plot.visible,
        textsize = textsize, font = fonts, rotation = rotations
    )

    onany(sargs...) do model, pfonts, text_pos, args...
        io = IOBuffer();
        empty!(combinedpos); empty!(colors); empty!(textsize); empty!(fonts); empty!(rotations)
        broadcast_foreach(1:length(text_pos), to_font(pfonts), text_pos, args...) do idx, f,
                (text, startpos), color, tsize, alignment, rotation, justification, lineheight
            c = to_color(color)
            rot = to_rotation(rotation)
            pos = layout_text(text, startpos, tsize, f, alignment, rot, model, justification, lineheight)
            print(io, text)
            n = length(pos)
            append!(combinedpos, pos)
            append!(textsize, repeated(tsize, n))
            append!(colors, repeated(c, n))
            append!(fonts, one_attribute_per_char(f, text))
            append!(rotations, repeated(rot, n))
        end
        str = String(take!(io))
        # update string the signals
        tplot[1] = str
        return
    end
    # update one time in the beginning, since otherwise the above won't run
    notify!(sargs[1])
    plot
end
