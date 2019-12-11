function LLegend(parent::Scene; bbox = nothing, kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LLegend))

    @extract attrs (
        halign, valign, padding, margin,
        title, titlefont, titlesize,
        labelsize, labelfont, labelcolor, labelhalign, labelvalign,
        bgcolor, strokecolor, strokewidth,
        patchsize, # the side length of the entry patch area
        ncols,
        colgap, rowgap, patchlabelgap,
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

    frame = poly!(scene,
        @lift(enlarge($legendrect, repeat([-$strokewidth/2], 4)...)),
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

        for i in 1:(labelgrid.ncols - 1)
            if i % 2 == 1
                colgap!(labelgrid, i, Fixed(patchlabelgap[]))
            else
                colgap!(labelgrid, i, Fixed(colgap[]))
            end
        end

        for i in 1:(labelgrid.nrows - 1)
            rowgap!(labelgrid, i, Fixed(rowgap[]))
        end

        manipulating_grid[] = false
        maingrid.needs_update[] = true
    end

    onany(ncols, rowgap, colgap, patchlabelgap) do _, _, _, _; relayout(); end

    on(entries) do entries
        for (i, e) in enumerate(entries)
            if i <= length(entrytexts)
                entrytexts[i].attributes.text[] = e.label
            else
                push!(entrytexts,
                    LText(scene, text = e.label, textsize = labelsize,
                    halign = labelhalign, valign = labelvalign, font = labelfont)
                )
            end

            if i <= length(entryrects)
                # entryrects[i].attributes.text[] = e.label
            else
                push!(entryrects,
                    LRect(scene, color = rand(RGBf0), width = @lift($patchsize[1]), height = @lift($patchsize[2]))
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


function legendsymbol!(scene, plot::Scatter, bbox)
    fracpoint = Point2f0(0.5, 0.5)
    points = @lift([fractionpoint($bbox, fracpoint)]) # array for the point because of scatter "bug" for single point
    scatter!(scene, points, color = plot.color, marker = plot.marker,
        markersize = 20, raw = true)[end]
end

function legendsymbol!(scene, plot::Union{Lines, LineSegments}, bbox)
    fracpoints = [Point2f0(0, 0.5), Point2f0(1, 0.5)]
    points = @lift(fractionpoint.(Ref($bbox), fracpoints))
    lines!(scene, points, linewidth = 3f0, color = plot.color,
        raw = true)[end]
end

function LegendEntry(label::String, plot::AbstractPlot)
    LegendEntry(label, AbstractPlot[plot])
end
