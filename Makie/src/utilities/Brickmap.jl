struct SDFBrickmapSamplers
    indices::ShaderAbstractions.Sampler{UInt32, 3, Array{UInt32, 3}}
    bricks::ShaderAbstractions.Sampler{N0f8, 3, Array{N0f8, 3}}

    # With 8k as the texture size limit this would allow 64e6 indices... probably enough?
    color_indexmap::ShaderAbstractions.Sampler{UInt32, 2, Array{UInt32, 2}}
    color_bricks::ShaderAbstractions.Sampler{RGB{N0f8}, 3, Array{RGB{N0f8}, 3}}
    bricksize::Int
end

function SDFBrickmapSamplers(
        indices::Array{UInt32, 3},
        bricks::Array{N0f8, 3},
        color_indexmap::Array{UInt32, 2},
        color_bricks::Array{RGB{N0f8}, 3},
        bricksize::Integer
    )
    return SDFBrickmapSamplers(
        ShaderAbstractions.Sampler(indices),
        ShaderAbstractions.Sampler(bricks),
        ShaderAbstractions.Sampler(color_indexmap),
        ShaderAbstractions.Sampler(color_bricks),
        bricksize
    )
end

function SDFBrickmapSamplers(bricksize::Integer)
    return SDFBrickmapSamplers(
        ShaderAbstractions.Sampler(Array{UInt32, 3}(undef, 0, 0, 0)),
        ShaderAbstractions.Sampler(Array{N0f8, 3}(undef, 0, 0, 0)),
        ShaderAbstractions.Sampler(Array{UInt32, 2}(undef, 0, 0)),
        ShaderAbstractions.Sampler(Array{RGB{N0f8}, 3}(undef, 0, 0, 0)),
        bricksize
    )
end

mutable struct SDFBrickmap
    samplers::SDFBrickmapSamplers

    size::NTuple{3, Int}
    bricksize::Int # equal for each dim

    brick_counter::UInt32
    color_index_counter::UInt32
    static_color_counter::UInt32
    color_brick_counter::UInt32

    delay_brick_update::Bool
    delay_color_indexmap_update::Bool
    delay_color_brick_update::Bool

    available_bricks::Vector{UInt32}
    available_static_colors::Vector{UInt32}
    available_color_bricks::Vector{UInt32}
end

SDFBrickmap(bricksize, _size) = SDFBrickmap(bricksize, to3tuple(_size))
function SDFBrickmap(bricksize::Int, _size::NTuple{3, Int})
    idx_size = cld.(_size .- 1, bricksize .- 1)
    # initial size should probably be at least as much as an xy plane would take...
    D = trunc(Int, cbrt(prod(idx_size) / minimum(idx_size))) * bricksize
    init_brick_size = (D, D, D)
    init_color_brick_size = (4, 4, 4) .* bricksize
    indices = fill(UInt32(0), idx_size)
    bricks = Array{N0f8, 3}(undef, init_brick_size)
    color_indexmap = fill(typemax(UInt32), 32, 32) # 1024 values
    color_bricks = Array{RGB{N0f8}}(undef, init_color_brick_size)
    samplers = SDFBrickmapSamplers(indices, bricks, color_indexmap, color_bricks, bricksize)
    return SDFBrickmap(
        samplers, _size, bricksize,
        0, 0, 0, 1, # 1 color brick reserved for static colors
        false, false, false,
        UInt32[], UInt32[], UInt32[]
    )
end

get_brick_index(bm::SDFBrickmap, i, j, k) = _indices(bm)[i, j, k]
_indices(bm::SDFBrickmap) = ShaderAbstractions.data(bm.samplers.indices)
_color_indices(bm::SDFBrickmap) = ShaderAbstractions.data(bm.samplers.color_indexmap)
_color_bricks(bm::SDFBrickmap) = ShaderAbstractions.data(bm.samplers.color_bricks)

# TODO: could be part of finish?
# function start_update!(bm::SDFBrickmap)
#     bm.delay_brick_update = false
#     bm.delay_color_indexmap_update = false
#     bm.delay_color_brick_update = false
#     return
# end

