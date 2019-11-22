"""
    side_indices(c::SpannedLayout)::RowCols{Int}

Indices of the rows / cols for each side
"""
function side_indices(c::SpannedLayout)
    return RowCols(
        c.sp.cols.start,
        c.sp.cols.stop,
        c.sp.rows.start,
        c.sp.rows.stop,
    )
end



"""
These functions tell whether an object in a grid touches the left, top, etc. border
of the grid. This means that it is relevant for the grid's own protrusion on that side.
"""
ismostin(sp::SpannedLayout, grid, ::Left) = sp.sp.cols.start == 1
ismostin(sp::SpannedLayout, grid, ::Right) = sp.sp.cols.stop == grid.ncols
ismostin(sp::SpannedLayout, grid, ::Bottom) = sp.sp.rows.stop == grid.nrows
ismostin(sp::SpannedLayout, grid, ::Top) = sp.sp.cols.start == 1

isleftmostin(sp::SpannedLayout, grid) = ismostin(sp, grid, Left())
isrightmostin(sp::SpannedLayout, grid) = ismostin(sp, grid, Right())
isbottommostin(sp::SpannedLayout, grid) = ismostin(sp, grid, Bottom())
istopmostin(sp::SpannedLayout, grid) = ismostin(sp, grid, Top())


function with_updates_suspended(f::Function, gl::GridLayout)
    gl.block_updates = true
    f()
    gl.block_updates = false
    gl.needs_update[] = true
end

parentlayout(gl::GridLayout) = gl.parent

function GridLayout(nrows, ncols;
        parent = nothing,
        rowsizes = nothing,
        colsizes = nothing,
        addedrowgaps = nothing,
        addedcolgaps = nothing,
        alignmode = Inside(),
        equalprotrusiongaps = (false, false))

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

    GridLayout(
        parent, content, nrows, ncols, rowsizes, colsizes, addedrowgaps,
        addedcolgaps, alignmode, equalprotrusiongaps, needs_update)
end

# these must be defined for special types that want protrusions or specified
# widths and heights
protrusionnode(anything) = Node{Union{Nothing, NTuple{4, Float32}}}(nothing)
widthnode(anything) = Node{Union{Nothing, Float32}}(nothing)
heightnode(anything) = Node{Union{Nothing, Float32}}(nothing)

parentlayout(pl::ProtrusionLayout) = pl.parent

function ProtrusionLayout(content)
    needs_update = Node(false)

    protrusions = protrusionnode(content)
    width = widthnode(content)
    height = heightnode(content)

    # the nothing parent here has to be replaced by a grid parent later
    # when placing this layout in the grid layout
    pl = ProtrusionLayout(nothing, protrusions, width, height, needs_update, content)

    update_func = x -> begin
        p = parentlayout(pl)
        if isnothing(p)
            error("This layout has no parent and can't continue the update signal chain.")
        end
        p.needs_update[] = true
    end

    on(update_func, protrusions)
    on(update_func, width)
    on(update_func, height)

    pl
end

protrusionnode(pl::ProtrusionLayout) = pl.protrusions
widthnode(pl::ProtrusionLayout) = pl.widthnode
heightnode(pl::ProtrusionLayout) = pl.heightnode


parentlayout(pl::ProtrusionContentLayout) = pl.parent

function ProtrusionContentLayout(content, side::Side)
    needs_update = Node(false)

    width = widthnode(content)
    height = heightnode(content)

    # the nothing parent here has to be replaced by a grid parent later
    # when placing this layout in the grid layout
    pl = ProtrusionContentLayout(nothing, width, height, side, needs_update, content)

    update_func = x -> begin
        p = parentlayout(pl)
        if isnothing(p)
            error("This layout has no parent and can't continue the update signal chain.")
        end
        p.needs_update[] = true
    end

    on(update_func, width)
    on(update_func, height)

    pl
end



