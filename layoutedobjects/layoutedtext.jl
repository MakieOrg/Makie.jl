function LayoutedText(parent::Scene; kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedText))

    @extract attrs (text, textsize, font, color, visible, alignment,
        rotation, padding)

    heightattr = attrs.height
    widthattr = attrs.width

    heightnode = Node{Union{Nothing, Float32}}(heightattr[])
    widthnode = Node{Union{Nothing, Float32}}(widthattr[])

    bboxnode = Node(BBox(0, 100, 0, 100))

    # scenearea = Node(IRect(0, 0, 100, 100))
    # # TODO: scenearea not needed, just for arguments for now
    # connect_scenearea_and_bbox_colorbar!(scenearea, bboxnode, widthnode, heightnode, alignment)

    position = Node(Point2f0(0, 0))

    t = text!(parent, text, position = position, textsize = textsize, font = font, color = color,
        visible = visible, align = (:center, :center), rotation = rotation)[end]

    textbb = BBox(0, 1, 0, 1)

    onany(text, textsize, font, rotation, padding, heightattr, widthattr) do text,
            textsize, font, rotation, padding, heightattr, widthattr

        textbb = FRect2D(boundingbox(t))

        # widthnode[] = width(textbb) + padding[1] + padding[2]

        newheight = if isnothing(heightattr)
            # self-calculate text height
            height(textbb) + padding[3] + padding[4]
        else
            # use provided height
            heightattr
        end
        if newheight != heightnode[]
            heightnode[] = newheight
        end

        newwidth = if isnothing(widthattr)
            width(textbb) + padding[1] + padding[2]
        else
            widthattr
        end
        if newwidth != widthnode[]
            widthnode[] = newwidth
        end
    end

    onany(bboxnode, alignment) do bbox, (halign, valign)

        tw = width(textbb)
        th = height(textbb)
        # w = widthnode[]
        # h = heightnode[]

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

    lt = LayoutedText(parent, bboxnode, widthnode, heightnode, t, attrs)

    # trigger first update, otherwise bounds are wrong somehow
    text[] = text[]

    lt
end

defaultlayout(lt::LayoutedText) = ProtrusionLayout(lt)

function widthnode(lt::LayoutedText)
    lt.width
end
function heightnode(lt::LayoutedText)
    lt.height
end

function align_to_bbox!(lt::LayoutedText, bbox)
    lt.bboxnode[] = bbox
end

function Base.getproperty(lt::LayoutedText, s::Symbol)
    if s in fieldnames(LayoutedText)
        getfield(lt, s)
    else
        lt.attributes[s]
    end
end
function Base.propertynames(lt::LayoutedText)
    [fieldnames(LayoutedText)..., keys(lt.attributes)...]
end
