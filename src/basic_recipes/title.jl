"""
    title(titletext, scene)

Create a `title` for `scene`. Note that the title is not automatically added to `scene`. Instead [`hbox`](@ref) can be used for this. Alternatively [`addtitle`](@ref) does create a title and add it to the scene.
"""
@recipe(Title, scene, string) do s
    t = default_theme(s, Text)
    t[:align] = (:center, :bottom)
    t
end

function AbstractPlotting.plot!(t::Title)
    @extract t (scene, string, align, alpha, color, font,
                linewidth, overdraw, rotation,
                strokecolor, strokewidth,
                textsize, transparency, visible)

    # scene is the scene in need of a title. It is not the scene which contains
    # the title in the end.
    s = to_value(scene)
    pos = lift(pixelarea(s)) do area
        x = widths(area)[1] ./ 2
        Vec2f0(x, 10) # offset 10px, to give it some space
    end

    text!(t.parent,
        string,
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
    t = title(scene, string; kw...)
    hbox(scene, t)
end

function addtitle(string; kw...)
    scene = current_scene()
    addtitle(scene, string; kw...)
end
