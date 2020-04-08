function LText(parent::Scene, text; kwargs...)
    LText(parent; text = text, kwargs...)
end

function LText(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LText, parent))

    @extract attrs (text, textsize, font, color, visible, halign, valign,
        rotation, padding)

    layoutobservables = LayoutObservables(LText, attrs.width, attrs.height,
        halign, valign, attrs.alignmode; suggestedbbox = bbox)

    textpos = Node(Point3f0(0, 0, 0))

    # this is just a hack until boundingboxes in abstractplotting are perfect
    alignnode = lift(halign, rotation) do h, rot
        # left align the text if it's not rotated and left aligned
        if rot == 0 && (h == :left || h == 0.0)
            (:left, :center)
        else
            (:center, :center)
        end
    end

    t = text!(parent, text, position = textpos, textsize = textsize, font = font, color = color,
        visible = visible, align = alignnode, rotation = rotation, raw = true)[end]

    textbb = Ref(BBox(0, 1, 0, 1))

    onany(text, textsize, font, rotation, padding) do text, textsize, font, rotation, padding
        textbb[] = FRect2D(boundingbox(t))
        autowidth = width(textbb[]) + padding[1] + padding[2]
        autoheight = height(textbb[]) + padding[3] + padding[4]
        layoutobservables.autosize[] = (autowidth, autoheight)
    end

    onany(layoutobservables.computedbbox, padding) do bbox, padding

        tw = width(textbb[])
        th = height(textbb[])

        box = bbox.origin[1]
        boy = bbox.origin[2]

        # this is also part of the hack to improve left alignment until
        # boundingboxes are perfect
        tx = if rotation[] == 0 && (halign[] == :left || halign[] == 0.0)
            box + padding[1]
        else
            box + padding[1] + 0.5 * tw
        end
        ty = boy + padding[3] + 0.5 * th

        textpos[] = Point3f0(tx, ty, 0)
    end


    # trigger first update, otherwise bounds are wrong somehow
    text[] = text[]
    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    lt = LText(parent, layoutobservables, t, attrs)

    lt
end

defaultlayout(lt::LText) = ProtrusionLayout(lt)

function align_to_bbox!(lt::LText, bbox)
    lt.layoutobservables.suggestedbbox[] = bbox
end

computedsizenode(lt::LText) = lt.layoutobservables.computedsize
protrusionnode(lt::LText) = lt.layoutobservables.protrusions


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

    disconnect_layoutnodes!(lt.layoutobservables.gridcontent)
    GridLayoutBase.remove_from_gridlayout!(lt.layoutobservables.gridcontent)
    empty!(lt.layoutobservables.suggestedbbox.listeners)
    empty!(lt.layoutobservables.computedbbox.listeners)
    empty!(lt.layoutobservables.computedsize.listeners)
    empty!(lt.layoutobservables.autosize.listeners)
    empty!(lt.layoutobservables.protrusions.listeners)

    # remove the plot object from the scene
    delete!(lt.parent, lt.textobject)
end
