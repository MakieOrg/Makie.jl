struct NestedSearchTree
    keytables::Vector{Dict{Symbol, Int}}
end

NestedSearchTree() = NestedSearchTree([Dict{Symbol, Int}()])

has_root_key(tree::NestedSearchTree, key::Symbol) = has_key_in_level(tree, 1, key)
function has_key_in_level(tree::NestedSearchTree, level::Int, key::Symbol)
    if length(tree.keytables) >= level
        return haskey(tree.keytables[level], key)
    else
        return false
    end
end

add_key!(tree::NestedSearchTree, args...) = add_key!(tree, args)
add_key!(tree::NestedSearchTree, args::Tuple) = add_key!(tree, 1, args)
add_path!(tree::NestedSearchTree, args...) = add_path!(tree, args)
add_path!(tree::NestedSearchTree, args::Tuple) = add_key!(tree, 1, args, false)
function add_key!(tree::NestedSearchTree, level, args::Tuple, points_to_value = true)
    key_to_insert = first(args)
    tail = Base.tail(args)
    if has_key_in_level(tree, level, key_to_insert)

        next_level = tree.keytables[level][key_to_insert]
        if next_level == -1 && !isempty(tail)
            error("Cannot insert (...).$key_to_insert.(...) - (...).$key_to_insert is already set to a value.")
        elseif next_level != -1 && isempty(tail)
            error("Cannot insert (...).$key_to_insert - (...).$key_to_insert is already set to a nested graph.")
        elseif isempty(tail)
            error("The given nested path (...).$key_to_insert already exists.")
        else
            add_key!(tree, next_level, tail)
        end
        return
    else

        @assert length(tree.keytables) >= level - 1
        if length(tree.keytables) == level - 1
            push!(tree.keytables, Dict{Symbol, Int}())
        end

        if isempty(tail)
            if points_to_value
                tree.keytables[level][key_to_insert] = -1
            else
                next_level = length(tree.keytables) + 1
                @assert length(tree.keytables) == next_level - 1
                tree.keytables[level][key_to_insert] = next_level
                push!(tree.keytables, Dict{Symbol, Int}())
            end
            return
        else
            next_level = length(tree.keytables) + 1
            tree.keytables[level][key_to_insert] = next_level
            add_key!(tree, next_level, tail)
            return
        end
    end
end

delete_key!(tree::NestedSearchTree, args...) = delete_key!(tree, args)
delete_key!(tree::NestedSearchTree, args::Tuple) = delete_key!(tree, 1, args)
function delete_key!(tree::NestedSearchTree, level, args::Tuple)
    current_key = first(args)
    tail = Base.tail(args)
    if has_key_in_level(tree, level, current_key)
        next_level = pop!(tree.keytables[level], current_key)

        if next_level != -1 # on path to leaf node
            delete_key!(tree, next_level, tail)
        end

        # If level is empty there are no more paths crossing through it,
        # so we can delete its table. No other entry should be pointing
        # to it, but there might be entries pointing to later trees.
        # These need to be adjusted.
        if isempty(tree.keytables[level])
            deleteat!(tree.keytables, level)
            for table in tree.keytables
                for (k, v) in table
                    if v > level
                        table[k] = v - 1
                    elseif v == level
                        @warn "Cleanup assumption broken"
                    end
                end
            end
        end
    else # should we error when deleting a non-existing key/path?
        return
    end
end

keys_in_level(tree::NestedSearchTree, level) = keys(tree.keytables[level])

function recursive_keys(tree::NestedSearchTree, level, root = tuple(), allkeys = Tuple[])
    for (key, next_level) in tree.keytables[level]
        if next_level == -1
            push!(allkeys, (root..., key))
        else
            path = (root..., key)
            recursive_keys(tree, next_level, path, allkeys)
        end
    end
    return allkeys
end

struct TemporarySearchResult
    parent::NestedSearchTree
    keys::Vector{Symbol}
    next_index::Int
end

function Base.getindex(tree::NestedSearchTree, key::Symbol)
    if has_key_in_level(tree, 1, key)
        next = tree.keytables[1][key]
        return TemporarySearchResult(tree, [key], next)
    else
        throw(KeyError(key))
    end
end

function Base.getindex(temp::TemporarySearchResult, key::Symbol)
    new_keys = [temp.keys..., key]
    if has_key_in_level(temp.parent, temp.next_index, key)
        next = temp.parent.keytables[temp.next_index][key]
        return TemporarySearchResult(temp.parent, new_keys, next)
    else
        merged = merged_key(new_keys)
        throw(KeyError(merged))
    end
end

isfinal(temp::TemporarySearchResult) = temp.next_index == -1

merged_key(temp::TemporarySearchResult) = merged_key(temp.keys)
merged_key(keys::Symbol...) = merged_key(keys)
merged_key(keys::Tuple{Symbol}) = keys[1]
merged_key(keys::Tuple{Symbol, Vararg{Symbol}}) = reduce((a, b) -> Symbol(a, :(.), b), keys)
merged_key(start::Symbol, keys::Tuple{Symbol, Vararg{Symbol}}) = Symbol(start, :(.), merged_key(keys))
function merged_key(keys::Vector{Symbol})
    if length(keys) == 1
        return keys[1]
    else
        reduce((a, b) -> Symbol(a, :(.), b), keys)
    end
end

function Base.haskey(temp::TemporarySearchResult, key::Symbol)
    return has_key_in_level(temp.parent, temp.next_index, key)
end

function Base.haskey(temp::TemporarySearchResult, key::Symbol, keys::Symbol...)
    haskey_here = has_key_in_level(temp.parent, temp.next_index, key)
    return haskey_here && haskey(getindex(temp, key), keys...)
end

function Base.haskey(tree::NestedSearchTree, key::Symbol)
    return has_root_key(tree, key)
end

function Base.haskey(tree::NestedSearchTree, key::Symbol, keys::Symbol...)
    return has_root_key(tree, key) && haskey(getindex(tree, key), keys...)
end

Base.keys(trace::TemporarySearchResult) = keys(trace.parent.keytables[trace.next_index])
recursive_keys(trace::TemporarySearchResult) = recursive_keys(trace.parent, trace.next_index)
