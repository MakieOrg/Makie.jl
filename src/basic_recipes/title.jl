@recipe(Title, titletext, plot) do scene
    t = default_theme(scene, Text)
    t[:align] = (:center, :bottom)
    t
end

function AbstractPlotting.plot!(t::Title)
    @extract t (titletext, plot, align, alpha, color, font,
                linewidth, overdraw, rotation,
                strokecolor, strokewidth,
                textsize, transparency, visible)

    plot = to_value(plot)
    pos = lift(pixelarea(plot)) do area
        x = widths(area)[1] ./ 2
        Vec2f0(x, 10) # offset 10px, to give it some space
    end

    text!(t.parent,
        titletext,
        position = pos, 
        camera=campixel!,
        raw=true,
        align=align,
        alpha=alpha, color=color, font=font, linewidth=linewidth, overdraw=overdraw, rotation=rotation,
        strokecolor= strokecolor, strokewidth=strokewidth, textsize=textsize, transparency=transparency, visible=visible
        )
end
