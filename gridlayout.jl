GridLayout(; kwargs...) = GridLayout(1, 1; kwargs...)

GridLayout(scene::Scene, args...; kwargs...) = GridLayout(args...; bbox = lift(x -> BBox(x), pixelarea(scene)), parentscene = scene, kwargs...)

function GridLayout(nrows::Int, ncols::Int;
        rowsizes = nothing,
        colsizes = nothing,
        addedrowgaps = nothing,
        addedcolgaps = nothing,
        alignmode = Inside(),
        equalprotrusiongaps = (false, false),
        bbox = nothing,
        parentscene = nothing,
        kwargs...)

    if isnothing(rowsizes)
        rowsizes = [Auto() for _ in 1:nrows]
    # duplicate a single row size into a vector for every row
    elseif rowsizes isa ContentSize
        rowsizes = [rowsizes for _ in 1:nrows]
    elseif !(typeof(rowsizes) <: Vector{<: ContentSize})
        error("Row sizes must be one size or a vector of sizes, not $(typeof(rowsizes))")
    end

    if isnothing(colsizes)
        colsizes = [Auto() for _ in 1:ncols]
    # duplicate a single col size into a vector for every col
    elseif colsizes isa ContentSize
        colsizes = [colsizes for _ in 1:ncols]
    elseif !(typeof(colsizes) <: Vector{<: ContentSize})
        error("Column sizes must be one size or a vector of sizes, not $(typeof(colsizes))")
    end

    if isnothing(addedrowgaps)
        addedrowgaps = [Fixed(20) for _ in 1:nrows-1]
    elseif addedrowgaps isa GapSize
        addedrowgaps = [addedrowgaps for _ in 1:nrows-1]
    elseif !(typeof(addedrowgaps) <: Vector{<: GapSize})
        error("Row gaps must be one size or a vector of sizes, not $(typeof(addedrowgaps))")
    end

    if isnothing(addedcolgaps)
        addedcolgaps = [Fixed(20) for _ in 1:ncols-1]
    elseif addedcolgaps isa GapSize
        addedcolgaps = [addedcolgaps for _ in 1:ncols-1]
    elseif !(typeof(addedcolgaps) <: Vector{<: GapSize})
        error("Column gaps must be one size or a vector of sizes, not $(typeof(addedcolgaps))")
    end

    needs_update = Node(true)

    content = []

    attrs = merge!(Attributes(kwargs), default_attributes(GridLayout))

    sizeattrs = sizenode!(attrs.width, attrs.height)

    alignment = lift(tuple, attrs.halign, attrs.valign)

    autosizenode = Node{NTuple{2, Optional{Float32}}}((nothing, nothing))

    computedsize = computedsizenode!(sizeattrs, autosizenode)

    suggestedbbox = create_suggested_bboxnode(bbox)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment,
        sizeattrs, autosizenode)

    protrusions = Node(RectSides(0f0, 0f0, 0f0, 0f0))

    layoutnodes = LayoutNodes{GridLayout, GridLayout}(suggestedbbox, protrusions, computedsize, autosizenode, finalbbox, nothing)


    gl = GridLayout(
        content, nrows, ncols, rowsizes, colsizes, addedrowgaps,
        addedcolgaps, alignmode, equalprotrusiongaps, needs_update, layoutnodes, attrs, parentscene)

    on(finalbbox) do bb
        align_to_bbox!(gl, bb)
    end

    on(needs_update) do u
        # TODO: is this correct? or should the bbox change somehow when a member
        # size changes

        w = determinedirsize(gl, Col())
        h = determinedirsize(gl, Row())

        new_autosize = (w, h)
        new_protrusions = RectSides{Float32}(
            protrusion(gl, Left()),
            protrusion(gl, Right()),
            protrusion(gl, Bottom()),
            protrusion(gl, Top()),
        )

        if autosizenode[] == new_autosize &&
                gl.layoutnodes.protrusions[] == new_protrusions

            gl.layoutnodes.suggestedbbox[] = gl.layoutnodes.suggestedbbox[]
        else
            # otherwise these values will not already be up to date when adding the
            # gridlayout into the next one

            # TODO: this is a double update?
            gl.layoutnodes.protrusions[] = new_protrusions
            autosizenode[] = new_autosize

            if isnothing(gl.layoutnodes.gridcontent)
                gl.layoutnodes.suggestedbbox[] = gl.layoutnodes.suggestedbbox[]
            end
        end

        nothing
    end

    gl
end


computedsizenode(gridlayout::GridLayout) = gridlayout.layoutnodes.computedsize
protrusionnode(gridlayout::GridLayout) = gridlayout.layoutnodes.protrusions


