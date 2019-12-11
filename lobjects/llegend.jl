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
    entryplots = [AbstractPlot[]]
    entryrects = LRect[]

    maingrid[1, 1] = LText(scene, text = title, textsize = titlesize, halign=:left)

    labelgrid = maingrid[2, 1] = GridLayout()

    function relayout()
        manipulating_grid[] = true

        n_entries = length(entries[])
        nrows = ceil(Int, n_entries / ncols[])

        # the grid has twice as many columns as ncols, because of labels and patches
        ncols_with_symbolcols = 2 * min(ncols[], n_entries) # if fewer entries than cols, not so many cols

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

        for i in labelgrid.nrows : -1 : max((nrows + 1), 2) # not the last row
            deleterow!(labelgrid, i)
        end

        for i in labelgrid.ncols : -1 : max((ncols_with_symbolcols + 1), 2) # not the last col
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

        # first delete all existing labels and patches

        # delete from grid layout
        detachfromgridlayout!.(entrytexts, Ref(labelgrid))
        # and from scene
        delete!.(entrytexts)
        empty!(entrytexts)

        # delete from grid layout
        detachfromgridlayout!.(entryrects, Ref(labelgrid))
        # and from scene
        delete!.(entryrects)
        empty!(entryrects)

        # delete patch plots
        for eplots in entryplots
            # each entry can have a vector of patch plots
            delete!.(scene, eplots)
        end
        empty!(entryplots)

        # the attributes for legend entries that the legend itself carries
        # these serve as defaults unless the legendentry gets its own value set
        preset_attrs = extractattributes(attrs, LegendEntry)

        for (i, e) in enumerate(entries)
            elemattrs = merge!(e.attributes, preset_attrs)

            push!(entrytexts, LText(scene, text = e.label))

            # t = entrytexts[i]
            # t.attributes[:textsize] = elemattrs.labelsize
            # t.attributes[:halign] = elemattrs.labelhalign
            # t.attributes[:valign] = elemattrs.labelvalign
            # t.attributes[:font] = elemattrs.labelfont

            rect = LRect(scene, color = RGBf0(0.95, 0.95, 0.95), strokecolor = :transparent,
                width = @lift($patchsize[1]),
                height = @lift($patchsize[2]))
            push!(entryrects, rect)

            # plot the symbols belonging to this entry
            symbolplots = AbstractPlot[
                legendsymbol!(scene, plot, rect.layoutnodes.computedbbox)
                for plot in e.plots]

            push!(entryplots, symbolplots)
        end
        relayout()
    end

    # entries[] = [
    #     LegendEntry("entry 1", AbstractPlot[]),
    # ]

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

# function legendsymbol!(scene, plot::Union{Lines, LineSegments}, bbox)
#     fracpoints = [Point2f0(0, 0.5), Point2f0(1, 0.5)]
#     points = @lift(fractionpoint.($bbox, fracpoints))
#     lines!(scene, points)[end]
# end