"""
All the protrusion functions calculate how much stuff "sticks out" of a layoutable object.
This is so that collisions are avoided, while what is actually aligned is the
"important" edges of the layout objects.
"""
leftprotrusion(x) = protrusion(x, Left())
rightprotrusion(x) = protrusion(x, Right())
bottomprotrusion(x) = protrusion(x, Bottom())
topprotrusion(x) = protrusion(x, Top())

protrusion(a::ProtrusionLayout, ::Left) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[][1]
protrusion(a::ProtrusionLayout, ::Right) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[][2]
protrusion(a::ProtrusionLayout, ::Top) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[][3]
protrusion(a::ProtrusionLayout, ::Bottom) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[][4]
protrusion(sp::SpannedLayout, side::Side) = protrusion(sp.al, side)

function protrusion(a::ProtrusionContentLayout, ::Left)
    if a.side isa Left || a.side isa TopLeft || a.side isa BottomLeft
        isnothing(a.widthnode[]) ? 0f0 : a.widthnode[]
    else
        0f0
    end
end
function protrusion(a::ProtrusionContentLayout, ::Right)
    if a.side isa Right || a.side isa TopRight || a.side isa BottomRight
        isnothing(a.widthnode[]) ? 0f0 : a.widthnode[]
    else
        0f0
    end
end
function protrusion(a::ProtrusionContentLayout, ::Top)
    if a.side isa Top || a.side isa TopLeft || a.side isa TopRight
        isnothing(a.heightnode[]) ? 0f0 : a.heightnode[]
    else
        0f0
    end
end
function protrusion(a::ProtrusionContentLayout, ::Bottom)
    if a.side isa Bottom || a.side isa BottomRight || a.side isa BottomLeft
        isnothing(a.heightnode[]) ? 0f0 : a.heightnode[]
    else
        0f0
    end
end

function protrusion(gl::GridLayout, side::Side)
    # when we align with the outside there is by definition no protrusion
    if gl.alignmode isa Outside
        return 0.0
    elseif gl.alignmode isa Inside
        return mapreduce(max, gl.content, init = 0.0) do elem
            # we use only objects that stick out on this side
            # And from those we use the maximum protrusion
            ismostin(elem, gl, side) ? protrusion(elem, side) : 0.0
        end
    end
end

protrusion(s::SolvedProtrusionLayout, ::Left) = left(s.inner) - left(s.outer)
function protrusion(s::SolvedProtrusionLayout, side::Side)
    return s.outer[side] - s.inner[side]
end

"""
This function solves a grid layout such that the "important lines" fit exactly
into a given bounding box. This means that the protrusions of all objects inside
the grid are not taken into account. This is needed if the grid is itself placed
inside another grid.
"""
function solve(gl::GridLayout, bbox::BBox)

    if gl.alignmode isa Outside
        l, r, t, b = gl.alignmode.padding
        bbox = BBox(left(bbox) + l, right(bbox) - r, top(bbox) - t, bottom(bbox) + b)
    end

    # first determine how big the protrusions on each side of all columns and rows are
    maxgrid = RowCols(gl.ncols, gl.nrows)
    # go through all the layout objects placed in the grid
    for c in gl.content
        idx_rect = side_indices(c)
        mapsides(idx_rect, maxgrid) do side, idx, grid
            grid[idx] = max(grid[idx], protrusion(c.al, side))
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
    end
    remainingverticalspace = if gl.alignmode isa Inside
        height(bbox) - sumrowgaps
    elseif gl.alignmode isa Outside
        height(bbox) - sumrowgaps - topprot - bottomprot
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
    # # compute the column widths and row heights using the specified row and column ratios
    # colwidths = gl.colratios ./ sum(gl.colratios) .* spaceforcolumns
    # rowheights = gl.rowratios ./ sum(gl.rowratios) .* spaceforrows

    # this is the vertical / horizontal space between the inner lines of all plots
    finalcolgaps = colgaps .+ addedcolgaps
    finalrowgaps = rowgaps .+ addedrowgaps

    # compute the x values for all left and right column boundaries
    xleftcols = if gl.alignmode isa Inside
        left(bbox) .+ cumsum([0; colwidths[1:end-1]]) .+ cumsum([0; finalcolgaps])
    elseif gl.alignmode isa Outside
        left(bbox) .+ cumsum([0; colwidths[1:end-1]]) .+ cumsum([0; finalcolgaps]) .+ leftprot
    end
    xrightcols = xleftcols .+ colwidths

    # compute the y values for all top and bottom row boundaries
    ytoprows = if gl.alignmode isa Inside
        top(bbox) .- cumsum([0; rowheights[1:end-1]]) .- cumsum([0; finalrowgaps])
    elseif gl.alignmode isa Outside
        top(bbox) .- cumsum([0; rowheights[1:end-1]]) .- cumsum([0; finalrowgaps]) .- topprot
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
    solvedcontent = map(gl.content) do c
        idx_rect = side_indices(c)
        bbox_cell = mapsides(idx_rect, gridboxes) do side, idx, gridside
            gridside[idx]
        end
        solved = if c.al isa ProtrusionContentLayout
            prot_l = maxgrid.lefts[idx_rect.lefts]
            prot_r = maxgrid.rights[idx_rect.rights]
            prot_t = maxgrid.tops[idx_rect.tops]
            prot_b = maxgrid.bottoms[idx_rect.bottoms]
            protrusion_bbox = BBox(prot_l, prot_r, prot_t, prot_b)
            solve(c.al, bbox_cell, protrusion_bbox)
        else
            solve(c.al, bbox_cell)
        end
        return SpannedLayout(solved, c.sp)
    end
    # return a solved grid layout in which all objects are also solved layout objects
    return SolvedGridLayout(
        bbox, solvedcontent,
        gl.nrows, gl.ncols,
        gridboxes
    )