function validategridlayout(gl::GridLayout)
    if gl.nrows < 1
        error("Number of rows can't be smaller than 1")
    end
    if gl.ncols < 1
        error("Number of columns can't be smaller than 1")
    end

    if length(gl.rowsizes) != gl.nrows
        error("There are $nrows rows but $(length(rowsizes)) row sizes.")
    end
    if length(gl.colsizes) != gl.ncols
        error("There are $ncols columns but $(length(colsizes)) column sizes.")
    end
    if length(gl.addedrowgaps) != gl.nrows - 1
        error("There are $nrows rows but $(length(addedrowgaps)) row gaps.")
    end
    if length(gl.addedcolgaps) != gl.ncols - 1
        error("There are $ncols columns but $(length(addedcolgaps)) column gaps.")
    end
end

function with_updates_suspended(f::Function, gl::GridLayout)
    gl.block_updates = true
    f()
    gl.block_updates = false
    gl.needs_update[] = true
end

function connect_layoutnodes!(gc::GridContent)

    disconnect_layoutnodes!(gc::GridContent)

    gc.protrusions_handle = on(protrusionnode(gc.content)) do p
        gc.needs_update[] = true
    end
    gc.computedsize_handle = on(computedsizenode(gc.content)) do c
        gc.needs_update[] = true
    end
end

function disconnect_layoutnodes!(gc::GridContent)
    if !isnothing(gc.protrusions_handle)
        Observables.off(protrusionnode(gc.content), gc.protrusions_handle)
        gc.protrusions_handle = nothing
    end
    if !isnothing(gc.computedsize_handle)
        Observables.off(computedsizenode(gc.content), gc.computedsize_handle)
        gc.computedsize_handle = nothing
    end
end

function add_to_gridlayout!(g::GridLayout, gc::GridContent)

    # to be safe
    remove_from_gridlayout!(gc)

    push!(g.content, gc)

    # let the gridcontent know that it's inside a gridlayout
    gc.parent = g

    on(gc.needs_update) do update
        g.needs_update[] = true
    end

    # trigger relayout
    g.needs_update[] = true
end


function remove_from_gridlayout!(gc::GridContent)
    if isnothing(gc.parent)
        return
    end

    i = findfirst(x -> x === gc, gc.parent.content)
    if isnothing(i)
        error("""GridContent had a parent but was not in the content array.
        This must be a bug.""")
    end
    deleteat!(gc.parent.content, i)

    gc.parent = nothing

    # remove all listeners from needs_update because they could be pointing
    # to previous parents if we're re-nesting layout objects
    empty!(gc.needs_update.listeners)
end


function convert_contentsizes(n, sizes)::Vector{ContentSize}
    if isnothing(sizes)
        [Auto() for _ in 1:n]
    elseif sizes isa ContentSize
        [sizes for _ in 1:n]
    elseif sizes isa Vector{<:ContentSize}
        length(sizes) == n ? sizes : error("$(length(sizes)) sizes instead of $n")
    else
        error("Illegal sizes value $sizes")
    end
end

function convert_gapsizes(n, gaps)::Vector{GapSize}
    if isnothing(gaps)
        [Fixed(20) for _ in 1:n]
    elseif gaps isa GapSize
        [gaps for _ in 1:n]
    elseif gaps isa Vector{<:GapSize}
        length(gaps) == n ? gaps : error("$(length(gaps)) gaps instead of $n")
    else
        error("Illegal gaps value $gaps")
    end
end

function appendrows!(gl::GridLayout, n::Int; rowsizes=nothing, addedrowgaps=nothing)

    rowsizes = convert_contentsizes(n, rowsizes)
    addedrowgaps = convert_gapsizes(n, addedrowgaps)

    with_updates_suspended(gl) do
        gl.nrows += n
        append!(gl.rowsizes, rowsizes)
        append!(gl.addedrowgaps, addedrowgaps)
    end
end

function appendcols!(gl::GridLayout, n::Int; colsizes=nothing, addedcolgaps=nothing)

    colsizes = convert_contentsizes(n, colsizes)
    addedcolgaps = convert_gapsizes(n, addedcolgaps)

    with_updates_suspended(gl) do
        gl.ncols += n
        append!(gl.colsizes, colsizes)
        append!(gl.addedcolgaps, addedcolgaps)
    end
end

function prependrows!(gl::GridLayout, n::Int; rowsizes=nothing, addedrowgaps=nothing)

    rowsizes = convert_contentsizes(n, rowsizes)
    addedrowgaps = convert_gapsizes(n, addedrowgaps)

    newcontent = map(gl.content) do gc
        span = gc.span
        newspan = Span(span.rows .+ n, span.cols)
        GridContent(gc.content, newspan, gc.side)
    end
    # because of too specific typing with the new parametric GridContent
    gl.content = convert(Vector{GridContent}, newcontent)

    with_updates_suspended(gl) do
        gl.nrows += n
        prepend!(gl.rowsizes, rowsizes)
        prepend!(gl.addedrowgaps, addedrowgaps)
    end
end

