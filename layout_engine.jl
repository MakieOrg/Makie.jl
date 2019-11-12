using Observables: onany

abstract type Alignable end

"""
Used to specify space that is occupied in a grid. Like 1:1|1:1 for the first square,
or 2:3|1:4 for a rect over the 2nd and 3rd row and the first four columns.
"""
struct Span
    rows::UnitRange{Int64}
    cols::UnitRange{Int64}
end

"""
An object that can be aligned that also specifies how much space it occupies in
a grid via its span.
"""
struct SpannedAlignable{T <: Alignable}
    al::T
    sp::Span
end

"""
    side_indices(c::SpannedAlignable)::RowCols{Int}

Indices of the rows / cols for each side
"""
function side_indices(c::SpannedAlignable)
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
ismostin(sp::SpannedAlignable, grid, ::Left) = sp.sp.cols.start == 1
ismostin(sp::SpannedAlignable, grid, ::Right) = sp.sp.cols.stop == grid.ncols
ismostin(sp::SpannedAlignable, grid, ::Bottom) = sp.sp.rows.stop == grid.nrows
ismostin(sp::SpannedAlignable, grid, ::Top) = sp.sp.cols.start == 1

isleftmostin(sp::SpannedAlignable, grid) = ismostin(sp, grid, Left())
isrightmostin(sp::SpannedAlignable, grid) = ismostin(sp, grid, Right())
isbottommostin(sp::SpannedAlignable, grid) = ismostin(sp, grid, Bottom())
istopmostin(sp::SpannedAlignable, grid) = ismostin(sp, grid, Top())

abstract type AlignMode end

struct Inside <: AlignMode end
struct Outside <: AlignMode
    padding::Tuple{Float32, Float32, Float32, Float32}
end

Outside() = Outside(0f0)
Outside(padding::Real) = Outside(Float32.(Tuple(padding for _ in 1:4)))
Outside(left::Real, right::Real, top::Real, bottom::Real) = Outside(Float32.((left, right, top, bottom)))

abstract type ContentSize end
abstract type GapSize <: ContentSize end

struct Auto <: ContentSize
    x::Float64 # ratio in case it's not determinable
end
Auto() = Auto(1)
struct Fixed <: GapSize
    x::Float64
end
struct Relative <: GapSize
    x::Float64
end
struct Aspect <: ContentSize
    index::Int
    ratio::Float64
end

mutable struct GridLayout <: Alignable
    parent::Union{Nothing, Scene, GridLayout}
    content::Vector{SpannedAlignable}
    nrows::Int
    ncols::Int
    rowsizes::Vector{ContentSize}
    colsizes::Vector{ContentSize}
    addedrowgaps::Vector{GapSize}
    addedcolgaps::Vector{GapSize}
    alignmode::AlignMode
    equalprotrusiongaps::Tuple{Bool, Bool}
    needs_update::Node{Bool}
    block_updates::Bool

    function GridLayout(
        parent, content, nrows, ncols, rowsizes, colsizes,
        addedrowgaps, addedcolgaps, alignmode, equalprotrusiongaps, needs_update)

        if nrows < 1
            error("Number of rows can't be smaller than 1")
        end
        if ncols < 1
            error("Number of columns can't be smaller than 1")
        end

        if length(rowsizes) != nrows
            error("There are $nrows rows but $(length(rowsizes)) row sizes.")
        end
        if length(colsizes) != ncols
            error("There are $ncols columns but $(length(colsizes)) column sizes.")
        end
        if length(addedrowgaps) != nrows - 1
            error("There are $nrows rows but $(length(addedrowgaps)) row gaps.")
        end
        if length(addedcolgaps) != ncols - 1
            error("There are $ncols columns but $(length(addedcolgaps)) column gaps.")
        end

        g = new(parent, content, nrows, ncols, rowsizes, colsizes,
            addedrowgaps, addedcolgaps, alignmode, equalprotrusiongaps, needs_update, false)

        setup_updates!(g)

        g
    end
