function LayoutedText(parent::Scene; kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedText))

    @extract attrs (text, textsize, font, color, visible, halign, valign,
        rotation, padding)

    sizeattrs = sizenode!(attrs.width, attrs.height)

    alignment = lift(tuple, halign, valign)

    autosizenode = Node((0f0, 0f0))

    computedsize = computedsizenode!(sizeattrs, autosizenode)

    suggestedbbox = Node(BBox(0, 100, 0, 100))

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment,
        sizeattrs)

    textpos = Node(Point2f0(0, 0))

    t = text!(parent, text, position = textpos, textsize = textsize, font = font, color = color,
        visible = visible, align = (:center, :center), rotation = rotation)[end]

    textbb = BBox(0, 1, 0, 1)

    onany(text, textsize, font, rotation, padding) do text, textsize, font, rotation, padding
        textbb = FRect2D(boundingbox(t))
        autowidth = width(textbb) + padding[1] + padding[2]
        autoheight = height(textbb) + padding[3] + padding[4]
        autosizenode[] = (autowidth, autoheight)
    end

    onany(finalbbox, alignment) do bbox, (halign, valign)

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
                boy + 0.5f0 * th + padding[][3]
            elseif valign == :top
                boy + bh - 0.5f0 * th - padding[][4]
            elseif valign == :center
                boy + 0.5f0 * bh
            else
                error("Invalid valign $valign")
            end

        textpos[] = Point2f0(x, y)
    end


    # text has no protrusions
    protrusions = Node(RectSides(0f0, 0f0, 0f0, 0f0))

    layoutnodes = LayoutNodes(suggestedbbox, protrusions, computedsize, finalbbox)

    lt = LayoutedText(parent, layoutnodes, t, attrs)

    # trigger first update, otherwise bounds are wrong somehow
    text[] = text[]

    lt
end

defaultlayout(lt::LayoutedText) = ProtrusionLayout(lt)

function align_to_bbox!(lt::LayoutedText, bbox)
    lt.layoutnodes.suggestedbbox[] = bbox
end

computedsizenode(lt::LayoutedText) = lt.layoutnodes.computedsize
protrusionnode(lt::LayoutedText) = lt.layoutnodes.protrusions


function Base.getproperty(lt::LayoutedText, s::Symbol)
    if s in fieldnames(LayoutedText)
        getfield(lt, s)
    else
        lt.attributes[s]
    end
end

function Base.setproperty!(lt::LayoutedText, s::Symbol, value)
    if s in fieldnames(LayoutedText)
        setfield!(lt, s, value)
    else
        lt.attributes[s][] = value
    end
end

function Base.propertynames(lt::LayoutedText)
    [fieldnames(LayoutedText)..., keys(lt.attributes)...]
end
