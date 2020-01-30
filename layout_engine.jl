"""
    side_indices(c::GridContent)::RowCols{Int}

Indices of the rows / cols for each side
"""
function side_indices(c::GridContent)
    return RowCols(
        c.span.cols.start,
        c.span.cols.stop,
        c.span.rows.start,
        c.span.rows.stop,
    )
end

# These functions tell whether an object in a grid touches the left, top, etc. border
# of the grid. This means that it is relevant for the grid's own protrusion on that side.
ismostin(gc::GridContent, grid, ::Left) = gc.span.cols.start == 1
ismostin(gc::GridContent, grid, ::Right) = gc.span.cols.stop == grid.ncols
ismostin(gc::GridContent, grid, ::Bottom) = gc.span.rows.stop == grid.nrows
ismostin(gc::GridContent, grid, ::Top) = gc.span.rows.start == 1

isleftmostin(gc::GridContent, grid) = ismostin(gc, grid, Left())
isrightmostin(gc::GridContent, grid) = ismostin(gc, grid, Right())
isbottommostin(gc::GridContent, grid) = ismostin(gc, grid, Bottom())
istopmostin(gc::GridContent, grid) = ismostin(gc, grid, Top())

function protrusionnode(x::T) where T
    error("protrusionnode() is not defined for type $T, if you want to include
        such an object in a grid layout, you need to create a method for your
        type that returns a Node{RectSides{Float32}}. If your object has no
        protrusions, the values of RectSides can just all be 0f0.")
end

function protrusion(x::T, side::Side) where T
    protrusions = protrusionnode(x)
    @match side begin
        si::Left => protrusions[].left
        si::Right => protrusions[].right
        si::Bottom => protrusions[].bottom
        si::Top => protrusions[].top
        si => error("Can't get a protrusion value for side $(typeof(si)), only
            Left, Right, Bottom, or Top.")
    end
end

function protrusion(gc::GridContent, side::Side)
    prot = @match gc.side begin
        gcside::Inner => protrusion(gc.content, side)
        # gcside::Outer => BBox(l - pl, r + pr, b - pb, t + pt)
        gcside::Union{Left, Right} => @match side begin
            si::typeof(gcside) => determinedirsize(gc.content, Col(), gc.side)
            si => 0.0
        end
        gcside::Union{Top, Bottom} => @match side begin
            si::typeof(gcside) => determinedirsize(gc.content, Row(), gc.side)
            si => 0.0
        end
        gcside::TopLeft => @match side begin
            si::Top => determinedirsize(gc.content, Row(), gc.side)
            si::Left => determinedirsize(gc.content, Col(), gc.side)
            si => 0.0
        end
        gcside::TopRight => @match side begin
            si::Top => determinedirsize(gc.content, Row(), gc.side)
            si::Right => determinedirsize(gc.content, Col(), gc.side)
            si => 0.0
        end
        gcside::BottomLeft => @match side begin
            si::Bottom => determinedirsize(gc.content, Row(), gc.side)
            si::Left => determinedirsize(gc.content, Col(), gc.side)
            si => 0.0
        end
        gcside::BottomRight => @match side begin
            si::Bottom => determinedirsize(gc.content, Row(), gc.side)
            si::Right => determinedirsize(gc.content, Col(), gc.side)
            si => 0.0
        end
        gcside => error("Invalid side $gcside")
    end
    ifnothing(prot, 0.0)
end

getside(m::Mixed, ::Left) = m.padding.left
getside(m::Mixed, ::Right) = m.padding.right
getside(m::Mixed, ::Top) = m.padding.top
getside(m::Mixed, ::Bottom) = m.padding.bottom

function inside_protrusion(gl::GridLayout, side::Side)
    prot = 0.0
    for elem in gl.content
        if ismostin(elem, gl, side)
            # take the max protrusion of all elements that are sticking
            # out at this side
            prot = max(protrusion(elem, side), prot)
        end
    end
    return prot
end

function protrusion(gl::GridLayout, side::Side)
    # when we align with the outside there is by definition no protrusion
    if gl.alignmode isa Outside
        return 0.0
    elseif gl.alignmode isa Inside
        inside_protrusion(gl, side)
    elseif gl.alignmode isa Mixed
        if isnothing(getside(gl.alignmode, side))
            inside_protrusion(gl, side)
        else
            # Outside alignment
            0.0
        end
    else
        error("Unknown AlignMode of type $(typeof(gl.alignmode))")
    end
end

function bbox_for_solving_from_side(maxgrid::RowCols, bbox_cell::BBox, idx_rect::RowCols, side::Side)
    pl = maxgrid.lefts[idx_rect.lefts]
    pr = maxgrid.rights[idx_rect.rights]
    pt = maxgrid.tops[idx_rect.tops]
    pb = maxgrid.bottoms[idx_rect.bottoms]

    l = left(bbox_cell)
    r = right(bbox_cell)
    b = bottom(bbox_cell)
    t = top(bbox_cell)

    @match side begin
        s::Inner => bbox_cell
        s::Outer => BBox(l - pl, r + pr, b - pb, t + pt)
        s::Left => BBox(l - pl, l, b, t)
        s::Top => BBox(l, r, t, t + pt)
        s::Right => BBox(r, r + pr, b, t)
        s::Bottom => BBox(l, r, b - pb, b)
        s::TopLeft => BBox(l - pl, l, t, t + pt)
        s::TopRight => BBox(r, r + pr, t, t + pt)
        s::BottomRight => BBox(r, r + pr, b - pb, b)
        s::BottomLeft => BBox(l - pl, l, b - pb, b)
        s => error("Invalid side $s")
    end
end

startside(c::Col) = Left()
stopside(c::Col) = Right()
startside(r::Row) = Top()
stopside(r::Row) = Bottom()


getspan(gc::GridContent, dir::Col) = gc.span.cols
getspan(gc::GridContent, dir::Row) = gc.span.rows



"""
Determine the size of a protrusion layout along a dimension. This size is dependent
on the `Side` at which the layout is placed in its parent grid. An `Inside` side
means that the protrusion layout reports its width but not its protrusions. `Left`
means that the layout reports only its full width but not its height, because
an element placed in the left protrusion loses its ability to influence height.
"""
function determinedirsize(content, gdir::GridDir, side::Side)
    computedsize = computedsizenode(content)
    if gdir isa Row
        @match side begin
            # TODO: is computedsize the correct thing to return? or plus protrusions depending on the side
            si::Union{Inner, Top, Bottom, TopLeft, TopRight, BottomLeft, BottomRight} =>
                ifnothing(computedsize[][2], nothing)
            si::Union{Left, Right} => nothing
            si => error("$side not implemented")
        end
    else
        @match side begin
            si::Union{Inner, Left, Right, TopLeft, TopRight, BottomLeft, BottomRight} =>
                ifnothing(computedsize[][1], nothing)
            si::Union{Top, Bottom} => nothing
            si => error("$side not implemented")
        end
    end
end

function to_ranges(g::GridLayout, rows::Indexables, cols::Indexables)
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
    rows, cols
end

function adjust_rows_cols!(g::GridLayout, rows, cols)
    rows, cols = to_ranges(g, rows, cols)

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