end

function setup_updates!(gl::GridLayout)
    parent = gl.parent

    if isnothing(parent)
        # Can't setup updates for GridLayout if no parent is defined."
    elseif parent isa Scene
        on(gl.needs_update) do update
            if !gl.block_updates
                sg = solve(gl, BBox(shrinkbymargin(pixelarea(parent)[], 0)))
                applylayout(sg)
            end
        end

        # update when parent scene changes size
        on(pixelarea(parent)) do px
            if !gl.block_updates
                gl.needs_update[] = true
            end
        end
    elseif parent isa GridLayout
        on(gl.needs_update) do update
            if !gl.block_updates
                parent.needs_update[] = true
            end
        end
    end
end

function with_updates_suspended(f::Function, gl::GridLayout)
    gl.block_updates = true
    f()
    gl.block_updates = false
    gl.needs_update[] = true
end

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

struct SolvedGridLayout <: Alignable
    bbox::BBox
    content::Vector{SpannedAlignable}
    nrows::Int
    ncols::Int
    grid::RowCols{Vector{Float64}}
end

struct SolvedAxisLayout <: Alignable
    bbox::BBox
    bboxnode::Node{BBox}
end

struct AxisAspect
    aspect::Union{Float32, Nothing}
end

struct AxisLayout <: Alignable
    parent::GridLayout
    protrusions::Node{Tuple{Float32, Float32, Float32, Float32}}
    # aspect::Node{AxisAspect}
    # alignment::Node{Tuple{Float32, Float32}}
    # maxsize::Node{Tuple{Float32, Float32}}
    bboxnode::Node{BBox}
    needs_update::Node{Bool}
end

function AxisLayout(parent, protrusions, bboxnode)
    # bboxnode now is supplied by the axis itself

    # bboxnode = Node(BBox(0, 1, 1, 0))
    needs_update = Node(false)
    on(protrusions) do p
        needs_update[] = true
    end
    AxisLayout(parent, protrusions, bboxnode, needs_update)
end

struct SolvedBoxLayout <: Alignable
    bbox::BBox
    bboxnode::Node{BBox}
end

"""
An alignable that contains something of a fixed size, like some text.
There will usually be more space available in at least one direction than
just the fixed size of the box, so the alignment says where
in the available BBox the fixed size content should be placed.
For example, the figure title is placed above all else, but can then
be aligned on the left, in the center, or on the right.
"""
struct BoxLayout <: Alignable
    parent::GridLayout
    width::Union{Nothing, Node{Float32}}
    height::Union{Nothing, Node{Float32}}
    halign::Union{Nothing, Node{Float32}}
    valign::Union{Nothing, Node{Float32}}
    bboxnode::Node{BBox}
    needs_update::Node{Bool}
end

function BoxLayout(parent, width::Node{Float32}, height::Node{Float32},
        halign::Node{Float32}, valign::Node{Float32}, bboxnode::Node{BBox})

    needs_update = Node(false)

    onany(width, height, halign, valign) do w, h, ha, va
        needs_update[] = true
    end

    BoxLayout(parent, width, height, halign, valign, bboxnode, needs_update)
end

function BoxLayout(parent, width::Nothing, height::Node{Float32}, valign::Node{Float32}, bboxnode::Node{BBox})
    needs_update = Node(false)

    onany(height, valign) do h, va
        needs_update[] = true
    end

    BoxLayout(parent, width, height, nothing, valign, bboxnode, needs_update)
end

function BoxLayout(parent, width::Node{Float32}, height::Nothing, halign::Node{Float32}, bboxnode::Node{BBox})
    needs_update = Node(false)

    onany(width, halign) do w, ha
        needs_update[] = true
    end

    BoxLayout(parent, width, height, halign, nothing, bboxnode, needs_update)
end

function determineheight(b::BoxLayout)
    if isnothing(b.height)
        nothing
    else
        b.height[]
    end