function prependcols!(gl::GridLayout, n::Int; colsizes=nothing, addedcolgaps=nothing)

    colsizes = convert_contentsizes(n, colsizes)
    addedcolgaps = convert_gapsizes(n, addedcolgaps)

    newcontent = map(gl.content) do gc
        span = gc.span
        newspan = Span(span.rows, span.cols .+ n)
        GridContent(gc.content, newspan, gc.side)
    end
    # because of too specific typing with the new parametric GridContent
    gl.content = convert(Vector{GridContent}, newcontent)

    with_updates_suspended(gl) do
        gl.ncols += n
        prepend!(gl.colsizes, colsizes)
        prepend!(gl.addedcolgaps, addedcolgaps)
    end
end

function deleterow!(gl::GridLayout, irow::Int)
    if !(1 <= irow <= gl.nrows)
        error("Row $irow does not exist.")
    end

    if gl.nrows == 1
        error("Can't delete the last row")
    end

    # new_content = GridContent[]
    to_remove = GridContent[]
    for c in gl.content
        rows = c.span.rows
        newrows = if irow in rows
            # range is one shorter now
            rows.start : rows.stop - 1
        elseif irow > rows.stop
            # content before deleted row stays the same
            rows
        else
            # content completely after is moved forward 1 step
            rows .- 1
        end
        if isempty(newrows)
            # the row span was just one row and now zero, remove the element
            push!(to_remove, c)
        else
            c.span = Span(newrows, c.span.cols)
        end
    end

    for c in to_remove
        remove_from_gridlayout!(c)
    end
    # gl.content = new_content
    deleteat!(gl.rowsizes, irow)
    deleteat!(gl.addedrowgaps, irow == 1 ? 1 : irow - 1)
    gl.nrows -= 1
    gl.needs_update[] = true
end

function deletecol!(gl::GridLayout, icol::Int)
    if !(1 <= icol <= gl.ncols)
        error("Col $icol does not exist.")
    end

    if gl.ncols == 1
        error("Can't delete the last col")
    end

    to_remove = GridContent[]
    for c in gl.content
        cols = c.span.cols
        newcols = if icol in cols
            # range is one shorter now
            cols.start : cols.stop - 1
        elseif icol > cols.stop
            # content before deleted col stays the same
            cols
        else
            # content completely after is moved forward 1 step
            cols .- 1
        end
        if isempty(newcols)
            # the col span was just one col and now zero, remove the element
            push!(to_remove, c)
        else
            c.span = Span(c.span.rows, newcols)
        end
    end

    for c in to_remove
        remove_from_gridlayout!(c)
    end
    # gl.content = new_content
    deleteat!(gl.colsizes, icol)
    deleteat!(gl.addedcolgaps, icol == 1 ? 1 : icol - 1)
    gl.ncols -= 1
    gl.needs_update[] = true
end

function Base.isempty(gl::GridLayout, dir::GridDir, i::Int)
    !any(gl.content) do c
        span = dir isa Row ? c.span.rows : c.span.cols
        i in span
    end
end

function trim!(gl::GridLayout)
    irow = 1
    while irow <= gl.nrows && gl.nrows > 1
        if isempty(gl, Row(), irow)
            deleterow!(gl, irow)
        else
            irow += 1
        end
    end

    icol = 1
    while icol <= gl.ncols && gl.ncols > 1
        if isempty(gl, Col(), icol)
            deletecol!(gl, icol)
        else
            icol += 1
        end
    end
end

function gridnest!(gl::GridLayout, rows::Indexables, cols::Indexables)

    newrows, newcols = adjust_rows_cols!(gl, rows, cols)

    subgl = GridLayout(
        length(newrows), length(newcols);
        parent = nothing,
        colsizes = gl.colsizes[newcols],
        rowsizes = gl.rowsizes[newrows],
        addedrowgaps = gl.addedrowgaps[newrows.start:(newrows.stop-1)],
        addedcolgaps = gl.addedcolgaps[newcols.start:(newcols.stop-1)],
    )

    # remove the content from the parent that is completely inside the replacement grid
    subgl.block_updates = true
    i = 1
    while i <= length(gl.content)
        gc = gl.content[i]

        if (gc.span.rows.start >= newrows.start && gc.span.rows.stop <= newrows.stop &&
            gc.span.cols.start >= newcols.start && gc.span.cols.stop <= newcols.stop)


            subgl[gc.span.rows .- (newrows.start - 1), gc.span.cols .- (newcols.start - 1), gc.side] = gc.content
            continue
            # don't advance i because there's one piece of content less in the queue
            # and the next item is in the same position as the old removed one
        end
        i += 1
    end
    subgl.block_updates = false

    gl[newrows, newcols] = subgl

    subgl
end

function find_in_grid(obj, container::GridLayout)
    for i in 1:length(container.content)
        if container.content[i].content === obj
            return i
        end
    end
    nothing
end


function topmost_grid(gl::GridLayout)
    candidate = gl
    while true
        if candidate.parent isa GridLayout
            candidate = candidate.parent
        else
            return candidate
        end
    end
end