finish_brick_update!(bm::SDFBrickmap, i, j, k) = finish_brick_update!(bm, get_brick_index(bm, i, j, k))
function finish_brick_update!(bm::SDFBrickmap, brick_idx)
    (brick_idx == 0 || bm.delay_brick_update) && return
    _, v = get_view_into_packed(bm.samplers.bricks, bm.bricksize, brick_idx)
    @assert !bm.delay_brick_update "should not get a resize here"
    ShaderAbstractions.update!(bm.samplers.bricks, v.indices...)
    return
end

function finish_update!(bm::SDFBrickmap)
    bm.delay_brick_update && ShaderAbstractions.update!(bm.samplers.bricks)
    ShaderAbstractions.update!(bm.samplers.color_indexmap)
    r = 1:bm.bricksize
    ShaderAbstractions.update!(bm.samplers.color_bricks, r, r, r)
    bm.delay_color_brick_update && ShaderAbstractions.update!(bm.samplers.color_bricks)

    bm.delay_brick_update = false
    bm.delay_color_indexmap_update = false
    bm.delay_color_brick_update = false

    return
end

"""
    increase_size_blocked(A, blocksize::NTuple{3, <:Integer})

Creates a new array with the size of A increased by `blocksize[dim]` along the
shortest dimension of `A`. Each block in A is then copied to the front of the
new array without destroying the block structure.

This is equivalent to the following example with 2D nested arrays:
```
A = reshape([block1, block2, block3, block4], (2, 2))
output = reshape([block1, block2, block3, block4, empty, empty], (3, 2))
```
"""
function increase_size_blocked(A::Array{T, 3}, blocksize::NTuple{3, <:Integer}) where {T}
    S = div.(size(A), blocksize)
    # avoid slow growth for small arrays
    # size 1..10 adds (511, 504, 485, 448, 387, 513, 657, 819, 999, 1744) elements
    delta = max.(ceil.(Int, sqrt.(S)), 10 .- S)
    S = (S .+ delta) .* blocksize
    # B = similar(A, S)
    B = zeros(T, S)

    copy_blocks_to!(B, A, blocksize)

    return B
end

function copy_blocks_to!(target::Array{T, 3}, source::Array{T, 3}, blocksize::NTuple{3, <:Integer}) where {T}
    @boundscheck begin
        all(size(target) .> size(source)) &&
        all(size(target) .% blocksize == 0) &&
        all(size(source) .% blocksize == 0)
    end

    # copy
    N_blocks = div(length(source), prod(blocksize))
    old_indices = CartesianIndices(div.(size(source), blocksize))
    new_indices = CartesianIndices(div.(size(target), blocksize))

    # TODO: Maybe this could be improve by iterating one array continuously and
    # calculating the indices in the other directly?
    @inbounds for block_idx in 1:N_blocks
        old_ijk = Tuple(old_indices[block_idx])
        old_ranges = range.((old_ijk .- 1) .* blocksize .+ 1, old_ijk .* blocksize)
        new_ijk = Tuple(new_indices[block_idx])
        new_ranges = range.((new_ijk .- 1) .* blocksize .+ 1, new_ijk .* blocksize)
        copyto!(view(target, new_ranges...), view(source, old_ranges...))
    end

    return
end

function increase_size_and_copy_no_pad(A::Array{T, 2}, len) where {T}
    N = length(A)
    D = ceil(Int, sqrt(len))
    if T == UInt32
        B = fill(typemax(UInt32), D, D) # for safety with color_indexmap
    else
        B = similar(A, (D, D))
    end
    copyto!(view(B, 1:N), view(A, 1:N))
    return B
end

function get_view_into_packed(blocks::ShaderAbstractions.Sampler{T, 3}, blocksize, block_idx) where {T}
    A = ShaderAbstractions.data(blocks)
    if length(A) < block_idx * blocksize^3
        new = increase_size_blocked(A, (blocksize, blocksize, blocksize))
        setfield!(blocks, :data, new)
        return true, get_view_into_packed(blocks, blocksize, block_idx)[2]
    else
        ijk = Tuple(CartesianIndices(div.(size(A), blocksize))[block_idx])
        ranges = range.((ijk .- 1) .* blocksize .+ 1, ijk .* blocksize)
        return false, view(A, ranges...)
    end
