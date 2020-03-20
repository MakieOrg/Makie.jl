function LLegend(parent::Scene; bbox = nothing, kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LLegend, parent))

    @extract attrs (
        halign, valign, padding, margin,
        title, titlefont, titlesize, titlealign, titlevisible,
        labelsize, labelfont, labelcolor, labelhalign, labelvalign,
        bgcolor, framecolor, framewidth, framevisible,
        patchsize, # the side length of the entry patch area
        nbanks,
        colgap, rowgap, patchlabelgap,
        titlegap, groupgap,
        orientation,
        titleposition,
    )

    decorations = Dict{Symbol, Any}()

    sizeattrs = sizenode!(attrs.width, attrs.height)
    alignment = lift(tuple, halign, valign)

    suggestedbbox = create_suggested_bboxnode(bbox)

    autosizenode = Node{NTuple{2, Optional{Float32}}}((nothing, nothing))

    computedsize = computedsizenode!(sizeattrs, autosizenode)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment, sizeattrs, autosizenode)

    scenearea = @lift(IRect2D($finalbbox))

    scene = Scene(parent, scenearea, raw = true, camera = campixel!)

    # the rectangle in which the legend is drawn when margins are removed
    legendrect = @lift(
        BBox($margin[1], width($scenearea) - $margin[2],
             $margin[3], height($scenearea)- $margin[4]))

    frame = poly!(scene,
        @lift(enlarge($legendrect, repeat([-$framewidth/2], 4)...)),
        color = bgcolor, strokewidth = framewidth, visible = framevisible,
        strokecolor = framecolor, raw = true)[end]

    # the array of legend entries, when it changes the legend gets redrawn

    # a vector with one entry for every legend group
    # each legend group consists of one title and a vector of legendentries
    attrs[:content_groups] = Node{Vector{Tuple{String, Vector{LegendEntry}}}}([])
    content_groups = attrs.content_groups

    entries_dummy = Node{Vector{LegendEntry}}([])

    # the grid containing all content
    grid = GridLayout(bbox = legendrect, alignmode = Outside(padding[]...))

    # while the entries are being manipulated through code, this Ref value is set to
    # true so the GridLayout doesn't update itself to save time
    manipulating_grid = Ref(false)

    on(padding) do p
        grid.alignmode = Outside(p...)
        relayout()
    end

    onany(grid.needs_update, margin) do _, margin
        if manipulating_grid[]
            return
        end
        w = determinedirsize(grid, Col())
        h = determinedirsize(grid, Row())
        if !any(isnothing.((w, h)))
            autosizenode[] = (w + sum(margin[1:2]), h + sum(margin[3:4]))
        end
    end

    # these arrays store all the plot objects that the legend entries need
    titletexts = LText[]
    entrytexts = [LText[]]
    entryplots = [[AbstractPlot[]]]
    entryrects = [LRect[]]


    function relayout()
        manipulating_grid[] = true

        ngroups = length(content_groups[])
        grouplengths = length.(last.(content_groups[]))
        n_max_entries = maximum(grouplengths)

        nbanks_real = min(n_max_entries, nbanks[]) # if there are fewer entries than banks

        nvaris_per_group = ceil.(Int, grouplengths ./ nbanks_real)
        nvaris_overall = sum(nvaris_per_group)


        nrows, ncols = if orientation[] == :vertical
            (nvaris_overall, nbanks_real)
        elseif orientation[] == :horizontal
            # columns become rows
            (nbanks_real, nvaris_overall)
        else
            error("Invalid legend orientation $(orientation[]), options are :horizontal or :vertical.")
        end

        # the grid has twice as many columns as nbanks, because of labels and patches
        ncols_with_symbolcols = 2 * ncols

        vari_starts = [1; 1 .+ cumsum(nvaris_per_group[1:end-1])]

        rows_per_group = if orientation[] == :vertical
            nvaris_per_group
        elseif orientation[] == :horizontal
            [nbanks_real for _ in 1:ngroups]
        end

        cols_per_group = if orientation[] == :vertical
            [nbanks_real for _ in 1:ngroups]
        elseif orientation[] == :horizontal
            nvaris_per_group
        end

        realcols_per_group = 2 .* cols_per_group

        rowstarts = if orientation[] == :vertical
            if titleposition[] == :above
                [2; 2 .+ (1:ngroups-1) .+ cumsum(rows_per_group[1:ngroups-1])]
            elseif titleposition[] == :left
                [1; 1 .+ cumsum(rows_per_group[1:ngroups-1])]
            end
        elseif orientation[] == :horizontal
            if titleposition[] == :above
                [2 for _ in 1:ngroups]
            elseif titleposition[] == :left
                [1 for _ in 1:ngroups]
            end
        end

        colstarts = if orientation[] == :vertical
            if titleposition[] == :above
                [1 for _ in 1:ngroups]
            elseif titleposition[] == :left
                [2 for _ in 1:ngroups]
            end
        elseif orientation[] == :horizontal
            if titleposition[] == :above
                [1; 1 .+ cumsum(realcols_per_group[1:ngroups-1])]
            elseif titleposition[] == :left
                [2; 2 .* cumsum(realcols_per_group[1:ngroups-1])]
            end
        end

        rowcol(n, nbanks) = ((n - 1) ÷ nbanks + 1, (n - 1) % nbanks + 1)

        # loop through groups
        for g in 1:ngroups
            title = titletexts[g]
            etexts = entrytexts[g]
            erects = entryrects[g]

            vari_start = vari_starts[g]
            nvaris = nvaris_per_group[g]

            rowstart = rowstarts[g]
            colstart = colstarts[g]

            rowoffset = rowstart - 1
            coloffset = colstart - 1

            nrows_group = rows_per_group[g]

            titlerows, titlecols = if orientation[] == :vertical
                if titleposition[] == :above
                    (rowstart-1, 1:ncols_with_symbolcols)
                elseif titleposition[] == :left
                    (rowstart:rowstart+nrows_group-1, 1)
                end
            elseif orientation[] == :horizontal
                if titleposition[] == :above
                    (rowstart-1, colstart:colstart+realcols_per_group[g]-1)
                elseif titleposition[] == :left
                    (rowstart:rowstart+nrows_group-1, colstart-1)
                end
            end

            grid[titlerows, titlecols] = title

            for (i, (lt, rect)) in enumerate(zip(etexts, erects))
                irow, icol = if orientation[] == :vertical
                    rowcol(i, cols_per_group[g])
                elseif orientation[] == :horizontal
                    reverse(rowcol(i, rows_per_group[g]))
                end
                grid[rowoffset + irow, coloffset + icol * 2] = lt
                grid[rowoffset + irow, coloffset + icol * 2 - 1] = rect
            end
        end

        if orientation[] == :vertical && titleposition[] == :above
            # first all rowgaps because it's easier
            for row in 1:nrows + ngroups - 1
                rowgap!(grid, row, Fixed(rowgap[]))
            end
            for rs in rowstarts
                rowgap!(grid, rs-1, Fixed(titlegap[]))
            end
            for rs in rowstarts[2:end]
                rowgap!(grid, rs-2, Fixed(groupgap[]))
            end
            for col in 1:2:ncols_with_symbolcols
                colgap!(grid, col, Fixed(patchlabelgap[]))
            end
            for col in 2:2:ncols_with_symbolcols-1
                colgap!(grid, col, Fixed(colgap[]))
            end
        elseif orientation[] == :vertical && titleposition[] == :left
            for row in 1:nrows-1
                rowgap!(grid, row, Fixed(rowgap[]))
            end
            for rs in rowstarts[2:end]
                rowgap!(grid, rs-1, Fixed(groupgap[]))
            end
            colgap!(grid, 1, Fixed(titlegap[]))
            for col in 2:2:ncols_with_symbolcols
                colgap!(grid, col, Fixed(patchlabelgap[]))
            end
            for col in 3:2:ncols_with_symbolcols-1
                colgap!(grid, col, Fixed(colgap[]))
            end
        elseif orientation[] == :horizontal && titleposition[] == :above
            for col in 1:2:ncols_with_symbolcols
                colgap!(grid, col, Fixed(patchlabelgap[]))
            end
            for col in 2:2:ncols_with_symbolcols-1
                colgap!(grid, col, Fixed(colgap[]))
            end
            for col in colstarts[2:end]
                colgap!(grid, col-1, Fixed(groupgap[]))
            end
            rowgap!(grid, 1, Fixed(titlegap[]))
            for row in 2:nrows
                rowgap!(grid, row, Fixed(rowgap[]))
            end
        elseif orientation[] == :horizontal && titleposition[] == :left
            for col in colstarts
                colgap!(grid, col-1, Fixed(titlegap[]))
            end
            for col in colstarts[2:end]
                colgap!(grid, col-2, Fixed(groupgap[]))
            end
            for (col, n) in zip(colstarts, realcols_per_group)
                for c in col:2:col+n-1
                    colgap!(grid, c, Fixed(patchlabelgap[]))
                end
                for c in col+1:2:col+n-2
                    colgap!(grid, c, Fixed(colgap[]))
                end
            end
            for row in 1:nrows-1
                rowgap!(grid, row, Fixed(rowgap[]))
            end
        end


        # delete unused rows and columns
        trim!(grid)


        manipulating_grid[] = false
        grid.needs_update[] = true

        # translate the legend forward so it is above the standard axis content
        # which is at zero. this will not really work if the legend should be
        # above a 3d plot, but for now this hack is ok.
        translate!(scene, (0, 0, 10))
    end

    onany(title, nbanks, titleposition, rowgap, colgap, patchlabelgap,
            titlevisible, orientation) do args...
        relayout()
    end

    on(content_groups) do content_groups
        # first delete all existing labels and patches

        delete!.(titletexts)
        empty!(titletexts)

        [delete!.(etexts) for etexts in entrytexts]
        empty!(entrytexts)

        [delete!.(erects) for erects in entrytexts]
        empty!(entryrects)

        # delete patch plots
        for eplotgroup in entryplots
            for eplots in eplotgroup
                # each entry can have a vector of patch plots
                delete!.(scene, eplots)
            end
        end
        empty!(entryplots)

        # the attributes for legend entries that the legend itself carries
        # these serve as defaults unless the legendentry gets its own value set
        preset_attrs = extractattributes(attrs, LegendEntry)

        for (title, entries) in content_groups
            push!(titletexts, LText(scene, text = title, font = titlefont,
                textsize = titlesize, halign = titlealign))

            etexts = []
            erects = []
            eplots = []
            for (i, e) in enumerate(entries)
                # fill missing entry attributes with those carried by the legend
                merge!(e.attributes, preset_attrs)

                # create the label
                push!(etexts, LText(scene,
                    text = e.label, textsize = e.labelsize, font = e.labelfont,
                    color = e.labelcolor, halign = e.labelhalign, valign = e.labelvalign
                    ))

                # create the patch rectangle
                rect = LRect(scene, color = e.patchcolor, strokecolor = e.patchstrokecolor,
                    strokewidth = e.patchstrokewidth,
                    width = lift(x -> x[1], e.patchsize),
                    height = lift(x -> x[2], e.patchsize))
                push!(erects, rect)

                # plot the symbols belonging to this entry
                symbolplots = AbstractPlot[
                    legendsymbol!(scene, element, rect.layoutnodes.computedbbox, e.attributes)
                    for element in e.elements]

                push!(eplots, symbolplots)
            end
            push!(entrytexts, etexts)
            push!(entryrects, erects)
            push!(entryplots, eplots)
        end
        relayout()
    end

    # no protrusions
    protrusions = Node(RectSides(0f0, 0f0, 0f0, 0f0))

    # trigger suggestedbbox
    suggestedbbox[] = suggestedbbox[]

    layoutnodes = LayoutNodes{LLegend, GridLayout}(suggestedbbox, protrusions, computedsize, autosizenode, finalbbox, nothing)

    LLegend(scene, entries_dummy, layoutnodes, attrs, decorations, LText[], Vector{Vector{AbstractPlot}}())
