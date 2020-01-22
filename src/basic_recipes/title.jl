
"""
    title(
        [scene=current_scene(), ], string;
        align = (:center, :bottom), textsize = 30, parent = Scene(), formatter = string, kw...
    )

Add a title with content `string` to `scene`.  Pass a `Function` to the `formatter` kwarg
if the value passed to `string` isn't actually a String.
"""
function title(scene, tstring; align = (:center, :bottom), textsize = 30, parent = Scene(), formatter = string, kw...)
    
    string = to_node(tstring)
    
    pos = lift(pixelarea(scene)) do area
        x = widths(area)[1] ./ 2
        Vec2f0(x, 10) # offset 10px, to give it some space
    end
    t = text(
        lift(formatter, string),
        position = pos,
        camera = campixel!,
        raw = true, align = align,
        textsize = textsize;
        kw...
    )
    hbox(scene, t; parent = parent)
end

function title(string; kw...)
    scene = current_scene()
    title(scene, string; kw...)
end
