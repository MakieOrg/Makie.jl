function LText(parent::Scene, text; kwargs...)
    LText(parent; text = text, kwargs...)
end

function LText(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LText))

    @extract attrs (text, textsize, font, color, visible, halign, valign,
        rotation, padding)

    sizeattrs = sizenode!(attrs.width, attrs.height)

    alignment = lift(tuple, halign, valign)

    autosizenode = Node{NTuple{2, Optional{Float32}}}((nothing, nothing))

    computedsize = computedsizenode!(sizeattrs, autosizenode)

    suggestedbbox = create_suggested_bboxnode(bbox)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment,
        sizeattrs, autosizenode)

    textpos = Node(Point3f0(0, 0, 0))

    t = text!(parent, text, position = textpos, textsize = textsize, font = font, color = color,
        visible = visible, align = (:center, :center), rotation = rotation, raw = true)[end]

    textbb = BBox(0, 1, 0, 1)

    onany(text, textsize, font, rotation, padding) do text, textsize, font, rotation, padding
        textbb = FRect2D(boundingbox(t))
        autowidth = width(textbb) + padding[1] + padding[2]
        autoheight = height(textbb) + padding[3] + padding[4]
        autosizenode[] = (autowidth, autoheight)
    end

    onany(finalbbox, padding) do bbox, padding

        tw = width(textbb)
        th = height(textbb)

        box = bbox.origin[1]
        boy = bbox.origin[2]

        tx = box + padding[1] + 0.5 * tw
        ty = boy + padding[3] + 0.5 * th

        textpos[] = Point3f0(tx, ty, 0)
    end


    # text has no protrusions
    protrusions = Node(RectSides(0f0, 0f0, 0f0, 0f0))

    layoutnodes = LayoutNodes{LText, GridLayout}(suggestedbbox, protrusions, computedsize, autosizenode, finalbbox, nothing)

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

    disconnect_layoutnodes!(lt.layoutnodes.gridcontent)
    remove_from_gridlayout!(lt.layoutnodes.gridcontent)
    empty!(lt.layoutnodes.suggestedbbox.listeners)
    empty!(lt.layoutnodes.computedbbox.listeners)
    empty!(lt.layoutnodes.computedsize.listeners)
    empty!(lt.layoutnodes.autosize.listeners)
    empty!(lt.layoutnodes.protrusions.listeners)

    # remove the plot object from the scene
    delete!(lt.parent, lt.textobject)
end
