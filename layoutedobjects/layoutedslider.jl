function LayoutedSlider(scene::Scene, height::Real, sliderrange)

    bboxnode = Node(BBox(0, 1, 1, 0))
    heightnode = Node{Union{Nothing, Float32}}(Float32(height))
    position = Node(Point2f0(0, 0))
    widthnode = Node{Union{Nothing, Float32}}(Float32(100))
    slider = slider!(scene, sliderrange, position=position,
        sliderheight=heightnode, sliderlength=widthnode, raw=true)[end]

    on(bboxnode) do bbox
        position[] = Point(left(bbox), bottom(bbox))
        widthnode[] = width(bbox)
    end

    LayoutedSlider(scene, bboxnode, heightnode, slider)
end

function align_to_bbox!(ls::LayoutedSlider, bbox)
    ls.bboxnode[] = bbox
end

heightnode(ls::LayoutedSlider) = ls.height

defaultlayout(ls::LayoutedSlider) = ProtrusionLayout(ls)
