
"""
    addtitle([scene=current_scene(), ], string; kw...)

Add a title with content `string` to `scene`.
"""
function addtitle(scene, string; align = (:center, :bottom), kw...)
    pos = lift(pixelarea(s)) do area
        x = widths(area)[1] ./ 2
        Vec2f0(x, 10) # offset 10px, to give it some space
    end
    t = text(
        string,
        position = pos,
        camera = campixel!,
        raw = true, align = align;
        kw...
    )
    hbox(scene, t)
end

function addtitle(string; kw...)
    scene = current_scene()
    addtitle(scene, string; kw...)
end