function find_in_grid_and_subgrids(obj, container::GridLayout)
    for i in 1:length(container.content)
        candidate = container.content[i].content

        if candidate === obj
            return container, i
        elseif candidate isa GridLayout
            return find_in_grid_and_subgrids(obj, candidate)
        end
    end
    nothing, nothing
end

function find_in_grid_tree(obj, container::GridLayout)
    topmost = topmost_grid(container)
    find_in_grid_and_subgrids(obj, topmost)
end

function detachfromgridlayout!(obj, gl::GridLayout)
    i = find_in_grid(obj, gl)
    if !isnothing(i)
        deleteat!(gl.content, i)
    end
end

function Base.show(io::IO, ::MIME"text/plain", gl::GridLayout)

    function spaceindent(str, n, downconnection)
        joinstr = if downconnection
            "\n" * (" " ^ 1) * "┃" * (" " ^ (n-2))
        else
            "\n" * (" " ^ n)
        end
        join(split(str, "\n"), joinstr)
    end

    println(io, "GridLayout[$(gl.nrows), $(gl.ncols)] with $(length(gl.content)) children")

    for (i, c) in enumerate(gl.content)
        rows = c.span.rows
        cols = c.span.cols
        content = c.content

        connector = i == length(gl.content) ? " ┗━ " : " ┣━ "

        if content isa GridLayout
            downconnection = i < length(gl.content)
            str = spaceindent(repr(MIME"text/plain"(), content), 2, downconnection)
            println(io, connector * "[$rows | $cols] $str")
        else
            println(io, connector * "[$rows | $cols] $(typeof(content))")
        end
    end
end

function Base.show(io::IO, gl::GridLayout)
    print(io, "GridLayout[$(gl.nrows), $(gl.ncols)] ($(length(gl.content)) children)")
end

function colsize!(gl::GridLayout, i::Int, s::ContentSize)
    if !(1 <= i <= gl.ncols)
        error("Can't set size of invalid column $i.")
    end
    gl.colsizes[i] = s
    gl.needs_update[] = true
end

function rowsize!(gl::GridLayout, i::Int, s::ContentSize)
    if !(1 <= i <= gl.nrows)
        error("Can't set size of invalid row $i.")
    end
    gl.rowsizes[i] = s
    gl.needs_update[] = true
end

function colgap!(gl::GridLayout, i::Int, s::GapSize)
    if !(1 <= i <= (gl.ncols - 1))
        error("Can't set size of invalid column gap $i.")
    end
    gl.addedcolgaps[i] = s
    gl.needs_update[] = true
end

function colgap!(gl::GridLayout, s::GapSize)
    gl.addedcolgaps .= s
    gl.needs_update[] = true
end

function colgap!(gl::GridLayout, r::Real)
    gl.addedcolgaps .= Ref(Fixed(r))
    gl.needs_update[] = true
end

function rowgap!(gl::GridLayout, i::Int, s::GapSize)
    if !(1 <= i <= (gl.nrows - 1))
        error("Can't set size of invalid row gap $i.")
    end
    gl.addedrowgaps[i] = s
    gl.needs_update[] = true
end

function rowgap!(gl::GridLayout, s::GapSize)
    gl.addedrowgaps .= s
    gl.needs_update[] = true
end

function rowgap!(gl::GridLayout, r::Real)
    gl.addedrowgaps .= Ref(Fixed(r))
    gl.needs_update[] = true
end

