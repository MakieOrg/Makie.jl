export addtitle

"""
    title(titletext, plot)

Create a `title` for `plot`. Note that the title is not automatically added to `plot`. Instead [`hbox`](@ref) can be used for this. Alternatively the [`addtitle`](@ref) convenience does create a title and add it to the plot.
"""
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

"""
    addtitle([scene=current_scene(), ], string; kw...)

Add a title with content `string` to `scene`.
"""
function addtitle(scene, string; kw...)
    t = title(string, scene; kw...)
    hbox(scene, t)
end # works

function addtitle(string; kw...)
    scene = current_scene()
    addtitle(scene, string; kw...)
end
