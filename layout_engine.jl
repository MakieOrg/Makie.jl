
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

struct SolvedAxisLayout <: Alignable
    inner::BBox
    outer::BBox
    axis::LayoutedAxis
end

struct AxisLayout <: Alignable
    decorations::BBox
    axis::LayoutedAxis
end

struct SolvedGridLayout <: Alignable
    bbox::BBox
    content::Vector{SpannedAlignable}
    nrows::Int
    ncols::Int
    grid::RowCols{Vector{Float64}}
end

abstract type AlignMode end

struct Inside <: AlignMode end
struct Outside <: AlignMode end

struct Auto end
struct Fixed
    x::Float64
end
struct Relative
    x::Float64
end
struct Ratio
    x::Float64
end
struct Aspect
    index::Int
    ratio::Float64
end
const ContentSize = Union{Auto, Fixed, Relative, Ratio, Aspect}
const GapSize = Union{Fixed, Relative}

struct GridLayout <: Alignable
    content::Vector{SpannedAlignable}
    nrows::Int
    ncols::Int
    rowsizes::Vector{ContentSize}
    colsizes::Vector{ContentSize}
    addedrowgaps::Vector{GapSize}
    addedcolgaps::Vector{GapSize}
    alignmode::AlignMode
    equalprotrusiongaps::Tuple{Bool, Bool}
end

struct SolvedFixedSizeBox{T} <: Alignable
    inner::BBox
    outer::BBox
    content::T
end

"""
An alignable that contains something of a fixed size, like some text.
There will usually be more space available in at least one direction than
just the fixed size of the box, so the alignment says where
in the available BBox the fixed size content should be placed.
For example, the figure title is placed above all else, but can then
be aligned on the left, in the center, or on the right.
"""
struct FixedSizeBox{T} <: Alignable
    bbox::BBox
    alignment::Tuple{Float64, Float64}
    content::T
end

height(fb::FixedSizeBox) = height(fb.bbox)
width(fb::FixedSizeBox) = width(fb.bbox)


"""
All the protrusion functions calculate how much stuff "sticks out" of a layoutable object.
This is so that collisions are avoided, while what is actually aligned is the
"important" edges of the layout objects.
"""
leftprotrusion(x) = protrusion(x, Left())
rightprotrusion(x) = protrusion(x, Right())
bottomprotrusion(x) = protrusion(x, Bottom())
topprotrusion(x) = protrusion(x, Top())

protrusion(fb::FixedSizeBox, side::Side) = 0.0
protrusion(u::AxisLayout, side::Side) = u.decorations[side]
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
        end
    end
    addedrowgaps = map(gl.addedrowgaps) do rg
        if rg isa Fixed
            return rg.x
        elseif rg isa Relative
            return rg.x * remainingverticalspace
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

function height(a::Alignable)
    nothing
end
function width(a::Alignable)
    nothing
end