"""
This function solves a grid layout such that the "important lines" fit exactly
into a given bounding box. This means that the protrusions of all objects inside
the grid are not taken into account. This is needed if the grid is itself placed
inside another grid.
"""
function align_to_bbox!(gl::GridLayout, suggestedbbox::BBox)

    # compute the actual bbox for the content given that there might be outside
    # padding that needs to be removed
    bbox = if gl.alignmode isa Outside
        pad = gl.alignmode.padding
        BBox(
            left(suggestedbbox) + pad.left,
            right(suggestedbbox) - pad.right,
            bottom(suggestedbbox) + pad.bottom,
            top(suggestedbbox) - pad.top)
    elseif gl.alignmode isa Inside
        suggestedbbox
    elseif gl.alignmode isa Mixed
        pad = gl.alignmode.padding
        BBox(
            left(suggestedbbox) + ifnothing(pad.left, 0f0),
            right(suggestedbbox) - ifnothing(pad.right, 0f0),
            bottom(suggestedbbox) + ifnothing(pad.bottom, 0f0),
            top(suggestedbbox) - ifnothing(pad.top, 0f0))
    else
        error("Unknown AlignMode of type $(typeof(gl.alignmode))")
    end

    # first determine how big the protrusions on each side of all columns and rows are
    maxgrid = RowCols(gl.ncols, gl.nrows)
    # go through all the layout objects placed in the grid
    for c in gl.content
        idx_rect = side_indices(c)
        mapsides(idx_rect, maxgrid) do side, idx, grid
            grid[idx] = max(grid[idx], protrusion(c, side))
        end
    end

    # for the outside alignmode
    topprot = maxgrid.tops[1]
    bottomprot = maxgrid.bottoms[end]
    leftprot = maxgrid.lefts[1]
    rightprot = maxgrid.rights[end]

    # compute what size the gaps between rows and columns need to be
    colgaps = maxgrid.lefts[2:end] .+ maxgrid.rights[1:end-1]
    rowgaps = maxgrid.tops[2:end] .+ maxgrid.bottoms[1:end-1]

    # determine the biggest gap
    # using the biggest gap size for all gaps will make the layout more even, but one
    # could make this aspect customizable, because it might waste space
    if gl.equalprotrusiongaps[2]
        colgaps = ones(gl.ncols - 1) .* (gl.ncols <= 1 ? 0.0 : maximum(colgaps))
    end
    if gl.equalprotrusiongaps[1]
        rowgaps = ones(gl.nrows - 1) .* (gl.nrows <= 1 ? 0.0 : maximum(rowgaps))
    end

    # determine the vertical and horizontal space needed just for the gaps
    # again, the gaps are what the protrusions stick into, so they are not actually "empty"
    # depending on what sticks out of the plots
    sumcolgaps = (gl.ncols <= 1) ? 0.0 : sum(colgaps)
    sumrowgaps = (gl.nrows <= 1) ? 0.0 : sum(rowgaps)

    # compute what space remains for the inner parts of the plots
    remaininghorizontalspace = if gl.alignmode isa Inside
        width(bbox) - sumcolgaps
    elseif gl.alignmode isa Outside
        width(bbox) - sumcolgaps - leftprot - rightprot
    elseif gl.alignmode isa Mixed
        rightal = getside(gl.alignmode, Right())
        leftal = getside(gl.alignmode, Left())
        width(bbox) - sumcolgaps -
            (isnothing(leftal) ? 0 : leftprot) -
            (isnothing(rightal) ? 0 : rightprot)
    else
        error("Unknown AlignMode of type $(typeof(gl.alignmode))")
    end

    remainingverticalspace = if gl.alignmode isa Inside
        height(bbox) - sumrowgaps
    elseif gl.alignmode isa Outside
        height(bbox) - sumrowgaps - topprot - bottomprot
    elseif gl.alignmode isa Mixed
        topal = getside(gl.alignmode, Top())
        bottomal = getside(gl.alignmode, Bottom())
        height(bbox) - sumrowgaps -
            (isnothing(bottomal) ? 0 : bottomprot) -
            (isnothing(topal) ? 0 : topprot)
    else
        error("Unknown AlignMode of type $(typeof(gl.alignmode))")
    end

    # compute how much gap to add, in case e.g. labels are too close together
    # this is given as a fraction of the space used for the inner parts of the plots
    # so far, but maybe this should just be an absolute pixel value so it doesn't change
    # when resizing the window
    addedcolgaps = map(gl.addedcolgaps) do cg
        if cg isa Fixed
            return cg.x
        elseif cg isa Relative
            return cg.x * remaininghorizontalspace
        else
            return 0.0 # for float type inference
        end
    end
    addedrowgaps = map(gl.addedrowgaps) do rg
        if rg isa Fixed
            return rg.x
        elseif rg isa Relative
            return rg.x * remainingverticalspace
        else
            return 0.0 # for float type inference
        end
    end

    # compute the actual space available for the rows and columns (plots without protrusions)
    spaceforcolumns = remaininghorizontalspace - ((gl.ncols <= 1) ? 0.0 : sum(addedcolgaps))
    spaceforrows = remainingverticalspace - ((gl.nrows <= 1) ? 0.0 : sum(addedrowgaps))

    colwidths, rowheights = compute_col_row_sizes(spaceforcolumns, spaceforrows, gl)

    # don't allow smaller widths than 1 px even if it breaks the layout (better than weird glitches)
    colwidths = max.(colwidths, ones(length(colwidths)))
    rowheights = max.(rowheights, ones(length(rowheights)))

    # this is the vertical / horizontal space between the inner lines of all plots
    finalcolgaps = colgaps .+ addedcolgaps
    finalrowgaps = rowgaps .+ addedrowgaps

    # compute the resulting width and height of the gridlayout and compute
    # adjustments for the grid's alignment (this will only matter if the grid is
    # bigger or smaller than the bounding box it occupies)

    gridwidth = sum(colwidths) + sum(finalcolgaps) +
        (gl.alignmode isa Outside ? (leftprot + rightprot) : 0.0)
    gridheight = sum(rowheights) + sum(finalrowgaps) +
        (gl.alignmode isa Outside ? (topprot + bottomprot) : 0.0)


    # compute the x values for all left and right column boundaries
    xleftcols = if gl.alignmode isa Inside
        left(bbox) .+ cumsum([0; colwidths[1:end-1]]) .+
            cumsum([0; finalcolgaps])
    elseif gl.alignmode isa Outside
        left(bbox) .+ cumsum([0; colwidths[1:end-1]]) .+
            cumsum([0; finalcolgaps]) .+ leftprot
    elseif gl.alignmode isa Mixed
        leftal = getside(gl.alignmode, Left())
        left(bbox) .+ cumsum([0; colwidths[1:end-1]]) .+
            cumsum([0; finalcolgaps]) .+ (isnothing(leftal) ? 0 : leftprot)
    else
        error("Unknown AlignMode of type $(typeof(gl.alignmode))")
    end
    xrightcols = xleftcols .+ colwidths

    # compute the y values for all top and bottom row boundaries
    ytoprows = if gl.alignmode isa Inside
        top(bbox) .- cumsum([0; rowheights[1:end-1]]) .-
            cumsum([0; finalrowgaps])
    elseif gl.alignmode isa Outside
        top(bbox) .- cumsum([0; rowheights[1:end-1]]) .-
            cumsum([0; finalrowgaps]) .- topprot
    elseif gl.alignmode isa Mixed
        topal = getside(gl.alignmode, Top())
        top(bbox) .- cumsum([0; rowheights[1:end-1]]) .-
            cumsum([0; finalrowgaps]) .- (isnothing(topal) ? 0 : topprot)
    else
        error("Unknown AlignMode of type $(typeof(gl.alignmode))")
    end
    ybottomrows = ytoprows .- rowheights

    # now we can solve the content thats inside the grid because we know where each
    # column and row is placed, how wide it is, etc.
    # note that what we did at the top was determine the protrusions of all grid content,
    # but we know the protrusions before we know how much space each plot actually has
    # because the protrusions should be static (like tick labels etc don't change size with the plot)

    gridboxes = RowCols(
        xleftcols, xrightcols,
        ytoprows, ybottomrows
    )

    for c in gl.content
        idx_rect = side_indices(c)
        bbox_cell = mapsides(idx_rect, gridboxes) do side, idx, gridside
            gridside[idx]
        end

        solving_bbox = bbox_for_solving_from_side(maxgrid, bbox_cell, idx_rect, c.side)

        c.content.layoutnodes.suggestedbbox[] = solving_bbox
    end

    nothing
