function LText(parent::Scene, text::String; kwargs...)
    LText(parent; text = text, kwargs...)
end

function LText(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LText))

    @extract attrs (text, textsize, font, color, visible, halign, valign,
        rotation, padding)

    sizeattrs = sizenode!(attrs.width, attrs.height)

    alignment = lift(tuple, halign, valign)

    autosizenode = Node((0f0, 0f0))

    computedsize = computedsizenode!(sizeattrs, autosizenode)

    suggestedbbox = create_suggested_bboxnode(bbox)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment,
        sizeattrs)

    textpos = Node(Point3f0(0, 0, 0))

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

        textpos[] = Point3f0(x, y, 0)
    end


    # text has no protrusions
    protrusions = Node(RectSides(0f0, 0f0, 0f0, 0f0))

    layoutnodes = LayoutNodes(suggestedbbox, protrusions, computedsize, finalbbox)

    # trigger first update, otherwise bounds are wrong somehow
    text[] = text[]
    # trigger bbox
    suggestedbbox[] = suggestedbbox[]

    lt = LText(parent, layoutnodes, t, attrs)

    lt
end

defaultlayout(lt::LText) = ProtrusionLayout(lt)

function align_to_bbox!(lt::LText, bbox)
    lt.layoutnodes.suggestedbbox[] = bbox
end

computedsizenode(lt::LText) = lt.layoutnodes.computedsize
protrusionnode(lt::LText) = lt.layoutnodes.protrusions


function Base.getproperty(lt::LText, s::Symbol)
    if s in fieldnames(LText)
        getfield(lt, s)
    else
        lt.attributes[s]
    end
end

function Base.setproperty!(lt::LText, s::Symbol, value)
    if s in fieldnames(LText)
        setfield!(lt, s, value)
    else
        lt.attributes[s][] = value
    end
end

function Base.propertynames(lt::LText)
    [fieldnames(LText)..., keys(lt.attributes)...]
end

function Base.delete!(lt::LText)
    # remove the plot object from the scene
    delete!(lt.parent, lt.text)
    # remove all layout node callbacks
    for f in fieldnames(LayoutNodes)
        empty!(getfield(lt.layoutnodes, f).listeners)
    end
end
