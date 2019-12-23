"""
    side_indices(c::GridContent)::RowCols{Int}

Indices of the rows / cols for each side
"""
function side_indices(c::GridContent)
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
ismostin(sp::GridContent, grid, ::Left) = sp.sp.cols.start == 1
ismostin(sp::GridContent, grid, ::Right) = sp.sp.cols.stop == grid.ncols
ismostin(sp::GridContent, grid, ::Bottom) = sp.sp.rows.stop == grid.nrows
ismostin(sp::GridContent, grid, ::Top) = sp.sp.rows.start == 1

isleftmostin(sp::GridContent, grid) = ismostin(sp, grid, Left())
isrightmostin(sp::GridContent, grid) = ismostin(sp, grid, Right())
isbottommostin(sp::GridContent, grid) = ismostin(sp, grid, Bottom())
istopmostin(sp::GridContent, grid) = ismostin(sp, grid, Top())

# parentlayout(pl::ProtrusionLayout) = pl.parent
#
# function ProtrusionLayout(content)
#     needs_update = Node(false)
#
#     protrusions = protrusionnode(content)
#     csize = computedsizenode(content)
#
#     # the nothing parent here has to be replaced by a grid parent later
#     # when placing this layout in the grid layout
#     pl = ProtrusionLayout(nothing, protrusions, csize, needs_update, content)
#
#     update_func = x -> begin
#         p = parentlayout(pl)
#         if isnothing(p)
#             error("This layout has no parent and can't continue the update signal chain.")
#         end
#         p.needs_update[] = true
#     end
#
#     on(update_func, protrusions)
#     on(update_func, csize)
#
#     pl
# end

# protrusionnode(pl::ProtrusionLayout) = pl.protrusions
# computedsizenode(pl::ProtrusionLayout) = pl.computedsize


# """
# All the protrusion functions calculate how much stuff "sticks out" of a layoutable object.
# This is so that collisions are avoided, while what is actually aligned is the
# "important" edges of the layout objects.
# """
# leftprotrusion(x) = protrusion(x, Left())
# rightprotrusion(x) = protrusion(x, Right())
# bottomprotrusion(x) = protrusion(x, Bottom())
# topprotrusion(x) = protrusion(x, Top())

# protrusion(a::ProtrusionLayout, ::Left) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[].left
# protrusion(a::ProtrusionLayout, ::Right) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[].right
# protrusion(a::ProtrusionLayout, ::Top) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[].top
# protrusion(a::ProtrusionLayout, ::Bottom) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[].bottom

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

function protrusion(sp::GridContent, side::Side)
    prot = @match sp.side begin
        sps::Inner => protrusion(sp.al, side)
        # sps::Outer => BBox(l - pl, r + pr, b - pb, t + pt)
        sps::Union{Left, Right} => @match side begin
            si::typeof(sps) => determinedirsize(sp.al, Col(), sp.side)
            si => 0.0
        end
        sps::Union{Top, Bottom} => @match side begin
            si::typeof(sps) => determinedirsize(sp.al, Row(), sp.side)
            si => 0.0
        end
        sps::TopLeft => @match side begin
            si::Top => determinedirsize(sp.al, Row(), sp.side)
            si::Left => determinedirsize(sp.al, Col(), sp.side)
            si => 0.0
        end
        sps::TopRight => @match side begin
            si::Top => determinedirsize(sp.al, Row(), sp.side)
            si::Right => determinedirsize(sp.al, Col(), sp.side)
            si => 0.0
        end
        sps::BottomLeft => @match side begin
            si::Bottom => determinedirsize(sp.al, Row(), sp.side)
            si::Left => determinedirsize(sp.al, Col(), sp.side)
            si => 0.0
        end
        sps::BottomRight => @match side begin
            si::Bottom => determinedirsize(sp.al, Row(), sp.side)
            si::Right => determinedirsize(sp.al, Col(), sp.side)
            si => 0.0
        end
        sps => error("Invalid side $sps")
    end
    ifnothing(prot, 0.0)
end

function protrusion(gl::GridLayout, side::Side)
    # when we align with the outside there is by definition no protrusion
    if gl.alignmode isa Outside
        return 0.0
    elseif gl.alignmode isa Inside
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
end

# protrusion(s::SolvedProtrusionLayout, ::Left) = left(s.inner) - left(s.outer)
# function protrusion(s::SolvedProtrusionLayout, side::Side)
#     return s.outer[side] - s.inner[side]
# end

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


span(sp::GridContent, dir::Col) = sp.sp.cols
span(sp::GridContent, dir::Row) = sp.sp.rows



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


# function solve(ua::ProtrusionLayout, innerbbox)
#     ib = innerbbox
#     bbox = BBox(
#         left(ib) - protrusion(ua, Left()),
#         right(ib) + protrusion(ua, Right()),
#         bottom(ib) - protrusion(ua, Bottom()),
#         top(ib) + protrusion(ua, Top()))
#     SolvedProtrusionLayout(innerbbox, ua.content)
# end

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
