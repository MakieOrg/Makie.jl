function LLegend(parent::Scene; bbox = nothing, kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LLegend))

    @extract attrs (
        halign, valign, padding, margin,
        title, titlefont, titlesize,
        labelsize, labelfont, labelcolor, labelalign,
        bgcolor, strokecolor, strokewidth,
        patchsize, # the side length of the entry patch area
        ncols,
    )

    decorations = Dict{Symbol, Any}()

    sizeattrs = sizenode!(attrs.width, attrs.height)
    alignment = lift(tuple, halign, valign)

    suggestedbbox = create_suggested_bboxnode(bbox)

    autosizenode = Node((500f0, 500f0))

    computedsize = computedsizenode!(sizeattrs, autosizenode)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment, sizeattrs)

    # scenearea = @lift(IRect2D(enlarge($finalbbox, $margin...)))
    scenearea = @lift(IRect2D($finalbbox))

    scene = Scene(parent, scenearea, raw = true, camera = campixel!)

    # translate!(scene, (0, 0, 10))

    legendrect = @lift(
        BBox($margin[1], width($scenearea) - $margin[2],
             $margin[3], height($scenearea)- $margin[4]))

    frame = poly!(scene, legendrect,
        color = bgcolor, strokewidth = strokewidth,
        strokecolor = strokecolor, raw = true)[end]

    entries = Node(LegendEntry[])

    # titlet = text!(scene, title, position = Point2f0(0, 0), textsize = titlesize,
    #     font = titlefont, align = (:left, :top))[end]

    maingrid = GridLayout(legendrect, alignmode = Outside(20))
    manipulating_grid = Ref(false)

    onany(maingrid.needs_update, margin) do _, margin
        if manipulating_grid[]
            return
        end
        w = determinedirsize(maingrid, Col())
        h = determinedirsize(maingrid, Row())
        if !any(isnothing.((w, h)))
            autosizenode[] = (w + sum(margin[1:2]), h + sum(margin[3:4]))
        end
    end

    entrytexts = LText[]
    entryplots = Vector{AbstractPlot}[]
    entryrects = LRect[]

    maingrid[1, 1] = LText(scene, text = title, textsize = titlesize, halign=:left)

    labelgrid = maingrid[2, 1] = GridLayout()

    function relayout()
        manipulating_grid[] = true

        nrows = ceil(Int, length(entries[]) / ncols[])
        ncols_with_symbolcols = 2 * ncols[]

        for (i, lt) in enumerate(entrytexts)
            irow = (i - 1) ÷ ncols[] + 1
            icol = (i - 1) % ncols[] + 1
            labelgrid[irow, icol * 2] = lt
        end

        for (i, rect) in enumerate(entryrects)
            irow = (i - 1) ÷ ncols[] + 1
            icol = (i - 1) % ncols[] + 1
            labelgrid[irow, icol * 2 - 1] = rect
        end
        # this is empty if no superfluous rows exist
        # for i in length(entrytexts) : -1 : (length(entries[]) + 1)
        #     # remove object from scene
        #     remove!(entrytexts[i])
        #     # remove reference from array
        #     deleteat!(entrytexts, i)
        # end

        for i in labelgrid.nrows : -1 : (nrows + 1)
            deleterow!(labelgrid, i)
        end

        for i in labelgrid.ncols : -1 : (ncols_with_symbolcols + 1)
            deletecol!(labelgrid, i)
        end

        # for i in 1:2:labelgrid.ncols
        #     colsize!(labelgrid, i, Fixed(30))
        # end

        manipulating_grid[] = false
        maingrid.needs_update[] = true
    end

    on(ncols) do n; relayout(); end
    # on(patchsize) do p; relayout(); end

    on(entries) do entries
        for (i, e) in enumerate(entries)
            if i <= length(entrytexts)
                entrytexts[i].attributes.text[] = e.label
            else
                push!(entrytexts,
                    LText(scene, text = e.label, textsize = labelsize, halign=:left)
                )
            end

            if i <= length(entryrects)
                # entryrects[i].attributes.text[] = e.label
            else
                push!(entryrects,
                    LRect(scene, color = rand(RGBf0), width = patchsize, height = patchsize)
                )
            end
        end
        relayout()
    end

    entries[] = [
        LegendEntry("entry 1", AbstractPlot[]),
    ]

    # no protrusions
    protrusions = Node(RectSides(0f0, 0f0, 0f0, 0f0))

    # trigger suggestedbbox
    suggestedbbox[] = suggestedbbox[]

    layoutnodes = LayoutNodes(suggestedbbox, protrusions, computedsize, finalbbox)

    LLegend(scene, entries, layoutnodes, attrs, decorations, entrytexts, entryplots)
end

defaultlayout(ll::LLegend) = ProtrusionLayout(ll)

function align_to_bbox!(ll::LLegend, bbox)
    ll.layoutnodes.suggestedbbox[] = bbox
end

computedsizenode(ll::LLegend) = ll.layoutnodes.computedsize
protrusionnode(ll::LLegend) = ll.layoutnodes.protrusions


function Base.getproperty(ll::LLegend, s::Symbol)
    if s in fieldnames(LLegend)
        getfield(ll, s)
    else
        ll.attributes[s]
    end
end

function Base.setproperty!(ll::LLegend, s::Symbol, value)
    if s in fieldnames(LLegend)
        setfield!(ll, s, value)
    else
        ll.attributes[s][] = value
    end
end

function Base.propertynames(ll::LLegend)
    [fieldnames(LLegend)..., keys(ll.attributes)...]
end

function LegendEntry(label::String, plot::AbstractPlot)
    LegendEntry(label, AbstractPlot[plot])
end