end


dirlength(gl::GridLayout, c::Col) = gl.ncols
dirlength(gl::GridLayout, r::Row) = gl.nrows

function dirgaps(gl::GridLayout, dir::GridDir)
    starts = zeros(Float32, dirlength(gl, dir))
    stops = zeros(Float32, dirlength(gl, dir))
    for c in gl.content
        span = getspan(c, dir)
        start = span.start
        stop = span.stop
        starts[start] = max(starts[start], protrusion(c, startside(dir)))
        stops[stop] = max(stops[stop], protrusion(c, stopside(dir)))
    end
    starts, stops
end

dirsizes(gl::GridLayout, c::Col) = gl.colsizes
dirsizes(gl::GridLayout, r::Row) = gl.rowsizes

"""
Determine the size of a grid layout along one of its dimensions.
`Row` measures from bottom to top and `Col` from left to right.
The size is dependent on the alignmode of the grid, `Outside` includes
protrusions and paddings.
"""
function determinedirsize(gl::GridLayout, gdir::GridDir)
    sum_dirsizes = 0

    sizes = dirsizes(gl, gdir)

    for idir in 1:dirlength(gl, gdir)
        # width can only be determined for fixed and auto
        sz = sizes[idir]
        dsize = determinedirsize(idir, gl, gdir)

        if isnothing(dsize)
            # early exit if a colsize can not be determined
            return nothing
        end
        sum_dirsizes += dsize
    end

    dirgapsstart, dirgapsstop = dirgaps(gl, Col())

    forceequalprotrusiongaps = gl.equalprotrusiongaps[gdir isa Row ? 1 : 2]

    dirgapsizes = if forceequalprotrusiongaps
        innergaps = dirgapsstart[2:end] .+ dirgapsstop[1:end-1]
        m = maximum(innergaps)
        innergaps .= m
    else
        innergaps = dirgapsstart[2:end] .+ dirgapsstop[1:end-1]
    end

    inner_gapsizes = dirlength(gl, gdir) > 1 ? sum(dirgapsizes) : 0

    addeddirgapsizes = gdir isa Row ? gl.addedrowgaps : gl.addedcolgaps

    addeddirgaps = dirlength(gl, gdir) == 1 ? 0 : sum(addeddirgapsizes) do c
        if c isa Fixed
            c.x
        elseif c isa Relative
            error("Auto grid size not implemented with relative gaps")
        end
    end

    inner_size_combined = sum_dirsizes + inner_gapsizes + addeddirgaps
    return if gl.alignmode isa Inside
        inner_size_combined
    elseif gl.alignmode isa Outside
        paddings = if gdir isa Row
            gl.alignmode.padding.top + gl.alignmode.padding.bottom
        else
            gl.alignmode.padding.left + gl.alignmode.padding.right
        end
        inner_size_combined + dirgapsstart[1] + dirgapsstop[end] + paddings
    else
        error("Unknown AlignMode of type $(typeof(gl.alignmode))")
    end
end


