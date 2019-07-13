
"""
    title(
        [scene=current_scene(), ], string;
        align = (:center, :bottom), textsize = 30, kw...
    )

Add a title with content `string` to `scene`.
"""
function title(scene, string; align = (:center, :bottom), textsize = 30, kw...)
    pos = lift(pixelarea(scene)) do area
        x = widths(area)[1] ./ 2
        Vec2f0(x, 10) # offset 10px, to give it some space
    end
    t = text(
        string,
        position = pos,
        camera = campixel!,
        raw = true, align = align,
        textsize = textsize;
        kw...
    )
    hbox(scene, t)
end

function title(string; kw...)
    scene = current_scene()
    title(scene, string; kw...)
end