end

startside(c::Col) = Left()
stopside(c::Col) = Right()
startside(r::Row) = Top()
stopside(r::Row) = Bottom()

dirlength(gl::GridLayout, c::Col) = gl.ncols
dirlength(gl::GridLayout, r::Row) = gl.nrows

function dirgaps(gl::GridLayout, dir::GridDir)
    starts = zeros(Float32, dirlength(gl, dir))
    stops = zeros(Float32, dirlength(gl, dir))
    for c in gl.content
        sp = span(c, dir)
        start = sp.start
        stop = sp.stop
        starts[start] = max(starts[start], protrusion(c, startside(dir)))
        stops[stop] = max(stops[stop], protrusion(c, stopside(dir)))
    end
    starts, stops
end

dirsizes(gl::GridLayout, c::Col) = gl.colsizes
dirsizes(gl::GridLayout, r::Row) = gl.rowsizes

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
        r = gdir isa Row
        paddings = sum(gl.alignmode.padding[gdir isa Row ? (1:2) : (3:4)])
        inner_size_combined + dirgapsstart[1] + dirgapsstop[end] + paddings
    end
end

span(sp::SpannedLayout, dir::Col) = sp.sp.cols
span(sp::SpannedLayout, dir::Row) = sp.sp.rows

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
            singlespanned = span(c, dir).start == span(c, dir).stop == idir

            if singlespanned
                s = determinedirsize(c.al, dir)
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

function determinedirsize(pl::ProtrusionLayout, gdir::GridDir)
    if gdir isa Row
        if isnothing(heightnode(pl)[])
            nothing
        else
            heightnode(pl)[] + protrusion(pl, Top()) + protrusion(pl, Bottom())
        end
    else
        if isnothing(widthnode(pl)[])
            nothing
        else
            widthnode(pl)[] + protrusion(pl, Left()) + protrusion(pl, Right())
        end
    end
end

function determinedirsize(pcl::ProtrusionContentLayout, gdir::GridDir)
    nothing
end

function solve(ua::ProtrusionLayout, innerbbox)
    ib = innerbbox
    bbox = BBox(
        left(ib) - protrusion(ua, Left()),
        right(ib) + protrusion(ua, Right()),
        top(ib) + protrusion(ua, Top()),
        bottom(ib) - protrusion(ua, Bottom())
    )
    SolvedProtrusionLayout(innerbbox, ua.content)
end