function determinecolsize(icol, gl)
    colsize = nothing
    for c in gl.content
        # content has to be single span to be determinable
        if c.sp.cols.start == icol && c.sp.cols.stop == icol
            w = width(c.al)
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
            h = height(c.al)
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

    # rows / cols with Ratio size get the ratio fraction of the space available
    # after the fixed and relative sizes are subtracted
    # there can be no ratio sizes together with auto sizes that are not determinable

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

    ratcsizes = filter(filtersize(Ratio), icsizes)
    ratrsizes = filter(filtersize(Ratio), irsizes)

    acsizes = filter(filtersize(Auto), icsizes)
    arsizes = filter(filtersize(Auto), irsizes)

    aspcsizes = filter(filtersize(Aspect), icsizes)
    asprsizes = filter(filtersize(Aspect), irsizes)

    determined_acsizes = map(acsizes) do (i, c)
        (i, determinecolsize(i, gl))
    end
    det_acsizes = filter(tup -> !isnothing(tup[2]), determined_acsizes)
    nondet_acsizes = filter(tup -> isnothing(tup[2]), determined_acsizes)
    length(nondet_acsizes) > 1 && error("More than one column with auto size is undeterminable $(map(x->x[1], nondet_acsizes)).")
    length(nondet_acsizes) == 1 && length(ratcsizes) >= 1 && error("There is one auto sized column but also ratio sized columns, those don't work together.")

    determined_arsizes = map(arsizes) do (i, c)
        (i, determinerowsize(i, gl))
    end
    det_arsizes = filter(tup -> !isnothing(tup[2]), determined_arsizes)
    nondet_arsizes = filter(tup -> isnothing(tup[2]), determined_arsizes)
    length(nondet_arsizes) > 1 && error("More than one row with auto size is undeterminable $(map(x->x[1], nondet_arsizes)).")
    length(nondet_arsizes) == 1 && length(ratrsizes) >= 1 && error("There is one auto sized row but also ratio sized rows, those don't work together.")

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
                if !isempty(nondet_arsizes) && nondet_arsizes[1][1] == index
                    error("Can't use aspect ratio with an undeterminable Auto size")
                end
            end
            rowheights[index]
        else
            error("Aspect size can only work in conjunction with Fixed, Relative, or Auto, not $(typeof(gl.rowsizes[index]))")
        end
        colwidths[i] = rowheight * ratio
    end

    map(asprsizes) do (i, asp)
        index = asp.index
        ratio = asp.ratio
        colsize = gl.colsizes[index]
        colwidth = if colsize isa Union{Fixed, Relative, Auto}
            if colsize isa Auto
                if !isempty(nondet_acsizes) && nondet_acsizes[1][1] == index
                    error("Can't use aspect ratio with an undeterminable Auto size")
                end
            end
            colwidths[index]
        else
            error("Aspect size can only work in conjunction with Fixed, Relative, or Auto, not $(typeof(gl.rowsizes[index]))")
        end
        rowheights[i] = colwidth * ratio
    end

    # next ratios
    if length(ratcsizes) > 0
        remaining = spaceforcolumns - sum(colwidths)
        sumratios = sum(map(x -> x[2].x, ratcsizes))
        map(ratcsizes) do (i, s)
            colwidths[i] = s.x / sumratios * remaining
        end
    end
    if length(ratrsizes) > 0
        remaining = spaceforrows - sum(rowheights)
        sumratios = sum(map(x -> x[2].x, ratrsizes))
        map(ratrsizes) do (i, s)
            rowheights[i] = s.x / sumratios * remaining
        end
    end

    # next undeterminable auto sizes
    if !isempty(nondet_acsizes)
        remaining = spaceforcolumns - sum(colwidths)
        colwidths[nondet_acsizes[1][1]] = remaining
    end
    if !isempty(nondet_arsizes)
        remaining = spaceforrows - sum(rowheights)
        rowheights[nondet_arsizes[1][1]] = remaining
    end

    colwidths, rowheights
end


function solve(ua::AxisLayout, innerbbox)
    bbox = mapsides(innerbbox, ua.decorations) do side, iside, decside
        op = side isa Union{Left, Top} ? (-) : (+)
        return op(iside, decside)
    end
    SolvedAxisLayout(innerbbox, bbox, ua.axis)
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
function Base.setindex!(g, a::Alignable, rows::Indexables, cols::Indexables)
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

    if !((1 <= rows.start <= g.nrows) || (1 <= rows.stop <= g.nrows))
        error("invalid row span $rows for grid with $(g.nrows) rows")
    end
    if !((1 <= cols.start <= g.ncols) || (1 <= cols.stop <= g.ncols))
        error("invalid col span $cols for grid with $(g.ncols) columns")
    end

    push!(g.content, SpannedAlignable(a, Span(rows, cols)))
end

function solve(fb::FixedSizeBox, bbox::BBox)
    fbh = height(fb.bbox)
    fbw = width(fb.bbox)

    bh = height(bbox)
    bw = width(bbox)

    oxb = bbox.origin[1]
    oyb = bbox.origin[2]

    restx = bw - fbw
    resty = bh - fbh

    xal = fb.alignment[1]
    yal = fb.alignment[2]

    oxinner = oxb + xal * restx
    oyinner = oyb + yal * resty

    SolvedFixedSizeBox(BBox(oxinner, oxinner + fbw, oyinner + fbh, oyinner), bbox, fb.content)
end