end

function _set_static_color!(bm::SDFBrickmap, idx::Integer, c::RGB{N0f8})
    N = bm.bricksize * bm.bricksize * bm.bricksize
    color_brick_idx = div(idx-1, N) + 1 # 1 based
    if color_brick_idx > div(bm.static_color_counter - 1, N) + 1
        error("TODO: move color brick $idx $color_brick_idx $(bm.static_color_counter) $N")
        # also needs to update color brick counter if we add it
    end
    bm.static_color_counter = max(bm.static_color_counter, idx)
    _, static_colors = get_view_into_packed(bm.samplers.color_bricks, bm.bricksize, color_brick_idx)
    static_colors[mod1(idx, N)] = c
    return
end

function free_brick!(bm::SDFBrickmap, i, j, k)
    brick_idx = get_brick_index(bm, i, j, k)
    if brick_idx != 0
        push!(bm.available_bricks, brick_idx)
        _indices(bm)[i, j, k] = UInt32(0)
        free_color_brick!(bm, brick_idx)
    end
    return
end

function free_color_brick!(bm::SDFBrickmap, brick_idx)
    brick_idx == 0 && return

    indexmap = _color_indices(bm)
    # v this seems to get out of order...?
    bm.color_index_counter < brick_idx && return # nothing to free
    merged_idx = indexmap[brick_idx]
    merged_idx == typemax(UInt32) && return # already freed, probably redundant?

    is_static = ((UInt32(1) << 31) & merged_idx) > 0
    idx = (~(UInt32(1) << 31) & merged_idx) + 1 # 0 -> 1 based

    indexmap[brick_idx] = typemax(UInt32)

    # only mark static color available if not reused
    if is_static
        if !any(==(merged_idx), indexmap)
            # Doesn't decrement static color counter because the color might
            # be removed from the middle. Doesn't need to avoid counter
            # increment because it always overwrites an index that's already
            # counted.

            # TODO: Allow more than 1 Brick
            # Note: this needs to be reset because we search through this
            # to reuse static colors
            _set_static_color!(bm, idx, RGB{N0f8}(1, 0, 1))
            push!(bm.available_static_colors, idx)
        end
    else
        push!(bm.available_color_bricks, idx)
    end
    return
end

function get_or_create_brick(bm::SDFBrickmap, i, j, k)
    brick_idx = get_brick_index(bm, i, j, k)
    if brick_idx == 0
        if isempty(bm.available_bricks)
            brick_idx = bm.brick_counter = bm.brick_counter + 1
        else
            brick_idx = pop!(bm.available_bricks)
        end
    end
    bm.samplers.indices[i, j, k] = brick_idx
    # if we resize we reupload everything at the end
    resized, A = get_view_into_packed(bm.samplers.bricks, bm.bricksize, brick_idx)
    bm.delay_brick_update |= resized
    return brick_idx => A
end

function set_color_index!(bm::SDFBrickmap, brick_idx, color_idx, is_static::Bool)
    @assert brick_idx <= length(bm.samplers.indices.data) "brick_idx $brick_idx can't exceed the maximum number of bricks $(length(bm.indices.data))"
    @assert color_idx <= bm.brick_counter + 1 "color_idx $color_idx can't exceed the number of bricks + 1 $(bm.brick_counter + 1)"

    # maybe resize (should only add to length + 1, so one size bump should be enough)
    indexmap = _color_indices(bm)
    if brick_idx > length(indexmap)
        new = increase_size_and_copy_no_pad(indexmap, brick_idx)
        setfield!(bm.samplers.color_indexmap, :data, new)
    end
    indexmap = _color_indices(bm)
    @assert brick_idx <= length(indexmap) "$brick_idx > $(length(indexmap))"

    idx0 = color_idx - 1 # 0 based
    # idx += ifelse(is_static, 0, UInt32(1)) # skip over static color brick - this is handled by counters
    idx0 = (UInt32(is_static) << 31) | UInt32(idx0) # encode is_static

    indexmap[brick_idx] = idx0
    bm.color_index_counter = max(bm.color_index_counter, color_idx)
    return
