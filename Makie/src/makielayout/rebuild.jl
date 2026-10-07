################################################################################
### Rebuilding a subfigure's content without rebuilding its blocks
################################################################################

"""
A rebuild shares one pool of controls. Explicit keys identify controls independently
of layout positions; unkeyed controls prefer their old cell, then reuse another
unclaimed control of the same type. Matching is indexed, not a pairwise search.
"""
struct RebuildLayout
    layout::GridLayout
    subfigure::Any
    cells::Dict{Tuple{Any, Any, Any, DataType}, Vector{Block}}
    types::Dict{DataType, Vector{Block}}
    keyed::Dict{Any, Block}
    available::IdDict{Block, Nothing}
    usedkeys::Set{Any}
end

struct RebuildPosition
    parent::RebuildLayout
    rows::Any
    cols::Any
    side::Any
end

Base.getindex(rl::RebuildLayout, rows, cols, side = GridLayoutBase.Inner()) =
    RebuildPosition(rl, rows, cols, side)

# `layout[3, 1]` and the span the grid remembers for that block (`3:3`) have to
# produce the same key, or nothing is found and every rebuild builds again.
tospan(i::Integer) = Int(i):Int(i)
tospan(r::UnitRange{<:Integer}) = Int(r.start):Int(r.stop)
tospan(x) = x                       # Colon and friends: no key, no reuse

cellkey(pos::RebuildPosition, ::Type{T}) where {T} =
    (tospan(pos.rows), tospan(pos.cols), pos.side, T)

# everything a closure does with the layout other than placing blocks — colgap!,
# rowsize!, nrows — goes to the real one
Base.getproperty(rl::RebuildLayout, k::Symbol) =
    k in fieldnames(RebuildLayout) ? getfield(rl, k) : getproperty(getfield(rl, :layout), k)

"""
The subfigure a [`replace_content!`](@ref) closure is handed: `.layout` yields
reusing positions, everything else is the real subfigure.
"""
struct RebuildSubfigure
    subfigure::Any
    layout::RebuildLayout
end

Base.getproperty(rs::RebuildSubfigure, k::Symbol) =
    k === :layout ? getfield(rs, :layout) :
    k === :subfigure ? getfield(rs, :subfigure) :
    getproperty(getfield(rs, :subfigure), k)

"Internal listeners, recorded before the rebuild closure attaches callbacks."
buildlisteners(block::Block) =
    Dict{Symbol, Vector{Any}}(k => collect(Any, o.listeners) for (k, o) in block.attributes.observables)

"""
Drop everything the previous closure hung on `block`, keep the wiring the block
made for itself.

A reused block is the same object, so `on(button.clicks) do …` in a closure that
runs on every rebuild would stack up one callback per rebuild. `snap` is what the
block carried when it was built; other listeners came from a closure.
"""
function reset_to_buildlisteners!(block::Block, snap::Dict{Symbol, Vector{Any}})
    for (name, obs) in block.attributes.observables
        original = get(snap, name, ())
        # Listener order follows priority, not registration order. Truncating a
        # count would retain high-priority user callbacks and remove internal ones.
        filter!(listener -> any(saved -> saved === listener, original), obs.listeners)
    end
    return block
end

"""
    reuse_arguments!(block, args...) -> Bool

Write a block's positional constructor arguments onto one that already exists,
or return `false` if this type cannot take them that way — then
[`replace_content!`](@ref) builds a fresh block instead.

There is no generic route: a block consumes its arguments in its own
`initialize_block!`, which may do more than set an attribute (`Label` accepts an
`Observable` and subscribes to it; an `Axis` builds a whole plot pipeline). So a
type opts in for the forms it can take back.
"""
reuse_arguments!(::Block, args...) = false
reuse_arguments!(l::Label, text::AbstractString) = (l.text = text; true)
reuse_arguments!(b::Button, label::AbstractString) = (b.label = label; true)

function take_rebuild_block!(rl, blocks)
    while !isempty(blocks)
        block = pop!(blocks)
        haskey(rl.available, block) || continue
        delete!(rl.available, block)
        return block
    end
    return nothing
end

function forget_rebuild_block!(sf, block)
    delete!(sf.buildlisteners, block)
    delete!(sf.buildkeys, block)
    delete_layoutable!(block)
    return nothing
end