"""
Determine the size of one row or column of a grid layout.
"""
function determinedirsize(idir, gl, dir::GridDir)

    sz = dirsizes(gl, dir)[idir]

    if sz isa Fixed
        # fixed dir size can simply be returned
        return sz.x
    elseif sz isa Relative
        # relative dir size can't be inferred
        return nothing
    elseif sz isa Auto
        # auto dir size can either be determined or not, depending on the
        # trydetermine flag
        !sz.trydetermine && return nothing

        dirsize = nothing
        for c in gl.content
            # content has to be single span to be determinable in size
            singlespanned = getspan(c, dir).start == getspan(c, dir).stop == idir

            # content has to be placed with Inner side, otherwise it's protrusion
            # content
            is_inner = c.side isa Inner

            if singlespanned && is_inner
                s = determinedirsize(c.content, dir, c.side)
                if !isnothing(s)
                    dirsize = isnothing(dirsize) ? s : max(dirsize, s)
                end
            end
        end
        return dirsize
    end
    nothing
end


function compute_col_row_sizes(spaceforcolumns, spaceforrows, gl)
    # the space for columns and for rows is divided depending on the sizes
    # stored in the grid layout

    # rows / cols with Auto size must have single span content that
    # can report its own size, otherwise they can't determine their own size
    # alternatively, if there is only one Auto row / col it can get the rest
    # that remains after the other specified sizes are subtracted

    # rows / cols with Fixed size get that size

    # rows / cols with Relative size get that fraction of the available space

    colwidths = zeros(gl.ncols)
    rowheights = zeros(gl.nrows)

    # store sizes in arrays with indices so we can keep track of them
    icsizes = collect(enumerate(gl.colsizes))
    irsizes = collect(enumerate(gl.rowsizes))

    filtersize(T::Type) = isize -> isize[2] isa T

    fcsizes = filter(filtersize(Fixed), icsizes)
    frsizes = filter(filtersize(Fixed), irsizes)

    relcsizes = filter(filtersize(Relative), icsizes)
    relrsizes = filter(filtersize(Relative), irsizes)

    acsizes = filter(filtersize(Auto), icsizes)
    arsizes = filter(filtersize(Auto), irsizes)

    aspcsizes = filter(filtersize(Aspect), icsizes)
    asprsizes = filter(filtersize(Aspect), irsizes)

    determined_acsizes = map(acsizes) do (i, c)
        (i, determinedirsize(i, gl, Col()))
    end
    det_acsizes = filter(tup -> !isnothing(tup[2]), determined_acsizes)
    nondets_c = filter(tup -> isnothing(tup[2]), determined_acsizes)
    nondet_acsizes = map(nondets_c) do (i, noth)
        i, gl.colsizes[i]
    end

    determined_arsizes = map(arsizes) do (i, c)
        (i, determinedirsize(i, gl, Row()))
    end
    det_arsizes = filter(tup -> !isnothing(tup[2]), determined_arsizes)
    nondets_r = filter(tup -> isnothing(tup[2]), determined_arsizes)
    nondet_arsizes = map(nondets_r) do (i, noth)
        i, gl.rowsizes[i]
    end

    # assign fixed sizes first
    map(fcsizes) do (i, f)
        colwidths[i] = f.x
    end
    map(frsizes) do (i, f)
        rowheights[i] = f.x
    end

    # next relative sizes
    map(relcsizes) do (i, r)
        colwidths[i] = r.x * spaceforcolumns
    end
    map(relrsizes) do (i, r)
        rowheights[i] = r.x * spaceforrows
    end

    # next determinable auto sizes
    map(det_acsizes) do (i, x)
        colwidths[i] = x
    end
    map(det_arsizes) do (i, x)
        rowheights[i] = x
    end

    # next aspect sizes
    map(aspcsizes) do (i, asp)
        index = asp.index
        ratio = asp.ratio
        rowsize = gl.rowsizes[index]
        rowheight = if rowsize isa Union{Fixed, Relative, Auto}
            if rowsize isa Auto
                if !isempty(nondet_arsizes) && any(x -> x[1] == index, nondet_arsizes)
                    error("Can't use aspect ratio with an undeterminable Auto size")
                end
            end
            rowheights[index]
        else
            error("Aspect size can only work in conjunction with Fixed, Relative, or determinable Auto, not $(typeof(gl.rowsizes[index]))")
        end
        colwidths[i] = rowheight * ratio
    end

    map(asprsizes) do (i, asp)
        index = asp.index
        ratio = asp.ratio
        colsize = gl.colsizes[index]
        colwidth = if colsize isa Union{Fixed, Relative, Auto}
            if colsize isa Auto
                if !isempty(nondet_acsizes) && any(x -> x[1] == index, nondet_acsizes)
                    error("Can't use aspect ratio with an undeterminable Auto size")
                end
            end
            colwidths[index]
        else
            error("Aspect size can only work in conjunction with Fixed, Relative, or determinable Auto, not $(typeof(gl.rowsizes[index]))")
        end
        rowheights[i] = colwidth * ratio
    end

    # next undeterminable auto sizes
    if !isempty(nondet_acsizes)
        remaining = spaceforcolumns - sum(colwidths)
        nondet_acsizes
        sumratios = sum(nondet_acsizes) do (i, c)
            c.ratio
        end
        map(nondet_acsizes) do (i, c)
            colwidths[i] = remaining * c.ratio / sumratios
        end
    end
    if !isempty(nondet_arsizes)
        remaining = spaceforrows - sum(rowheights)
        sumratios = sum(nondet_arsizes) do (i, r)
            r.ratio
        end
        map(nondet_arsizes) do (i, r)
            rowheights[i] = remaining * r.ratio / sumratios
        end
    end

    colwidths, rowheights
