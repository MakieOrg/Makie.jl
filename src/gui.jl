struct Button
    value::Node{Bool}
    text::Node{String}
    visual::AbstractPlot
end

function Button(scene::Scene, txt::String)
    butt = Combined{:Button}(scene, Attributes(), txt)
    tvis = text!(butt, txt)
    value = node(:button_value, false)
    onclick(butt) do val
        value[] = val
    end
    Button(value, txt, butt)
end

struct Slider{T <: Number}
    value::Node{T}
    range::Range
    visual::AbstractPlot
end

function Slider(scene::Scene, range::Range)
    slider = Combined{:Slider}(scene, Attributes(), txt)
    tvis = text!(slider, txt)
    value = node(:slider_value, false)
    ondrag(slider) do val
        value[] = val
    end
    Button(value, txt, slid)
end

struct CheckBox
    value::Node{Bool}
    visual::AbstractPlot
end