end


function legendsymbol!(scene, element::MarkerElement, bbox, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes

    fracpoints = attrs.markerpoints
    points = @lift(fractionpoint.(Ref($bbox), $fracpoints))
    scatter!(scene, points, color = attrs.color, marker = attrs.marker,
        markersize = attrs.markersize,
        strokewidth = attrs.markerstrokewidth,
        strokecolor = attrs.strokecolor, raw = true)[end]
end

function legendsymbol!(scene, element::LineElement, bbox, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes

    fracpoints = attrs.linepoints
    points = @lift(fractionpoint.(Ref($bbox), $fracpoints))
    lines!(scene, points, linewidth = attrs.linewidth, color = attrs.color,
        linestyle = attrs.linestyle,
        raw = true)[end]
end

function legendsymbol!(scene, element::PolyElement, bbox, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes

    fracpoints = attrs.polypoints
    points = @lift(fractionpoint.(Ref($bbox), $fracpoints))
    poly!(scene, points, strokewidth = attrs.polystrokewidth, color = attrs.color,
        strokecolor = attrs.strokecolor,
        raw = true)[end]
end

function Base.getproperty(lentry::LegendEntry, s::Symbol)
    if s in fieldnames(LegendEntry)
        getfield(lentry, s)
    else
        lentry.attributes[s]
    end
end

function Base.setproperty!(lentry::LegendEntry, s::Symbol, value)
    if s in fieldnames(LegendEntry)
        setfield!(lentry, s, value)
    else
        lentry.attributes[s][] = value
    end
end

function Base.propertynames(lentry::LegendEntry)
    [fieldnames(T)..., keys(lentry.attributes)...]
end


function LegendEntry(label::String, plots::Vararg{AbstractPlot}; kwargs...)
    attrs = Attributes(label = label)

    kwargattrs = Attributes(kwargs)
    merge!(attrs, kwargattrs)

    elems = vcat(legendelements.(plots)...)
    LegendEntry(elems, attrs)
end

function LegendEntry(label::String, elements::Vararg{LegendElement}; kwargs...)
    attrs = Attributes(label = label)

    kwargattrs = Attributes(kwargs)
    merge!(attrs, kwargattrs)

    elems = LegendElement[elements...]
    LegendEntry(elems, attrs)
end

function LineElement(;kwargs...)
    LineElement(Attributes(kwargs))
end

function MarkerElement(;kwargs...)
    MarkerElement(Attributes(kwargs))
end
function PolyElement(;kwargs...)
    PolyElement(Attributes(kwargs))
end

function legendelements(plot::Union{Lines, LineSegments})
    LegendElement[LineElement(color = plot.color, linestyle = plot.linestyle)]
end

function legendelements(plot::Scatter)
    LegendElement[MarkerElement(
        color = plot.color, marker = plot.marker,
        strokecolor = plot.strokecolor)]
end

function legendelements(plot::Poly)
    LegendElement[PolyElement(color = plot.color, strokecolor = plot.strokecolor)]
end

function legendelements(plot::Band)
    # there seems to be no stroke for Band, so we set it invisible
    LegendElement[PolyElement(color = plot.color, strokecolor = :transparent)]
end

function legendelements(plot::T) where T
    error("""
        There is no `legendelements` method defined for plot type $T. This means
        that you can't automatically generate a legend entry for this plot type.
        You can overload this method for your plot type that returns a `LegendElement`
        vector, or manually construct a legend entry from those elements.
    """)
end

function Base.getproperty(legendelement::T, s::Symbol) where T <: LegendElement
    if s in fieldnames(T)
        getfield(legendelement, s)
    else
        legendelement.attributes[s]
    end
end

function Base.setproperty!(legendelement::T, s::Symbol, value) where T <: LegendElement
    if s in fieldnames(T)
        setfield!(legendelement, s, value)
    else
        legendelement.attributes[s][] = value
    end
end

function Base.propertynames(legendelement::T) where T <: LegendElement
    [fieldnames(T)..., keys(legendelement.attributes)...]
end

function Base.push!(legend::LLegend, entry::LegendEntry)
    legend.entries[] = [legend.entries[]; entry]
    nothing
end

function Base.pushfirst!(legend::LLegend, entry::LegendEntry)
    legend.entries[] = [entry; legend.entries[]]
    nothing
end

function Base.push!(legend::LLegend, label::String, plots::Vararg{AbstractPlot}; kwargs...)
    entry = LegendEntry(label, plots...; kwargs...)
    push!(legend, entry)
end

function Base.pushfirst!(legend::LLegend, label::String, plots::Vararg{AbstractPlot}; kwargs...)
    entry = LegendEntry(label, plots...; kwargs...)
    pushfirst!(legend, entry)
end

"""
    LLegend(scene, plots::AbstractArray{<:AbstractPlot}, labels::AbstractArray{String}; kwargs...)

Create a legend where one default legend marker derived from each plot in `plots` is
combined with one label from `labels`.
"""
function LLegend(scene, plots::AbstractArray{<:AbstractPlot}, labels::AbstractArray{String}; kwargs...)
    legend = LLegend(scene; kwargs...)
    if length(plots) != length(labels)
        error("Legend received $(length(plots)) plots but $(length(labels)) labels.")
    end
    legend.entries[] = [LegendEntry(label, plot) for (plot, label) in zip(plots, labels)]
    legend
end

"""
    LLegend(scene, plotgroups::AbstractArray{<:AbstractArray{<:AbstractPlot}}, labels::AbstractArray{String}; kwargs...)

Create a legend where a stack of default legend markers derived from each group of
plot objects in `plotgroups` is combined with one label from `labels`.
"""
function LLegend(scene, plotgroups::AbstractArray{<:AbstractArray{<:AbstractPlot}}, labels::AbstractArray{String}; kwargs...)
    legend = LLegend(scene; kwargs...)
    if length(plotgroups) != length(labels)
        error("Legend received $(length(plots)) plotgroups but $(length(labels)) labels.")
    end
    legend.entries[] = [LegendEntry(label, plotgroup...) for (plotgroup, label) in zip(plotgroups, labels)]
    legend
end