end
function determinewidth(b::BoxLayout)
    if isnothing(b.width)
        nothing
    else
        b.width[]
    end
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

protrusion(b::BoxLayout, side::Side) = 0.0
# protrusion(u::AxisLayout, side::Side) = u.protrusions[side]
protrusion(a::AxisLayout, ::Left) = a.protrusions[][1]
protrusion(a::AxisLayout, ::Right) = a.protrusions[][2]
protrusion(a::AxisLayout, ::Top) = a.protrusions[][3]
protrusion(a::AxisLayout, ::Bottom) = a.protrusions[][4]
protrusion(sp::SpannedAlignable, side::Side) = protrusion(sp.al, side)

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

protrusion(s::SolvedAxisLayout, ::Left) = left(s.inner) - left(s.outer)
function protrusion(s::SolvedAxisLayout, side::Side)
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
    sumcolgaps = sum(colgaps)
    sumrowgaps = sum(rowgaps)

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
    spaceforcolumns = remaininghorizontalspace - sum(addedcolgaps)
    spaceforrows = remainingverticalspace - sum(addedrowgaps)

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
        solved = solve(c.al, bbox_cell)
        return SpannedAlignable(solved, c.sp)
    end
    # return a solved grid layout in which all objects are also solved layout objects
    return SolvedGridLayout(
        bbox, solvedcontent,
        gl.nrows, gl.ncols,
        gridboxes
    )
end

function determineheight(a::Alignable)
    nothing
end
function determinewidth(a::Alignable)
    nothing
end

function determinecolsize(icol, gl)
    colsize = nothing
    for c in gl.content
        # content has to be single span to be determinable
        if c.sp.cols.start == icol && c.sp.cols.stop == icol
            w = determinewidth(c.al)
            if !isnothing(w)
                colsize = isnothing(colsize) ? w : max(colsize, w)
            end
        end
    end
    colsize
end

function determinerowsize(row, gl)
    rowsize = nothing
    for c in gl.content
        # content has to be single span to be determinable
        if c.sp.rows.start == row && c.sp.rows.stop == row
            h = determineheight(c.al)
            if !isnothing(h)
                rowsize = isnothing(rowsize) ? h : max(rowsize, h)
            end
        end
    end
    rowsize
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
        (i, determinecolsize(i, gl))
    end
    det_acsizes = filter(tup -> !isnothing(tup[2]), determined_acsizes)
    nondets_c = filter(tup -> isnothing(tup[2]), determined_acsizes)
    nondet_acsizes = map(nondets_c) do (i, noth)
        i, gl.colsizes[i]
    end

    determined_arsizes = map(arsizes) do (i, c)
        (i, determinerowsize(i, gl))
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
            c.x
        end
        map(nondet_acsizes) do (i, c)
            colwidths[i] = remaining * c.x / sumratios
        end
    end
    if !isempty(nondet_arsizes)
        remaining = spaceforrows - sum(rowheights)
        sumratios = sum(nondet_arsizes) do (i, r)
            r.x
        end
        map(nondet_arsizes) do (i, r)
            rowheights[i] = remaining * r.x / sumratios
        end
    end

    colwidths, rowheights
end


function solve(ua::AxisLayout, innerbbox)
    # bbox = mapsides(innerbbox, ua.protrusions) do side, iside, decside
    #     op = side isa Union{Left, Top} ? (-) : (+)
    #     return op(iside, decside)
    # end
    ib = innerbbox
    bbox = BBox(
        left(ib) - ua.protrusions[][1],
        right(ib) + ua.protrusions[][2],
        top(ib) + ua.protrusions[][3],
        bottom(ib) - ua.protrusions[][4]
    )
    SolvedAxisLayout(innerbbox, ua.bboxnode)
end

const Indexables = Union{UnitRange, Int, Colon}

