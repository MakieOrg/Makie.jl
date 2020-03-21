function LLegend(
        parent::Scene,
        entry_groups::Node{Vector{Tuple{Optional{String}, Vector{LegendEntry}}}};
        bbox = nothing, kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LLegend, parent))

    @extract attrs (
        halign, valign, padding, margin,
        titlefont, titlesize, titlehalign, titlevalign, titlevisible,
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
    titletexts = Optional{LText}[]
    entrytexts = [LText[]]
    entryplots = [[AbstractPlot[]]]
    entryrects = [LRect[]]


    function relayout()
        manipulating_grid[] = true

        ngroups = length(entry_groups[])
        grouplengths = length.(last.(entry_groups[]))
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
            if titleposition[] == :top
                [2; 2 .+ (1:ngroups-1) .+ cumsum(rows_per_group[1:ngroups-1])]
            elseif titleposition[] == :left
                [1; 1 .+ cumsum(rows_per_group[1:ngroups-1])]
            end
        elseif orientation[] == :horizontal
            if titleposition[] == :top
                [2 for _ in 1:ngroups]
            elseif titleposition[] == :left
                [1 for _ in 1:ngroups]
            end
        end

        colstarts = if orientation[] == :vertical
            if titleposition[] == :top
                [1 for _ in 1:ngroups]
            elseif titleposition[] == :left
                [2 for _ in 1:ngroups]
            end
        elseif orientation[] == :horizontal
            if titleposition[] == :top
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
                if titleposition[] == :top
                    (rowstart-1, 1:ncols_with_symbolcols)
                elseif titleposition[] == :left
                    (rowstart:rowstart+nrows_group-1, 1)
                end
            elseif orientation[] == :horizontal
                if titleposition[] == :top
                    (rowstart-1, colstart:colstart+realcols_per_group[g]-1)
                elseif titleposition[] == :left
                    (rowstart:rowstart+nrows_group-1, colstart-1)
                end
            end

            if !isnothing(title)
                grid[titlerows, titlecols] = title
            end

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

        if orientation[] == :vertical && titleposition[] == :top
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
        elseif orientation[] == :horizontal && titleposition[] == :top
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

    onany(title, nbanks, titleposition, rowgap, colgap, patchlabelgap, groupgap, titlegap,
            titlevisible, orientation) do args...
        relayout()
    end

    on(entry_groups) do entry_groups
        # first delete all existing labels and patches

        for t in titletexts
            !isnothing(t) && delete!(t)
        end
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

        for (title, entries) in entry_groups

            if isnothing(title)
                # in case a group has no title
                push!(titletexts, nothing)
            else
                push!(titletexts, LText(scene, text = title, font = titlefont,
                    textsize = titlesize, halign = titlehalign, valign = titlevalign))
            end

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
                symbolplots = AbstractPlot[]
                for element in e.elements
                    append!(symbolplots,
                        legendelement_plots!(scene, element,
                            rect.layoutnodes.computedbbox, e.attributes))
                end

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

    leg = LLegend(scene, entry_groups, layoutnodes, attrs, decorations, LText[], Vector{Vector{AbstractPlot}}())
    # trigger first relayout
    entry_groups[] = entry_groups[]
    leg
end


function legendelement_plots!(scene, element::MarkerElement, bbox::Node{BBox}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes

    fracpoints = attrs.markerpoints
    points = @lift(fractionpoint.(Ref($bbox), $fracpoints))
    scat = scatter!(scene, points, color = attrs.color, marker = attrs.marker,
        markersize = attrs.markersize,
        strokewidth = attrs.markerstrokewidth,
        strokecolor = attrs.strokecolor, raw = true)[end]
    [scat]
end

function legendelement_plots!(scene, element::LineElement, bbox::Node{BBox}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes

    fracpoints = attrs.linepoints
    points = @lift(fractionpoint.(Ref($bbox), $fracpoints))
    lin = lines!(scene, points, linewidth = attrs.linewidth, color = attrs.color,
        linestyle = attrs.linestyle,
        raw = true)[end]
    [lin]
end

function legendelement_plots!(scene, element::PolyElement, bbox::Node{BBox}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes

    fracpoints = attrs.polypoints
    points = @lift(fractionpoint.(Ref($bbox), $fracpoints))
    pol = poly!(scene, points, strokewidth = attrs.polystrokewidth, color = attrs.color,
        strokecolor = attrs.strokecolor,
        raw = true)[end]
    [pol]
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

legendelements(le::LegendElement) = LegendElement[le]
legendelements(les::AbstractArray{<:LegendElement}) = LegendElement[les...]


function LegendEntry(label::String, contentelements::AbstractArray; kwargs...)
    attrs = Attributes(label = label)

    kwargattrs = Attributes(kwargs)
    merge!(attrs, kwargattrs)

    elems = vcat(legendelements.(contentelements)...)
    LegendEntry(elems, attrs)
end

function LegendEntry(label::String, contentelement; kwargs...)
    attrs = Attributes(label = label)

    kwargattrs = Attributes(kwargs)
    merge!(attrs, kwargattrs)

    elems = legendelements(contentelement)
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



"""
    LLegend(
        scene,
        contents::AbstractArray,
        labels::AbstractArray{String},
        title::Optional{String} = nothing;
        kwargs...)

Create a legend from `contents` and `labels` where each label is associated to
one content element. A content element can be an `AbstractPlot`, an array of
`AbstractPlots`, a `LegendElement`, or any other object for which the
`legendelements` method is defined.
"""
function LLegend(scene,
        contents::AbstractArray,
        labels::AbstractArray{String},
        title::Optional{String} = nothing;
        kwargs...)

    if length(contents) != length(labels)
        error("Number of elements not equal: $(length(contents)) content elements and $(length(labels)) labels.")
    end

    entries = [LegendEntry(label, content) for (content, label) in zip(contents, labels)]
    entrygroups = Node{Vector{EntryGroup}}([(title, entries)])
    legend = LLegend(scene, entrygroups; kwargs...)
end



"""
    LLegend(
        scene,
        contentgroups::AbstractArray{<:AbstractArray},
        labelgroups::AbstractArray{<:AbstractArray},
        titles::AbstractArray{<:Optional{String}};
        kwargs...)

Create a multi-group legend from `contentgroups`, `labelgroups` and `titles`.
Each group from `contentgroups` and `labelgroups` is associated with one title
from `titles` (a title can be `nothing` to hide it).

Within each group, each content element is associated with one label. A content
element can be an `AbstractPlot`, an array of `AbstractPlots`, a `LegendElement`,
or any other object for which the `legendelements` method is defined.
"""
function LLegend(scene,
        contentgroups::AbstractArray{<:AbstractArray},
        labelgroups::AbstractArray{<:AbstractArray},
        titles::AbstractArray{<:Optional{String}};
        kwargs...)

    if !(length(titles) == length(contentgroups) == length(labelgroups))
        error("Number of elements not equal: $(length(titles)) titles, $(length(contentgroups)) content groups and $(length(labelgroups)) label groups.")
    end

    entries = [[LegendEntry(l, pg) for (l, pg) in zip(labelgroup, contentgroup)]
        for (labelgroup, contentgroup) in zip(labelgroups, contentgroups)]

    entrygroups = Node{Vector{EntryGroup}}([(t, en) for (t, en) in zip(titles, entries)])
    legend = LLegend(scene, entrygroups; kwargs...)
end
