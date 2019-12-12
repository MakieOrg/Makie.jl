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
ismostin(sp::SpannedLayout, grid, ::Top) = sp.sp.rows.start == 1

isleftmostin(sp::SpannedLayout, grid) = ismostin(sp, grid, Left())
isrightmostin(sp::SpannedLayout, grid) = ismostin(sp, grid, Right())
isbottommostin(sp::SpannedLayout, grid) = ismostin(sp, grid, Bottom())
istopmostin(sp::SpannedLayout, grid) = ismostin(sp, grid, Top())

parentlayout(pl::ProtrusionLayout) = pl.parent

function ProtrusionLayout(content)
    needs_update = Node(false)

    protrusions = protrusionnode(content)
    csize = computedsizenode(content)

    # the nothing parent here has to be replaced by a grid parent later
    # when placing this layout in the grid layout
    pl = ProtrusionLayout(nothing, protrusions, csize, needs_update, content)

    update_func = x -> begin
        p = parentlayout(pl)
        if isnothing(p)
            error("This layout has no parent and can't continue the update signal chain.")
        end
        p.needs_update[] = true
    end

    on(update_func, protrusions)
    on(update_func, csize)

    pl
end

protrusionnode(pl::ProtrusionLayout) = pl.protrusions
computedsizenode(pl::ProtrusionLayout) = pl.computedsize


"""
All the protrusion functions calculate how much stuff "sticks out" of a layoutable object.
This is so that collisions are avoided, while what is actually aligned is the
"important" edges of the layout objects.
"""
leftprotrusion(x) = protrusion(x, Left())
rightprotrusion(x) = protrusion(x, Right())
bottomprotrusion(x) = protrusion(x, Bottom())
topprotrusion(x) = protrusion(x, Top())

protrusion(a::ProtrusionLayout, ::Left) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[].left
protrusion(a::ProtrusionLayout, ::Right) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[].right
protrusion(a::ProtrusionLayout, ::Top) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[].top
protrusion(a::ProtrusionLayout, ::Bottom) = isnothing(a.protrusions[]) ? 0f0 : a.protrusions[].bottom

function protrusion(sp::SpannedLayout, side::Side)
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

protrusion(s::SolvedProtrusionLayout, ::Left) = left(s.inner) - left(s.outer)
function protrusion(s::SolvedProtrusionLayout, side::Side)
    return s.outer[side] - s.inner[side]
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


span(sp::SpannedLayout, dir::Col) = sp.sp.cols
span(sp::SpannedLayout, dir::Row) = sp.sp.rows



"""
Determine the size of a protrusion layout along a dimension. This size is dependent
on the `Side` at which the layout is placed in its parent grid. An `Inside` side
means that the protrusion layout reports its width but not its protrusions. `Left`
means that the layout reports only its full width but not its height, because
an element placed in the left protrusion loses its ability to influence height.
"""
function determinedirsize(pl::ProtrusionLayout, gdir::GridDir, side::Side)
    computedsize = computedsizenode(pl)
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


function solve(ua::ProtrusionLayout, innerbbox)
    ib = innerbbox
    bbox = BBox(
        left(ib) - protrusion(ua, Left()),
        right(ib) + protrusion(ua, Right()),
        bottom(ib) - protrusion(ua, Bottom()),
        top(ib) + protrusion(ua, Top()))
    SolvedProtrusionLayout(innerbbox, ua.content)
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


"""
This function allows indexing syntax to add a layout object to a grid.
You can do:

grid[1, 1] = obj
grid[1, :] = obj
grid[1:3, 2:5] = obj

and all combinations of the above
"""
function Base.setindex!(g::GridLayout, a::AbstractLayout, rows::Indexables, cols::Indexables, side::Side = Inner())
    detachfromparent!(a)
    add_layout!(g, a, rows, cols, side)
    a
end

"""
This function is similar to the other setindex! but is for all objects that are
not themselves layouts. They need to be wrapped in a layout first before being
added. This is determined by the defaultlayout function.
"""
function Base.setindex!(g::GridLayout, content, rows::Indexables, cols::Indexables, side::Side = Inner())

    # check if this content already sits somewhere in the grid layout tree
    # if yes, remove it from there before attaching it here
    parentlayout, index = find_in_grid_tree(content, g)
    if !isnothing(parentlayout) && !isnothing(index)
        deleteat!(parentlayout.content, index)
    end

    layout = ProtrusionLayout(content)
    add_layout!(g, layout, rows, cols, side)
    content
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

function add_layout!(g::GridLayout, layout::AbstractLayout, rows, cols, side::Side)
    rows, cols = adjust_rows_cols!(g, rows, cols)
    layout.parent = g
    sp = SpannedLayout(layout, Span(rows, cols), side)
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

function is_range_within(inner::UnitRange, outer::UnitRange)
    inner.start >= outer.start && inner.stop <= outer.stop
end

function Base.getindex(g::GridLayout, rows::Indexables, cols::Indexables)

    rows, cols = to_ranges(g, rows, cols)

    included = filter(g.content) do c
        is_range_within(c.sp.rows, rows) && is_range_within(c.sp.cols, cols)
    end

    extracted_layouts = map(included) do c
        c.al
    end

    return if length(extracted_layouts) == 0
        nothing
    elseif length(extracted_layouts) == 1
        extracted_layouts[1]
    else
        extracted_layouts
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
