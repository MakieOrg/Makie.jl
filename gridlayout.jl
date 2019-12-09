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

function detach_parent!(gl::GridLayout)
    detach_parent!(gl, gl.parent)
    nothing
end

function detach_parent!(gl::GridLayout, parent::Scene)
    if isnothing(gl._update_func_handle)
        error("Trying to detach a Scene parent, but there is no update_func_handle. This must be a bug.")
    end
    Observables.off(pixelarea(parent), gl._update_func_handle)
    gl._update_func_handle = nothing
    gl.parent = nothing
    nothing
end

function detach_parent!(gl::GridLayout, parent::Node{<:Rect2D})
    if isnothing(gl._update_func_handle)
        error("Trying to detach a Rect Node parent, but there is no update_func_handle. This must be a bug.")
    end
    Observables.off(parent, gl._update_func_handle)
    gl._update_func_handle = nothing
    gl.parent = nothing
    nothing
end

function detach_parent!(gl::GridLayout, parent::GridLayout)
    if !isnothing(gl._update_func_handle)
        error("Trying to detach a GridLayout parent, but there is an update_func_handle. This must be a bug.")
    end
    gl.parent = nothing
    nothing
end

function detach_parent!(gl::GridLayout, parent::Nothing)
    if !isnothing(gl._update_func_handle)
        error("Trying to detach a Nothing parent, but there is an update_func_handle. This must be a bug.")
    end
    nothing
end

function attach_parent!(gl::GridLayout, parent::Scene)
    detach_parent!(gl)
    gl._update_func_handle = on(pixelarea(parent)) do px
        request_update(gl)
    end
    gl.parent = parent
    nothing
end

function attach_parent!(gl::GridLayout, parent::Nothing)
    detach_parent!(gl)
    gl.parent = parent
    nothing
end

function attach_parent!(gl::GridLayout, parent::GridLayout)
    detach_parent!(gl)
    gl.parent = parent
    nothing
end

function attach_parent!(gl::GridLayout, parent::Node{<:Rect2D})
    detach_parent!(gl)
    gl._update_func_handle = on(parent) do rect
        request_update(gl)
    end
    gl.parent = parent
    nothing
end

function request_update(gl::GridLayout)
    if !gl.block_updates
        request_update(gl, gl.parent)
    end
end

function request_update(gl::GridLayout, parent::Nothing)
    error("The GridLayout has no parent and therefore can't request an update.")
end

function request_update(gl::GridLayout, parent::Scene)
    sg = solve(gl, BBox(pixelarea(parent)[]))
    applylayout(sg)
end

function request_update(gl::GridLayout, parent::Node{<:Rect2D})
    sg = solve(gl, BBox(parent[]))
    applylayout(sg)
end

function request_update(gl::GridLayout, parent::GridLayout)
    parent.needs_update[] = true
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
        SpannedLayout(spal.al, newspan, spal.side)
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
        SpannedLayout(spal.al, newspan, spal.side)
    end

    with_updates_suspended(gl) do
        gl.ncols += n
        prepend!(gl.colsizes, colsizes)
        prepend!(gl.addedcolgaps, addedcolgaps)
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
        spal = gl.content[i]

        if (spal.sp.rows.start >= newrows.start && spal.sp.rows.stop <= newrows.stop &&
            spal.sp.cols.start >= newcols.start && spal.sp.cols.stop <= newcols.stop)

            detachfromparent!(spal.al) # this deletes the alignable from its old parent already
            # which would happen anyway hidden in the next assignment, but makes the intent clearer
            subgl[spal.sp.rows .- (newrows.start - 1), spal.sp.cols .- (newcols.start - 1)] = spal.al
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
        # for non layout objects like LAxis we check if they are inside
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

function Base.show(io::IO, gl::GridLayout)

    println(io, "GridLayout[$(gl.nrows), $(gl.ncols)] with $(length(gl.content)) children")
    for (i, c) in enumerate(gl.content)
        rows = c.sp.rows
        cols = c.sp.cols
        al = c.al
        if i == 1
            println(io, " ┗━┳━ [$rows | $cols] $(typeof(al))")
        elseif i == length(gl.content)
            println(io, "   ┗━ [$rows | $cols] $(typeof(al))")
        else
            println(io, "   ┣━ [$rows | $cols] $(typeof(al))")
        end
    end

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