function solve(pcl::ProtrusionContentLayout, innerbbox, protrusion_bbox)
    ib = innerbbox
    pb = protrusion_bbox

    bbox = if pcl.side isa Left
        BBox(left(ib) - left(pb), left(ib), top(ib), bottom(ib))
    elseif pcl.side isa Top
        BBox(left(ib), right(ib), top(ib) + top(pb), top(ib))
    elseif pcl.side isa Right
        BBox(right(ib), right(ib) + right(pb), top(ib), bottom(ib))
    elseif pcl.side isa Bottom
        BBox(left(ib), right(ib), bottom(ib), bottom(ib) - bottom(pb))
    elseif pcl.side isa TopLeft
        BBox(left(ib) - left(pb), left(ib), top(ib) + top(pb), top(ib))
    elseif pcl.side isa TopRight
        BBox(right(ib), right(ib) + right(pb), top(ib) + top(pb), top(ib))
    elseif pcl.side isa BottomRight
        BBox(right(ib), right(ib) + right(pb), bottom(ib), bottom(ib) - bottom(pb))
    elseif pcl.side isa BottomLeft
        BBox(left(ib) - left(pb), left(ib), bottom(ib), bottom(ib) - bottom(pb))
    end

    SolvedProtrusionContentLayout(bbox, pcl.content)
end

const Indexables = Union{UnitRange, Int, Colon}



function adjust_rows_cols!(g::GridLayout, rows, cols)
    if rows isa Int
        rows = rows:rows
    elseif rows isa Colon
        rows = 1:g.nrows
    end
    if cols isa Int
        cols = cols:cols
    elseif cols isa Colon
        cols = 1:g.ncols
    end

    if rows.start < 1
        n = 1 - rows.start
        prependrows!(g, n)
        # adjust rows for the newly prepended ones
        rows = rows .+ n
    end
    if rows.stop > g.nrows
        n = rows.stop - g.nrows
        appendrows!(g, n)
    end
    if cols.start < 1
        n = 1 - cols.start
        prependcols!(g, n)
        # adjust cols for the newly prepended ones
        cols = cols .+ n
    end
    if cols.stop > g.ncols
        n = cols.stop - g.ncols
        appendcols!(g, n)
    end

    rows, cols
end


"""
This function allows indexing syntax to add a layout object to a grid.
You can do:

grid[1, 1] = obj
grid[1, :] = obj
grid[1:3, 2:5] = obj

and all combinations of the above
"""
function Base.setindex!(g::GridLayout, a::AbstractLayout, rows::Indexables, cols::Indexables)
    detachfromparent!(a)
    add_layout!(g, a, rows, cols)
    a
end

"""
This function is similar to the other setindex! but is for all objects that are
not themselves layouts. They need to be wrapped in a layout first before being
added. This is determined by the defaultlayout function.
"""
function Base.setindex!(g::GridLayout, content, rows::Indexables, cols::Indexables)

    # check if this content already sits somewhere in the grid layout tree
    # if yes, remove it from there before attaching it here
    parentlayout, index = find_in_grid_tree(content, g)
    if !isnothing(parentlayout) && !isnothing(index)
        deleteat!(parentlayout.content, index)
    end

    layout = defaultlayout(content)
    add_layout!(g, layout, rows, cols)
    content
end

function Base.setindex!(g::GridLayout, content, rows::Indexables, cols::Indexables, side::Symbol)

    side_struct = if side in (:t, :top)
        Top()
    elseif side in (:tr, :topright)
        TopRight()
    elseif side in (:r, :right)
        Right()
    elseif side in (:br, :bottomright)
        BottomRight()
    elseif side in (:b, :bottom)
        Bottom()
    elseif side in (:bl, :bottomleft)
        BottomLeft()
    elseif side in (:l, :left)
        Left()
    elseif side in (:tl, :topleft)
        TopLeft()
    else
        error("Invalid side identifier $side")
    end

    # check if this content already sits somewhere in the grid layout tree
    # if yes, remove it from there before attaching it here
    parentlayout, index = find_in_grid_tree(content, g)
    if !isnothing(parentlayout) && !isnothing(index)
        deleteat!(parentlayout.content, index)
    end

    layout = ProtrusionContentLayout(content, side_struct)
    add_layout!(g, layout, rows, cols)
    content
