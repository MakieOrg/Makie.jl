function LayoutedButton(scene::Scene; width=nothing, height=nothing, kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedButton))

    @extract attrs (valign, halign, padding, textsize, label)

    bboxnode = Node(BBox(0, 1, 0, 1))
    heightnode = Node{Union{Nothing, Float32}}(height)
    widthnode = Node{Union{Nothing, Float32}}(width)

    position = Node(Point2f0(0, 0))

    dims = lift(bboxnode, widthnode, heightnode) do bb, w, h
        w = isnothing(w) ? MakieLayout.width(bb) : w
        h = isnothing(h) ? MakieLayout.height(bb) : h
        (w, h)
    end

    position = lift(dims) do d
        bb = bboxnode[]
        Point(left(bb), bottom(bb))
    end

    button = button!(
        scene, label,
        dimensions = dims,
        position = position,
        textsize=textsize, raw=true)[end]

    LayoutedButton(scene, bboxnode, widthnode, heightnode, button, attrs)
end

function align_to_bbox!(lb::LayoutedButton, bbox)
    lb.bboxnode[] = bbox
end

widthnode(lb::LayoutedButton) = lb.width
heightnode(lb::LayoutedButton) = lb.height

defaultlayout(lb::LayoutedButton) = ProtrusionLayout(lb)