"Reuse a keyed control anywhere in the layout, or an unkeyed control of this type."
function (::Type{T})(pos::RebuildPosition, args...; key = nothing, kwargs...) where {T <: Block}
    rl = pos.parent
    if key !== nothing
        key in rl.usedkeys && throw(ArgumentError("duplicate rebuild key: $(repr(key))"))
        push!(rl.usedkeys, key)
        block = get(rl.keyed, key, nothing)
        block === nothing || delete!(rl.available, block)
    else
        block = take_rebuild_block!(rl, get(rl.cells, cellkey(pos, T), Block[]))
        block === nothing && (block = take_rebuild_block!(rl, get(rl.types, T, Block[])))
    end
    if block !== nothing
        # Remove callbacks before applying any attributes/arguments: updates must
        # not invoke a closure belonging to the previous document or selection.
        snap = get!(() -> buildlisteners(block), rl.subfigure.buildlisteners, block)
        reset_to_buildlisteners!(block, snap)
        if block isa T && (isempty(args) || reuse_arguments!(block, args...))
            for (k, v) in kwargs
                isequal(to_value(getproperty(block, k)), v) || setproperty!(block, k, v)
            end
            if gridcontent_key(block) != cellkey(pos, T)
                rl.layout[pos.rows, pos.cols, pos.side] = block
            end
            return block
        end
        forget_rebuild_block!(rl.subfigure, block)
    end
    block = T(rl.layout[pos.rows, pos.cols, pos.side], args...; kwargs...)
    rl.subfigure.buildlisteners[block] = buildlisteners(block)
    key === nothing || (rl.subfigure.buildkeys[block] = key)
    return block
end

"The cell key a block currently sits in, or `nothing` if it is not in a layout."
function gridcontent_key(block::Block)
    gc = block.layoutobservables.gridcontent[]
    gc === nothing && return nothing
    return (tospan(gc.span.rows), tospan(gc.span.cols), gc.side, typeof(block))
end

"""
    replace_content!(f, sf::Subfigure)

Rebuild the subfigure's content by calling `f(sf)`, reusing the blocks already
there. Pass `key = id` to a block constructor to preserve that control's identity
when it moves, for example `Slider(sf.layout[row, 2]; key = (:gain, track.id))`.
Keys must be unique within a rebuild. A key whose block type changes creates a
new block. Unkeyed controls prefer the same cell, then any unused unkeyed control
of the same type; give stateful controls keys when their meaning must be retained.
Omitted attributes retain their values, including focus and uncommitted text.
Blocks the closure does not ask for are deleted,
the layout is trimmed and the content size refreshed.

The whole rebuild is one layout pass. Otherwise every deleted block and every
attribute write triggers its own pass over the grid, which is where a panel
rebuild's time goes: writing a `Label`'s text costs 1551 µs with updates live and
43 µs inside a suspended layout, against 21 µs for the `text` plot underneath.

```julia
replace_content!(sf) do sf
    for (i, name) in enumerate(names)
        b = Button(sf.layout[i, 1]; key = name, label = name)
        on(b.clicks) do _        # registered fresh on every rebuild; the previous
            select(name)         # closure's callbacks are dropped from the reused
        end                      # block first
    end
end
```
"""
function replace_content!(f, sf::Subfigure)
    layout = sf.layout
    cells = Dict{Tuple{Any, Any, Any, DataType}, Vector{Block}}()
    types = Dict{DataType, Vector{Block}}()
    keyed = Dict{Any, Block}()
    available = IdDict{Block, Nothing}()
    for c in contents(layout)
        c isa Block || continue
        available[c] = nothing
        if haskey(sf.buildkeys, c)
            keyed[sf.buildkeys[c]] = c
        else
            k = gridcontent_key(c)
            k === nothing || push!(get!(() -> Block[], cells, k), c)
            push!(get!(() -> Block[], types, typeof(c)), c)
        end
    end
    rl = RebuildLayout(layout, sf, cells, types, keyed, available, Set{Any}())
    previous = layout.block_updates
    layout.block_updates = true
    try
        f(RebuildSubfigure(sf, rl))
        for block in keys(rl.available)   # asked for last time, not this time
            forget_rebuild_block!(sf, block)
        end
        for c in contents(layout)          # …and anything that was never a Block
            c isa Block || delete_layoutable!(c)
        end
        trim!(layout)
    finally
        layout.block_updates = previous
        GridLayoutBase.update!(layout)
    end
    refresh_contentsize!(sf)
    return sf
end