end

function add_layout!(g::GridLayout, layout::AbstractLayout, rows, cols)
    rows, cols = adjust_rows_cols!(g, rows, cols)
    layout.parent = g
    sp = SpannedLayout(layout, Span(rows, cols))
    connectchildlayout!(g, sp)
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

function connectchildlayout!(g::GridLayout, spa::SpannedLayout)
    push!(g.content, spa)

    # remove all listeners from needs_update because they could be pointing
    # to previous parents if we're re-nesting layout objects
    empty!(spa.al.needs_update.listeners)

    on(spa.al.needs_update) do update
        g.needs_update[] = true
    end
    # trigger relayout
    g.needs_update[] = true
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

    gl.content = map(gl.content) do spal
        span = spal.sp
        newspan = Span(span.rows .+ n, span.cols)
        SpannedLayout(spal.al, newspan)
    end

    with_updates_suspended(gl) do
        gl.nrows += n
        prepend!(gl.rowsizes, rowsizes)
        prepend!(gl.addedrowgaps, addedrowgaps)
    end
end

function prependcols!(gl::GridLayout, n::Int; colsizes=nothing, addedcolgaps=nothing)

    colsizes = convert_contentsizes(n, colsizes)
    addedcolgaps = convert_gapsizes(n, addedcolgaps)

    gl.content = map(gl.content) do spal
        span = spal.sp
        newspan = Span(span.rows, span.cols .+ n)
        SpannedLayout(spal.al, newspan)
    end

    with_updates_suspended(gl) do
        gl.ncols += n
        prepend!(gl.colsizes, colsizes)
        prepend!(gl.addedcolgaps, addedcolgaps)
    end
end

function nest_content_into_gridlayout!(gl::GridLayout, rows::Indexables, cols::Indexables)

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
    i = 1
    while i <= length(gl.content)
        spal = gl.content[i]

        if (spal.sp.rows.start >= newrows.start && spal.sp.rows.stop <= newrows.stop &&
            spal.sp.cols.start >= newcols.start && spal.sp.cols.stop <= newcols.stop)

            # adjust span for new grid position and place content inside it
            subgl[spal.sp.rows .- (newrows.start - 1), spal.sp.cols .- (newcols.start - 1)] = spal.al
            deleteat!(gl.content, i)
            continue
            # don't advance i because there's one piece of content less in the queue
            # and the next item is in the same position as the old removed one
        end
        i += 1
    end

    gl[newrows, newcols] = subgl

    subgl
end

function find_in_grid(obj, container::GridLayout)
    for i in 1:length(container.content)
        layout = container.content[i].al
        if layout isa ProtrusionLayout
            if layout.content === obj
                return i
            end
        end
    end
    nothing
end

function find_in_grid(layout::AbstractLayout, container::GridLayout)
    for i in 1:length(container.content)
        if container.content[i].al === layout
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
        candidate = container.content[i].al
        # for non layout objects like LayoutedAxis we check if they are inside
        # any protrusion layout we find
        if candidate isa ProtrusionLayout
            if candidate.content === obj
                return container, i
            end
        elseif candidate isa GridLayout
            return find_in_grid_and_subgrids(obj, candidate)
        end
    end
    nothing, nothing
end

function find_in_grid_and_subgrids(layout::AbstractLayout, container::GridLayout)
    for i in 1:length(container.content)
        candidate = container.content[i].al
        if candidate === layout
            return container, i
        elseif candidate isa GridLayout
            return find_in_grid_and_subgrids(layout, candidate)
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

function detachfromparent!(l::AbstractLayout)
    if l.parent isa Scene
        error("Can't detach a grid layout from its parent if it's a Scene.")
    elseif l.parent isa GridLayout
        i = find_in_grid(l, l.parent)
        isnothing(i) && error("Layout could not be found in its parent's content.")

        deleteat!(l.parent.content, i)
        l.parent = nothing
    end
end