end

function get_or_create_color_brick(bm, brick_idx)
    @assert brick_idx != 0 "no brick no color"

    # free static color or color brick associated with brick_idx (if one is associated)
    free_color_brick!(bm, brick_idx)

    # get color brick idx
    idx = if isempty(bm.available_color_bricks)
        # TODO: the first index should be div(static_color_counter, bricksize^3) + 1, so the
        # color_brick_counter should update accordingly
        bm.color_brick_counter += 1
    else
        pop!(bm.available_color_bricks)
    end
    @assert idx <= bm.brick_counter + 1 "$idx < $(bm.brick_counter + 1)"

    resized, color_brick = get_view_into_packed(bm.samplers.color_bricks, bm.bricksize, idx)
    bm.delay_color_brick_update |= resized

    set_color_index!(bm, brick_idx, idx, false)

    return color_brick
end

function set_interpolated_color!(bm, brick_idx, colors)
    brick = get_or_create_color_brick(bm, brick_idx)
    for i in eachindex(colors)
        c = colors[i]
        brick[i] = RGB{N0f8}(
            N0f8(trunc(UInt8, 255.99f0 * red(c)), nothing),
            N0f8(trunc(UInt8, 255.99f0 * green(c)), nothing),
            N0f8(trunc(UInt8, 255.99f0 * blue(c)), nothing),
        )
    end
    if !bm.delay_color_brick_update
        ShaderAbstractions.update!(bm.samplers.color_bricks, brick.indices...)
    end
    return
end

function set_static_color!(bm, brick_idx, c)
    rgb8 = RGB{N0f8}(
        N0f8(trunc(UInt8, 255.99f0 * red(c)), nothing),
        N0f8(trunc(UInt8, 255.99f0 * green(c)), nothing),
        N0f8(trunc(UInt8, 255.99f0 * blue(c)), nothing),
    )

    # clear the previously attached color brick or static color (if any was attached)
    free_color_brick!(bm, brick_idx)

    # TODO: allow multiple
    _, static_colors = get_view_into_packed(bm.samplers.color_bricks, bm.bricksize, 1)
    max_idx = min(bm.static_color_counter, length(static_colors))

    # does the color already exist?
    idx = -1
    if c == RGB{N0f8}(1, 0, 1) # placeholder color
        for i in 1:max_idx
            if static_colors[i] == rgb8 && !in(i, bm.available_static_colors)
                idx = i
                break
            end
        end
    else
        for i in 1:max_idx
            if static_colors[i] == rgb8
                idx = i
                break
            end
        end
    end

    # if the color does not exist, get a new index to write to
    if idx == -1
        if isempty(bm.available_static_colors) # no reuseable index
            idx = bm.static_color_counter + 1 # set_static_color updates this
        else
            idx = pop!(bm.available_static_colors)
        end
    end

    _set_static_color!(bm, idx, rgb8)

    set_color_index!(bm, brick_idx, idx, true)

    return
end

############ TODO v

# function Base.show(io::IO, brickmap::Brickmap{T}) where {T}
#     X, Y, Z = size(brickmap.indexmap)
#     print(io, "$(brickmap.size[1])×$(brickmap.size[2]) Brickmap{$T} with ")
#     print(io, X, "×", Y, "×", Z, " indices, ")
#     print(io, "$(length(brickmap.bricks)) bricks of size ", brickmap.bricksize[1], "×", brickmap.bricksize[2], "×", brickmap.bricksize[3])
# end

# function Base.show(io::IO, ::MIME"text/plain", brickmap::Brickmap{T}) where {T}
#     X, Y, Z = size(brickmap.indexmap)
#     println(io, "$(brickmap.size[1])×$(brickmap.size[2]) Brickmap{$T}:")
#     println(io, "  ", X, "×", Y, "×", Z, " indices")
#     print(io, "  $(length(brickmap.bricks)) bricks of size ", brickmap.bricksize[1], "×", brickmap.bricksize[2], "×", brickmap.bricksize[3])
# end