end

function Base.setindex!(g::GridLayout, content, rows::Indexables, cols::Indexables, side::Side = Inner())
    add_content!(g, content, rows, cols, side)
    content
end

function Base.setindex!(g::GridLayout, content_array::AbstractArray{T, 2}) where T
    rowrange = 1:size(content_array, 1)
    colrange = 1:size(content_array, 2)
    g[rowrange, colrange] = content_array
end

function Base.setindex!(g::GridLayout, content_array::AbstractArray{T, 1}) where T
    error("""
        You can only assign a one-dimensional content AbstractArray if you also specify the direction in the layout.
        Valid options are :h for horizontal and :v for vertical.
        Example:
            layout[:h] = contentvector
    """)
end

function Base.setindex!(g::GridLayout, content_array::AbstractArray{T, 1}, h_or_v::Symbol) where T
    if h_or_v == :h
        g[1, 1:length(content_array)] = content_array
    elseif h_or_v == :v
        g[1:length(content_array), 1] = content_array
    else
        error("""
            Invalid direction specifier $h_or_v.
            Valid options are :h for horizontal and :v for vertical.
        """)
    end
end

function Base.setindex!(g::GridLayout, content_array::AbstractArray, rows::Indexables, cols::Indexables)

    rows, cols = to_ranges(g, rows, cols)

    if rows.start < 1
        error("Can't prepend rows using array syntax so far, start row $(rows.start) is smaller than 1.")
    end
    if cols.start < 1
        error("Can't prepend columns using array syntax so far, start column $(cols.start) is smaller than 1.")
    end

    nrows = length(rows)
    ncols = length(cols)
    ncells = nrows * ncols

    if ndims(content_array) == 2
        if size(content_array) != (nrows, ncols)
            error("Content array size is size $(size(content_array)) for $nrows rows and $ncols cols")
        end
        # put the array content into the grid layout in order
        for (i, r) in enumerate(rows), (j, c) in enumerate(cols)
            g[r, c] = content_array[i, j]
        end
    elseif ndims(content_array) == 1
        if length(content_array) != nrows * ncols
            error("Content array size is length $(length(content_array)) for $nrows * $ncols cells")
        end
        # put the content in the layout along columns first, because that is more
        # intuitive
        for (i, (c, r)) in enumerate(Iterators.product(cols, rows))
            g[r, c] = content_array[i]
        end
    else
        error("Can't assign a content array with $(ndims(content_array)) dimensions, only 1 or 2.")
    end
    content_array
end

function GridContent(content::T, span::Span, side::Side) where T
    needs_update = Node(false)
    # connect the correct nodes
    protrusions_handle = on(protrusionnode(content)) do p
        needs_update[] = true
    end
    computedsize_handle = on(computedsizenode(content)) do c
        needs_update[] = true
    end
    GridContent{GridLayout, T}(nothing, content, span, side, needs_update,
        protrusions_handle, computedsize_handle)
end

function add_content!(g::GridLayout, content, rows, cols, side::Side)
    rows, cols = adjust_rows_cols!(g, rows, cols)

    gc = if !isnothing(content.layoutnodes.gridcontent)
        # take the existing gridcontent, remove it from its gridlayout if it has one,
        # and modify it with the new span and side
        gridc = content.layoutnodes.gridcontent
        remove_from_gridlayout!(gridc)
        gridc.span = Span(rows, cols)
        gridc.side = side
        gridc
    else
        # make a new one if none existed
        GridContent(content, Span(rows, cols), side)
    end

    content.layoutnodes.gridcontent = gc

    connect_layoutnodes!(gc)

    add_to_gridlayout!(g, gc)
end

function Base.lastindex(g::GridLayout, d)
    if d == 1
        g.nrows
    elseif d == 2
        g.ncols
    else
        error("A grid only has two dimensions, you're indexing dimension $d.")
    end
end

function is_range_within(inner::UnitRange, outer::UnitRange)
    inner.start >= outer.start && inner.stop <= outer.stop
end

function Base.getindex(g::GridLayout, rows::Indexables, cols::Indexables)
    GridPosition(g, rows, cols)
end

function Base.setindex!(gp::GridPosition, element)
    gp.layout[gp.rows, gp.cols] = element
end
