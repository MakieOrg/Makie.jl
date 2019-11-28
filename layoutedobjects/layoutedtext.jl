function LayoutedText(parent::Scene; kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedText))

    @extract attrs (text, textsize, font, color, visible, valign, halign,
        rotation, padding)

    bboxnode = Node(BBox(0, 100, 0, 100))

    # align = lift(valign, halign) do v, h
    #     (h, v)
    # end

    position = Node(Point2f0(0, 0))

    t = text!(parent, text, position = position, textsize = textsize, font = font, color = color,
        visible = visible, align = (:center, :center), rotation = rotation)[end]

    textbb = BBox(0, 1, 0, 1)
    heightnode = Node(1f0)
    widthnode = Node(1f0)

    onany(text, textsize, font, visible, rotation, padding) do text, textsize, font, visible,
            rotation, padding

        if visible
            textbb = FRect2D(boundingbox(t))
            heightnode[] = height(textbb) + padding[3] + padding[4]
            widthnode[] = width(textbb) + padding[1] + padding[2]
        else
            heightnode[] = 0f0
            widthnode[] = 0f0
        end
    end

    onany(bboxnode, valign, halign) do bbox, valign, halign

        tw = width(textbb)
        th = height(textbb)
        w = widthnode[]
        h = heightnode[]

        bw = width(bbox)
        bh = height(bbox)

        box = bbox.origin[1]
        boy = bbox.origin[2]

        x = if halign == :left
                box + 0.5f0 * tw + padding[][1]
            elseif halign == :right
                box + bw - 0.5f0 * tw - padding[][2]
            elseif halign == :center
                box + 0.5f0 * bw
            else
                error("Invalid halign $halign")
            end

        y = if valign == :bottom
                boy + 0.5f0 * th + padding[][4]
            elseif valign == :top
                boy + bh - 0.5f0 * th - padding[][3]
            elseif valign == :center
                boy + 0.5f0 * bh
            else
                error("Invalid valign $valign")
            end

        position[] = Point2f0(x, y)
    end

    lt = LayoutedText(parent, bboxnode, heightnode, widthnode, t, attrs)

    # trigger first update, otherwise bounds are wrong somehow
    text[] = text[]

    lt
end

defaultlayout(lt::LayoutedText) = ProtrusionLayout(lt)

# workarounds for the new optional float in protrusionlayout
# should actually be combined with a "shrink to text" setting
function widthnode(lt::LayoutedText)
    node = Node{Union{Nothing, Float32}}(lt.width[])
    on(lt.width) do w
        node[] = w
    end
    node
end
function heightnode(lt::LayoutedText)
    node = Node{Union{Nothing, Float32}}(lt.height[])
    on(lt.height) do h
        node[] = h
    end
    node
end

function align_to_bbox!(lt::LayoutedText, bbox)
    lt.bboxnode[] = bbox
end
