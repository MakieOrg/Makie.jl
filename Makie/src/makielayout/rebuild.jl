################################################################################
### Rebuilding a subfigure's content without rebuilding its blocks
################################################################################

"""
Rebuilding panel content by deleting every block and constructing it again is
the expensive way to change a label. Measured on 100 `Button`s: 230 ms and
118 MB to delete and rebuild, of which the construction is nearly all — a
`Button` costs 1.5 MB, and 1.03 MB of that is the `poly` and the `text` it draws
with. The block that was already there can take the new values instead.

The API stays the one people write, an imperative closure that constructs
blocks. What changes is the POSITION it constructs them at: inside
[`replace_content!`](@ref) `sf.layout[i, j]` yields a [`RebuildPosition`](@ref),
and `Button(pos; label = …)` on one of those hands back the block that was in
that cell — with the new attributes written and the previous closure's callbacks
removed — instead of building a second one.
"""

"""
The cell a block is being (re)built in, plus the pool it may be taken from.

`(rows, cols, side, T)` is the key: a form draws the same kinds of block in the
same cells every time, so position and type identify the block to reuse without
comparing anything. specapi's `distance_score` matcher answers a harder question
(match specs to blocks anywhere in the layout) and pays for it — it is quadratic
in the number of blocks, 5.7 ms for 50 and 38.4 ms for 200.
"""
struct RebuildLayout
    layout::GridLayout
    subfigure::Any                                   # `Subfigure`, holds the listener record
    pool::Dict{Tuple{Any, Any, Any, DataType}, Block}   # what is still up for reuse
    kept::Vector{Block}
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
# produce the SAME key, or nothing is ever found and every rebuild builds again.
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

"Listener counts of every observable a block has materialised, as it was built."
buildlisteners(block::Block) =
    Dict{Symbol, Int}(k => length(o.listeners) for (k, o) in block.attributes.observables)

"""
Drop everything the previous closure hung on `block`, keep the wiring the block
made for itself.

A reused block is the same object, so `on(button.clicks) do …` in a closure that
runs on every rebuild would stack up one callback per rebuild — the classic leak
of any reuse scheme. `snap` is what the block carried when it was BUILT; anything
past that came from a closure and goes.
"""
function reset_to_buildlisteners!(block::Block, snap::Dict{Symbol, Int})
    for (name, obs) in block.attributes.observables
        n = get(snap, name, 0)
        length(obs.listeners) > n && resize!(obs.listeners, n)
    end
    return block
end

"""
    reuse_arguments!(block, args...) -> Bool

Write a block's POSITIONAL constructor arguments onto one that already exists,
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

"Take the block in this cell, or build one — see [`RebuildLayout`](@ref)."
function (::Type{T})(pos::RebuildPosition, args...; kwargs...) where {T <: Block}
    rl = pos.parent
    key = cellkey(pos, T)
    block = get(rl.pool, key, nothing)
    if block !== nothing
        delete!(rl.pool, key)
        if isempty(args) || reuse_arguments!(block, args...)
            reset_to_buildlisteners!(block, get(rl.subfigure.buildlisteners, block, Dict{Symbol, Int}()))
            for (k, v) in kwargs
                setproperty!(block, k, v)
            end
            push!(rl.kept, block)
            return block
        end
        # arguments this type will not take back: the old block goes, a new one comes
        delete!(rl.subfigure.buildlisteners, block)
        delete_layoutable!(block)
    end
    block = T(rl.layout[pos.rows, pos.cols, pos.side], args...; kwargs...)
    rl.subfigure.buildlisteners[block] = buildlisteners(block)
    push!(rl.kept, block)
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

Rebuild the subfigure's content by calling `f(sf)`, REUSING the blocks that are
already there: a block of the same type in the same cell takes the new attributes
instead of being deleted and built again. Blocks the closure does not ask for
this time are deleted, the layout is trimmed, and the content size refreshed.

The whole rebuild is one layout pass. Every block deleted and every attribute
written otherwise triggers its own pass over the entire grid, which is where a
panel rebuild's time actually goes: writing a `Label`'s text costs 1551 µs with
updates live and 43 µs inside a suspended layout — the `text` plot underneath
needs 21 µs.

```julia
replace_content!(sf) do sf
    for (i, name) in enumerate(names)
        b = Button(sf.layout[i, 1]; label = name)
        on(b.clicks) do _        # registered fresh on every rebuild; the previous
            select(name)         # closure's callbacks are dropped from the reused
        end                      # block first
    end
end
```
"""
function replace_content!(f, sf::Subfigure)
    layout = sf.layout
    pool = Dict{Tuple{Any, Any, Any, DataType}, Block}()
    for c in contents(layout)
        c isa Block || continue
        k = gridcontent_key(c)
        k === nothing || (pool[k] = c)
    end
    rl = RebuildLayout(layout, sf, pool, Block[])
    GridLayoutBase.with_updates_suspended(layout) do
        f(RebuildSubfigure(sf, rl))
        for (_, block) in rl.pool          # asked for last time, not this time
            delete!(sf.buildlisteners, block)
            delete_layoutable!(block)
        end
        for c in contents(layout)          # …and anything that was never a Block
            c isa Block || delete_layoutable!(c)
        end
        trim!(layout)
    end
    refresh_contentsize!(sf)
    return sf
end
