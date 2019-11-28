function LayoutedRect(parent::Scene; width=nothing, height=nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedRect))

    @extract attrs (color, visible, valign, halign, padding, strokewidth,
        strokevisible, strokecolor)

    bboxnode = Node(BBox(0, 100, 0, 100))

    heightnode = Node(height)
    widthnode = Node(width)

    rect = lift(bboxnode, halign, valign, strokewidth, strokevisible, visible, padding, heightnode,
        widthnode) do bbox, halign, valign, strokewidth, strokevisible, visible, padding, height,
            width

        bh = MakieLayout.height(bbox)
        bw = MakieLayout.width(bbox)

        h = isnothing(height) ? bh : height
        w = isnothing(width) ? bw : width

        if strokevisible
            h -= strokewidth # adjust so that the lines stay inside the rect
            w -= strokewidth
        end

        w -= padding[1] + padding[2]
        h -= padding[3] + padding[4]

        resth = bh - h
        restw = bw - w

        offset_w = if halign == :left
            padding[1]
        elseif halign == :right
            restw + padding[1]
        elseif halign == :center
            restw / 2 + padding[1]
        else
            error("Invalid halign $halign")
        end

        # if strokevisible
        #     offset_w += strokewidth
        # end

        offset_h = if valign == :top
            padding[4] + resth
        elseif valign == :bottom
            padding[4]
        elseif valign == :center
            padding[4] + resth / 2
        else
            error("Invalid valign $valign")
        end

        # if strokevisible
        #     offset_h += strokewidth
        # end


        l = left(bbox) + offset_w
        b = bottom(bbox) + offset_h

        BBox(l, l + w, b, b + h)
    end

    strokecolor_with_visibility = lift(strokecolor, strokevisible) do col, vis
        vis ? col : RGBAf0(0, 0, 0, 0)
    end

    r = poly!(parent, rect, color = color, visible = visible, raw = true,
        strokecolor = strokecolor_with_visibility, strokewidth = strokewidth)[end]

    LayoutedRect(parent, bboxnode, heightnode, widthnode, r, attrs)
end

defaultlayout(lr::LayoutedRect) = ProtrusionLayout(lr)

widthnode(lr::LayoutedRect) = lr.width
heightnode(lr::LayoutedRect) = lr.height

function align_to_bbox!(lt::LayoutedRect, bbox)
    lt.bboxnode[] = bbox
end
