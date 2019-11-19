function LayoutedButton(scene::Scene, width::Real, height::Real, label::String, textsize=20)

    bboxnode = Node(BBox(0, 1, 1, 0))
    heightnode = Node(Float32(height))
    widthnode = Node(Float32(width))
    position = Node(Point2f0(0, 0))

    button = button!(
        scene, label,
        dimensions = lift((w, h) -> (w, h), widthnode, heightnode),
        position = position,
        textsize=textsize, raw=true)[end]

    on(bboxnode) do bbox
        position[] = Point(left(bbox), bottom(bbox))
    end

    LayoutedButton(scene, bboxnode, widthnode, heightnode, button)
end

function align_to_bbox!(lb::LayoutedButton, bbox)
    lb.bboxnode[] = bbox
end

widthnode(lb::LayoutedButton) = lb.width
heightnode(lb::LayoutedButton) = lb.height