"""
This function allows indexing syntax to add a layout object to a grid.
You can do:

grid[1, 1] = obj
grid[1, :] = obj
grid[1:3, 2:5] = obj

and all combinations of the above
"""
function Base.setindex!(g::GridLayout, a::Alignable, rows::Indexables, cols::Indexables)
    rows, cols = adjust_rows_cols!(g, rows, cols)

    sp = SpannedAlignable(a, Span(rows, cols))
    connectchildlayout!(g, sp)
end

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

function Base.setindex!(g::GridLayout, la::LayoutedAxis, rows::Indexables, cols::Indexables)
    al = AxisLayout(g, la.protrusions, la.bboxnode)
    g[rows, cols] = al
    la
end

function Base.setindex!(g::GridLayout, lc::LayoutedColorbar, rows::Indexables, cols::Indexables)
    al = AxisLayout(g, lc.protrusions, lc.bboxnode)
    g[rows, cols] = al
    lc
end

function Base.setindex!(g::GridLayout, gsub::GridLayout, rows::Indexables, cols::Indexables)
    # avoid stackoverflow error
    # g[rows, cols] = gsub

    rows, cols = adjust_rows_cols!(g, rows, cols)

    gsub.parent = g
    setup_updates!(gsub)
    sp = SpannedAlignable(gsub, Span(rows, cols))
    connectchildlayout!(g, sp)

    gsub
end

function Base.setindex!(g::GridLayout, ls::LayoutedSlider, rows::Indexables, cols::Indexables)
    fh = BoxLayout(g, nothing, ls.height, Node(0.5f0), ls.bboxnode)
    g[rows, cols] = fh
    ls
end

function Base.setindex!(g::GridLayout, lb::LayoutedButton, rows::Indexables, cols::Indexables)
    b = BoxLayout(g, lb.width, lb.height, Node(0.5f0), Node(0.5f0), lb.bboxnode)
    g[rows, cols] = b
    lb
end

function connectchildlayout!(g::GridLayout, spa::SpannedAlignable)
    push!(g.content, spa)
    on(spa.al.needs_update) do update
        g.needs_update[] = true
    end
    # trigger relayout
    g.needs_update[] = true
end

function solve(b::BoxLayout, bbox::BBox)

    fbh = if isnothing(b.height)
        # the height is not fixed and therefore takes the bbox value
        height(bbox)
    else
        b.height[]
    end

    fbw = if isnothing(b.width)
        # the width is not fixed and therefore takes the bbox value
        width(bbox)
    else
        b.width[]
    end

    oxb = bbox.origin[1]
    oyb = bbox.origin[2]


    bh = height(bbox)
    bw = width(bbox)

    restx = bw - fbw
    resty = bh - fbh

    xal = isnothing(b.halign) ? 0f0 : b.halign[]
    yal = isnothing(b.valign) ? 0f0 : b.valign[]

    oxinner = oxb + xal * restx
    oyinner = oyb + yal * resty

    SolvedBoxLayout(BBox(oxinner, oxinner + fbw, oyinner + fbh, oyinner), b.bboxnode)
end

# function Base.convert(::Vector{ContentSize}, vec::Vector{T}) where T <: ContentSize
#     ContentSize[v for v in vec]
# end
#
# function Base.convert(::Vector{GapSize}, vec::Vector{T}) where T <: GapSize
#     GapSize[v for v in vec]
# end

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
        SpannedAlignable(spal.al, newspan)
    end

    with_updates_suspended(gl) do
        gl.nrows += n
        append!(gl.rowsizes, rowsizes)
        append!(gl.addedrowgaps, addedrowgaps)
    end
end

function prependcols!(gl::GridLayout, n::Int; colsizes=nothing, addedcolgaps=nothing)

    colsizes = convert_contentsizes(n, colsizes)
    addedcolgaps = convert_gapsizes(n, addedcolgaps)

    gl.content = map(gl.content) do spal
        span = spal.sp
        newspan = Span(span.rows, span.cols .+ n)
        SpannedAlignable(spal.al, newspan)
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
