using ComputePipeline: NestedSearchTree, Computed, compute_identity, add_key!

struct MetaAttributes
    # This contains a collection of Dicts that trace nesting paths:
    # nesting.keytables[1][key1] = idx1
    # nesting.keytables[idx1][key2] = idx2
    # ...
    # where (key1, key2, ...) traces a nesting path
    # The final key will return an index < 0 which we reuse here to index into
    # lists of leaf attribute information
    nesting::NestedSearchTree

    merged_key_to_index::Dict{Symbol, Int}

    # indexed by leaf indices
    merged_keys::Vector{Symbol}
    defaults::Vector{Any}
    default_expr::Vector{String}
    leaf_docstring::Vector{Union{Nothing, String}}

    # indexed by positive indices in nesting, i.e. non leaf node indices
    nested_docstring::Vector{Union{Nothing, String}}

    # 1 per leaf node, indexes into types
    type_index::Vector{Int}

    # synchronized, type_indices contains leaf node indices
    types::Vector{Type}
    type_indices::Vector{Vector{Int}}

    # leaf node indices of every inherited attribute
    inherit::Vector{Int}
end

################################################################################
# Utilities

function is_attribute(T::Type, name::Symbol)
    meta = meta_attributes(T)
    return has_flat_key(meta, name) || has_nested_key(meta, name)
end

function attribute_names(::Type{T}) where {T}
    return flattened_keys(meta_attributes(T))
end

########################################

# TODO: We should probably differentiate flattened, nested and root level access
# Used in cycle init
function Base.getindex(attr::MetaAttributes, key::Symbol)
    return attr.defaults[attr.merged_key_to_index[key]]
end
Base.haskey(attr::MetaAttributes, key::Symbol) = haskey(attr.nesting.keytables[1], key)
Base.isempty(attr::MetaAttributes) = isempty(attr.nesting.keytables[1])

has_root_key(attr::MetaAttributes, key::Symbol) = haskey(attr.nesting.keytables[1], key)
has_nested_key(attr::MetaAttributes, keys::Tuple) = has_nested_key(attr, keys...)
function has_nested_key(attr::MetaAttributes, keys::Symbol...)
    idx = 1
    for key in keys
        if idx < 0 || !haskey(attr.nesting.keytables[idx], key)
            return false
        end
        idx = attr.nesting.keytables[idx]
    end
    return true
end

root_keys(attr::MetaAttributes) = keys(attr.nesting.keytables[1])
flattened_keys(attr::MetaAttributes) = attr.merged_keys

function has_flat_key(attr::MetaAttributes, key::Symbol)
    return haskey(attr.merged_key_to_index, key)
end

for (name, field) in (:default => :defaults, :expr => :default_expr, :docstring => :leaf_docstring)
    @eval function $(Symbol(:get_flat_, name))(attr::MetaAttributes, key::Symbol)
        return attr.$field[attr.merged_key_to_index[key]]
    end

    @eval function $(Symbol(:get_flat_, name))(attr::MetaAttributes, key::Symbol, default)
        source = attr.$field
        return has_flat_key(attr, key) ? source[attr.merged_key_to_index[key]] : default
    end
end

function get_flat_type(attr::MetaAttributes, key::Symbol)
    return attr.types[attr.type_index[attr.merged_key_to_index[key]]]
end

function unchecked_nested_key_to_index(meta::MetaAttributes, keys::Symbol...)
    return unchecked_nested_key_to_index(meta, keys)
end
function unchecked_nested_key_to_index(meta::MetaAttributes, keys::Tuple)
    idx = 1
    for (i, key) in enumerate(keys)
        if idx < 0 || !haskey(meta.nesting.keytables[idx], key)
            idx < 0 && error("Nested keys $keys could not be resolved because $(keys[i-1]) is not nested.")
            error("Nested keys $keys could not be resolved because $key does not exist in parent.")
        end
        idx = meta.nesting.keytables[idx][key]
    end
    return idx
end

function nested_key_to_index(meta::MetaAttributes, keys::Symbol...)
    idx = unchecked_nested_key_to_index(meta, keys)
    idx > 0 && error("Nested keys $keys point to another nesting layer instead of a value.")
    return -idx
end

for (name, field) in (:default => :defaults, :expr => :default_expr, :docstring => :leaf_docstring)
    @eval function $(Symbol(:get_nested_, name))(attr::MetaAttributes, keys::Symbol...)
        return getfield(attr, $field)[nested_key_to_index(attr, key)]
    end
end

function get_nested_type(attr::MetaAttributes, keys::Symbol...)
    idx = nested_key_to_index(attr, key)
    idx > 0 && error("Nested keys $keys point to another nesting layer instead of a value.")
    return attr.types[attr.type_index[idx]]
end

# If possible use the the methods that do this in bulk, for all attributes
function resolve_single_default(::Type{T}, scene, keys::Symbol...) where {T}
    return resolve_single_default(T, scene, NamedTuple(), keys...)
end

function resolve_single_default(::Type{T}, scene, kwargs, keys::Symbol...) where {T}
    return resolve_single_default(meta_attributes(T), scene, plotsym(T), kwargs, keys...)
end

function resolve_single_default(attr::MetaAttributes, scene, name, kwargs, keys::Symbol...)
    got, result1 = get_nested_value(kwargs, keys...)
    got && return result1
    default_theme = theme(scene)
    if haskey(default_theme, name)
        got, result2 = get_nested_value(default_theme[name], keys...)
        got && return result2
    end
    if haskey(theme(nothing), name)
        got, result2 = get_nested_value(default_theme[name], keys...)
        got && return result2
    end

    # Probably better to avoid type checking Inherit
    idx = nested_key_to_index(attr, keys...)
    if idx in attr.inherit
        return inherit_default(attr.defaults[idx]::Inherit, default_theme)
    else
        return attr.defaults[idx]
    end
end

function get_nested_value(dictlike, key, keys...)
    if haskey(dictlike, key)
        return get_nested_value(dictlike[key], keys...)
    else
        return (false, nothing)
    end
end

function get_nested_value(dictlike, key)
    if haskey(dictlike, key)
        return (true, dictlike[key])
    else
        return (false, nothing)
    end
end

function get_typed_default(meta::MetaAttributes, flattened::Vector, keys::Symbol...)
    idx = nested_key_to_index(meta, keys...)
    T = meta.types[meta.type_index[idx]]
    return T, flattened[idx]
end

function nested_indices(attr::MetaAttributes, keys::Symbol...)
    return nested_indices!(Int[], attr, keys)
end

nested_indices!(indices::Vector{<:Integer}, attr, keys::Symbol...) = nested_indices!(indices, attr, keys)
function nested_indices!(indices, attr, keys::Tuple)
    idx = unchecked_nested_key_to_index(attr, keys)
    nested_indices!(indices, attr, idx)
    return indices
end

function nested_indices!(indices::Vector{<:Integer}, attr, idx::Int)
    if idx > 0
        for i in values(attr.nesting.keytables[idx])
            nested_indices!(indices, attr, i)
        end
    else
        push!(indices, -idx)
    end
    return indices
end

################################################################################

function MetaAttributes()
    return MetaAttributes(
        NestedSearchTree(), Dict{Symbol, Int}(),
        Symbol[], Any[], # per leaf keys, defaults
        String[], Union{Nothing, String}[], # per leaf expr, docstrings
        Union{Nothing, String}[nothing], # nested docstrings
        Int[], Type[], Vector{Int}[], # types
        Int[] # inherit
    )
end

function MetaAttributes(doc_attr::DocumentedAttributes)
    return convert_attributes!(MetaAttributes(), doc_attr)
end

function convert_attributes!(attr::MetaAttributes, doc_attr::DocumentedAttributes, level = 1, _trace = tuple())
    for (key, meta) in doc_attr
        trace = (_trace..., key)
        if is_nested(meta)
            next_level = add_key!(attr.nesting, level, (key,), false)
            push!(attr.nested_docstring, meta.docstring)
            convert_attributes!(attr, meta.default_value::DocumentedAttributes, next_level, trace)
        else
            leaf_idx = length(attr.merged_keys) + 1
            add_key!(attr.nesting, level, (key,), -leaf_idx)
            name = ComputePipeline.merged_key(trace)
            attr.merged_key_to_index[name] = leaf_idx

            push!(attr.merged_keys, name)
            push!(attr.defaults, meta.default_value)
            push!(attr.default_expr, meta.default_expr)
            push!(attr.leaf_docstring, meta.docstring)

            T = meta.type
            type_idx = findfirst(==(T), attr.types)
            if isnothing(type_idx)
                push!(attr.types, T)
                push!(attr.type_indices, Int[])
                type_idx = length(attr.types)
            end
            push!(attr.type_index, type_idx)
            push!(attr.type_indices[type_idx], leaf_idx)

            if meta.default_value isa Inherit
                push!(attr.inherit, leaf_idx)
            end
        end
    end
    return attr
end

# Underscoring these to make them less visible
# state = layer, keys
# layers: stack of the current nesting indices, starting with 1
# keys: stack of current nesting keys, starting with the first key in layer 1 (i.e. one less)
function _begin_nesting_layer!(attr::MetaAttributes, state, key::Symbol, docstring = nothing)
    layers, keys = state
    current_layer = last(layers)
    keytable = attr.nesting.keytables[current_layer]
    if haskey(keytable, key)
        next_layer = keytable[key]
        if next_layer < 0
            error("$key in $(join(keys, '.')) can not nest because it already has a value.")
        end
        attr.nested_docstring[next_layer] = docstring
    else
        push!(attr.nesting.keytables, Dict{Symbol, Int}())
        next_layer = length(attr.nesting.keytables)
        keytable[key] = next_layer
        push!(attr.nested_docstring, docstring)
    end
    push!(layers, next_layer)
    push!(keys, key)
    return
end

function _end_nesting_layer!(state)
    pop!.(state)
    return
end

function _add_attribute!(
        attr::MetaAttributes, state, key::Symbol,
        @nospecialize(type), default_value, default_expr, docstring;
        allow_edit = true
    )
    layers, keys = state
    current_layer = last(layers)
    keytable = attr.nesting.keytables[current_layer]

    if haskey(keytable, key) # existing value

        leaf_idx = -keytable[key]
        name = ComputePipeline.merged_key(keys..., key)
        if leaf_idx < 0
            error("Could not insert attribute :$name because it is already defined as a nesting layer.")
        end
        allow_edit || return false

        # add or remove tracking of leaf_idx as inherited
        was_inherit = insorted(leaf_idx, attr.inherit)
        is_inherit = default_value isa Inherit
        if was_inherit && !is_inherit
            inherit_idx = searchsortedfirst(attr.inherit, leaf_idx)
            deleteat!(attr.inherit, inherit_idx)
        elseif !was_inherit && is_inherit
            inherit_idx = searchsortedfirst(attr.inherit, leaf_idx)
            insert!(attr.inherit, inherit_idx, leaf_idx)
        end

        # update leaf data
        attr.merged_keys[leaf_idx] = name
        attr.defaults[leaf_idx] = default_value
        attr.default_expr[leaf_idx] = default_expr
        if !isnothing(docstring)
            attr.leaf_docstring[leaf_idx] = docstring
        end

        # update leaf type
        type_idx = attr.type_index[leaf_idx]
        old_type = attr.types[type_idx]
        if old_type != type
            # type_indices are sorted
            indices = attr.type_indices[type_idx]
            idx = searchsortedfirst(indices, leaf_idx)
            deleteat!(indices, idx)

            type_idx = findfirst(==(type), attr.types)
            if isnothing(type_idx)
                push!(attr.types, type)
                push!(attr.type_indices, Int[])
                type_idx = length(attr.types)
            end
            push!(attr.type_index, type_idx)
            # keep it sorted
            indices = attr.type_indices[type_idx]
            idx = searchsortedfirst(indices, leaf_idx)
            insert!(indices, idx, leaf_idx)
        end

    else # new value

        leaf_idx = length(attr.merged_keys) + 1
        add_key!(attr.nesting, current_layer, (key,), -leaf_idx)

        name = ComputePipeline.merged_key(keys..., key)
        attr.merged_key_to_index[name] = leaf_idx

        push!(attr.merged_keys, name)
        push!(attr.defaults, default_value)
        push!(attr.default_expr, default_expr)
        push!(attr.leaf_docstring, docstring)

        # leaf_idx only increases here so index lists will remain sorted
        type_idx = findfirst(==(type), attr.types)
        if isnothing(type_idx)
            push!(attr.types, type)
            push!(attr.type_indices, Int[])
            type_idx = length(attr.types)
        end
        push!(attr.type_index, type_idx)
        push!(attr.type_indices[type_idx], leaf_idx)

        if default_value isa Inherit
            push!(attr.inherit, leaf_idx)
        end
    end

    return true
end

# temporary
function _merge_attributes!(target::MetaAttributes, state, source::DocumentedAttributes)
    _merge_attributes_rec!(target, state, MetaAttributes(source), tuple(), 1)
    return
end

function _merge_attributes!(target::MetaAttributes, state, source::MetaAttributes)
    _merge_attributes_rec!(target, state, source, tuple(), 1)
    return
end

function _merge_attributes_rec!(target, state, source, _trace, current_layer)
    keytables = source.nesting.keytables
    for (key, layer_idx) in keytables[current_layer]
        if layer_idx > 0
            trace = (_trace..., key)
            _begin_nesting_layer!(target, state, key, source.nested_docstring[layer_idx])
            _merge_attributes_rec!(target, state, source, trace, layer_idx)
            _end_nesting_layer!(state)
        else
            idx = -layer_idx
            type = source.types[source.type_index[idx]]
            got_added = _add_attribute!(
                target, state, key, type, source.defaults[idx],
                source.default_expr[idx], source.leaf_docstring[idx],
                allow_edit = false
            )
            if !got_added
                target_path = join(state[2], '.') * '.' * string(key)
                source_path = join(_trace, '.') * '.' * string(key)
                error("Could not add :$target_path from :$source_path because :$target_path already exists.")
            end
        end
    end
    return
end

function build_meta_attributes(expr::Expr, local_vars = tuple())
    block_expr = Expr(:block)
    build_meta_attributes!(block_expr.args, expr, local_vars)

    final_expr = quote
        let;
            attr = Makie.MetaAttributes()
            state = (Int[1], Symbol[])
            $block_expr
            @assert isempty(state[2]) "Failed to build documented attributes: Nesting did not resolve correctly, leaving behind $state."
            attr
        end
    end
    # display(final_expr)
    return final_expr
end

function build_meta_attributes!(output::Vector, expr::Expr, local_vars)
    if !(expr.head === :block)
        throw(ArgumentError("Argument is not a begin end block"))
    end

    for line in expr.args
        line isa LineNumberNode && continue

        # TODO: How do you capture the docstring with MacroTools?
        has_docs = line isa Expr && line.head === :macrocall && line.args[1] isa GlobalRef

        if has_docs
            docs = line.args[3]
            attr = line.args[4]
        else
            docs = nothing
            attr = line
        end

        if MacroTools.@capture(attr, key_ = @attributes block_)
            if !isa(key, Symbol)
                error("Attribute name $(repr(key)) must be a Symbol. (Plain variable name in macro closure.)")
            end
            push!(output, :(Makie._begin_nesting_layer!(attr, state, $(QuoteNode(key)), $docs)))
            try
                build_meta_attributes!(output, block, local_vars)
            catch e
                @info "While building nested attributes for $key:"
                rethrow(e)
            end
            push!(output, :(Makie._end_nesting_layer!(state)))

        elseif MacroTools.@capture(attr, key_type_ = val_)
            # ^ this also matches `name::type = val`
            if !MacroTools.@capture(key_type, key_::type_)
                key = key_type
                type = :Any
            end
            if !isa(key, Symbol)
                error("Attribute name $(repr(key)) must be a Symbol. (Plain variable name in macro closure.)")
            end

            # TODO: allow Inherit here?
            attribute = quote
                Makie._add_attribute!(
                    attr, state, $(QuoteNode(key)), $type,
                    $(get_default_expr_no_nesting(val, key, val, local_vars)),
                    $(default_expr_string(val)), $docs
                )
            end
            push!(output, attribute)

        elseif MacroTools.@capture(attr, mixin_...)
            mixin_expr = quote
                mixin = $mixin
                prev_state = last(state[1])
                Makie._merge_attributes!(attr, state, mixin)
                @assert last(state[1]) == prev_state "Mixin must return to the previous state when finished"
            end
            push!(output, mixin_expr)

        else
            error("Could not parse line:\n $line")
        end
    end

    return
end

function convert_old_attributes_expr_to_meta(func_expr::Expr)
    # remove the function header and just work on the body
    ex = func_expr.args[2]

    # preserve :fonts
    # convert theme(scene, key) -> @inherit
    expr = MacroTools.postwalk(ex) do x
        if MacroTools.@capture(x, key_ = Attributes(args__))
            key === :fonts ? :($key = Dict($args)) : x
        elseif MacroTools.@capture(x, theme(scene_, key_))
            return :(Makie.Inherit(($key,)))
        elseif MacroTools.@capture(x, lift(f_, Makie.Inherit(key_tuple_)))
            return :(Makie.Inherit($f, $key_tuple))
        elseif MacroTools.@capture(x, map(f_, Makie.Inherit(key_tuple_)))
            return :(Makie.Inherit($f, $key_tuple))
        end
        return x
    end

    # replace all top level `Attribute` calls with `MetaAttributes` generation code
    local_vars = Set{Symbol}()
    attr_sources = Set{Symbol}()
    for (i, line) in enumerate(expr.args)
        if MacroTools.@capture(line, var_ = Attributes(entries__))
            new_line = line_to_documented_attributes(entries, local_vars, attr_sources)
            expr.args[i] = :($var = $new_line)
            push!(local_vars, var)
            push!(attr_sources, var)
        elseif MacroTools.@capture(line, return Attributes(entries__))
            new_line = line_to_documented_attributes(entries, local_vars, attr_sources)
            expr.args[i] = new_line
        elseif MacroTools.@capture(line, var_ = val_)
            push!(local_vars, var)
        end
    end

    full_expr = :(let; $expr end)
    # display(full_expr)
    return full_expr
end

function line_to_documented_attributes(entries, local_vars, attr_sources)
    # build @DocumentedAttributes style expression
    block_expr = attribute_args_to_block_expr(entries, attr_sources)

    # restore fonts
    block_expr = MacroTools.postwalk(block_expr) do x
        if MacroTools.@capture(x, key_ = Dict(args__))
            key === :fonts ? :($key = Attributes($args)) : x
        end
        return x
    end

    # convert as @DocumentedAttributes
    return build_meta_attributes(block_expr, local_vars)
end

function attribute_args_to_block_expr(entries, attr_sources)
    block_expr = Expr(:block)
    for entry in entries
        if MacroTools.@capture(entry, key_ => val_)
            expr = convert_old_attributes_expr_to_meta_inner(val, attr_sources)
        elseif MacroTools.@capture(entry, key_ = val_)
            expr = convert_old_attributes_expr_to_meta_inner(val, attr_sources)
        else
            error("Failed to parse input of `Attributes(...)`:\n$entry")
        end
        push!(block_expr.args, :($key = $expr))
    end
    return block_expr
end

function convert_old_attributes_expr_to_meta_inner(entry_value_expr, attr_sources)
    if MacroTools.@capture(entry_value_expr, Attributes(entries__))
        block_expr = attribute_args_to_block_expr(entries, attr_sources)
        return :(@attributes $block_expr)
    elseif entry_value_expr isa Symbol && entry_value_expr in attr_sources
        # Doing
        #   a = Attributes(...)
        #   b = Attributes(a = a)
        # is like
        #   a = @DocumentedAttributes begin ... end
        #   b = @DocumentedAttributes begin
        #       a = @attributes begin a... end
        #   end
        return :(@attributes begin $(entry_value_expr)... end)
    end
    return entry_value_expr
end

################################################################################

meta_attributes(::Type) = MetaAttributes()

function collect_nested_paths!(output, nesting, level = 1, _trace = tuple())
    for (key, next_level) in nesting.keytables[level]
        trace = (_trace..., key)
        if next_level > 0
            collect_nested_paths!(output, nesting, next_level, trace)
        else
            push!(output, trace)
        end
    end
    return output
end

function prepare_graph_for_attributes!(
        graph, attr::MetaAttributes, exclude = tuple();
        is_block = false, is_primitive = false
    )

    old_paths = collect_nested_paths!(Tuple[], graph.nesting)
    empty!(graph.nesting.keytables)
    for table in attr.nesting.keytables
        push!(graph.nesting.keytables, copy(table))
    end
    for path in old_paths
        ComputePipeline.add_key!(graph.nesting, path)
    end

    if is_block
        for (indices, type) in zip(attr.type_indices, attr.types)
            add_typed_nodes!(graph, attr, indices, type, exclude)
        end
    else
        for key in attr.merged_keys
            if !haskey(graph.outputs, key) && !in(key, exclude)
                node = Computed(key)
                node.parent_idx = 1
                is_primitive || ComputePipeline.set_type!(node, Any)
                graph.outputs[key] = node
            end
        end
    end

    return graph
end

# Function barrier to hopefully infer type once
function add_typed_nodes!(graph, attr, indices, ::Type{T}, exclude) where {T}
    for idx in indices
        key = attr.merged_keys[idx]
        if !haskey(graph.outputs, key) && !in(key, exclude)
            node = Computed(key)
            node.parent_idx = 1
            ComputePipeline.set_type!(node, T)
            graph.outputs[key] = node
        end
    end
end

function isconnected(graph, key)
    return haskey(graph.outputs, key) && ComputePipeline.hasparent(graph.outputs[key])
end

function connect_nodes!(callback, graph::ComputeGraph, source::Computed, target::Computed)
    edge = ComputePipeline.ComputeEdge(callback, graph, source, target)
    push!(source.parent.dependents, edge)
    target.parent = edge
    return
end

function add_prepared_input!(callback, graph::ComputeGraph, key::Symbol, @nospecialize(value), output::Computed)
    input = ComputePipeline.Input(graph, key, value, callback, output)
    output.parent = input
    graph.inputs[key] = input
    return
end

function add_or_connect_value!(callback, graph, fullkey, @nospecialize(val), output)
    if val isa Computed
        connect_nodes!(callback, graph, val, output)
    elseif val isa Observable
        add_prepared_input!(callback, graph, fullkey, val[], output)
        of = on(val, priority = typemax(Int) - 1) do new_val
            setproperty!(graph, fullkey, new_val)
            return Consume(false)
        end
        push!(graph.observerfunctions, of)
    else
        add_prepared_input!(callback, graph, fullkey, val, output)
    end
    return
end

# kwargs > passthrough > overwrite > doc_attr + inherit
function add_from_kwargs!(
        get_callback,
        graph::ComputeGraph, attr::MetaAttributes, kwdict,
        exclude = tuple()
    )
    # User passes kwargs[Symbol("outer.inner")] = val, e.g. through shared_attributes
    add_from_flattened_kwargs!(get_callback, graph, attr, kwdict, exclude)
    # user passes kwargs[:outer] = (inner = val, ...)
    add_from_nested_kwargs!(get_callback, graph, attr, kwdict, exclude)
    return
end

function add_from_nested_kwargs!(
        get_callback,
        graph::ComputeGraph, attr::MetaAttributes, kwdict,
        exclude = tuple(), level = 1
    )
    for (key, val) in pairs(kwdict)
        # kwargs may not all be attributes
        ComputePipeline.has_key_in_level(attr.nesting, level, key) || continue

        idx = attr.nesting.keytables[level][key]
        if idx > 0
            add_from_nested_kwargs!(get_callback, graph, attr, val, exclude, idx)
        else
            idx = -idx
            fullkey = attr.merged_keys[idx]
            (isconnected(graph, fullkey) || in(key, exclude)) && continue

            output = graph.outputs[fullkey]
            add_or_connect_value!(get_callback(key), graph, fullkey, val, output)
        end
    end
    return
end

function add_from_flattened_kwargs!(
        get_callback,
        graph::ComputeGraph, attr::MetaAttributes, kwdict,
        exclude = tuple()
    )
    for key in attr.merged_keys
        if haskey(kwdict, key) && !isconnected(graph, key) && !in(key, exclude)
            output = graph.outputs[key]
            add_or_connect_value!(get_callback(key), graph, key, kwdict[key], output)
        end
    end
    return
end


# There is no passthrough of graphs in Blocks
function connect_parent!(
        get_callback, child::ComputeGraph, parent::ComputeGraph,
        attr::MetaAttributes, exclude = tuple()
    )
    # TODO: key being a merged_key is probably bad for convert_attribute()
    for key in attr.merged_keys
        if haskey(parent, key) && !isconnected(child, key) && !in(key, exclude)
            connect_nodes!(get_callback(key), child, parent[key], child.outputs[key])
        end
    end
end

# add remaining entries
function add_remaining_inputs!(get_callback, graph, attr, exclude = tuple())
    # TODO: key being a merged_key is probably bad for convert_attribute()
    for (key, value) in zip(attr.merged_keys, attr.defaults)
        if !isconnected(graph, key) && !in(key, exclude)
            output = graph[key]
            add_prepared_input!(get_callback(key), graph, key, value, output)
        end
    end
end


function add_theme!(graph, attr, T, scene, exclude, kwargs)
    # add merged keys from kwargs to exclusion list
    collect_merged_keys!(exclude, attr, kwargs)
    # fill out an array with resolved defaults from theme + plot
    defaults = resolve_defaults(attr, scene, plotsym(T), NamedTuple(), exclude)
    # update anything that's an input and not excluded
    for (i, key) in enumerate(attr.merged_keys)
        if !(key in exclude) && haskey(graph.inputs, key)
            val = to_value(defaults[i])
            # Skipping setproperty/setindex from ComputePipeline to
            # avoid type inference for val.
            setfield!(graph.inputs[key], :value, val)
            # This would usually only happen if `is_same()` returns false, but
            # since this runs during plot init we don't lose much from
            # setting everything dirty.
            ComputePipeline.mark_dirty!(graph.inputs[key])
        end
    end
    return
end

function collect_merged_keys!(output, attr, kwargs, level = 1)
    for (key, val) in pairs(kwargs)
        # kwargs/overwrites may not all be attributes
        ComputePipeline.has_key_in_level(attr.nesting, level, key) || continue
        idx = attr.nesting.keytables[level][key]
        if idx > 0
            resolve_overwrites!(output, attr, val, idx)
        else
            push!(output, attr.merged_keys[-idx])
        end
    end
    return output
end

function resolve_defaults(attr, scene, name::Symbol, kwargs, skip = tuple(), remove_kw = false)
    flattened = Vector{Any}(undef, length(attr.defaults))
    resolve_overwrites!(flattened, attr, kwargs, skip, remove_kw)
    default_theme = theme(scene)
    if haskey(default_theme, name)
        resolve_overwrites!(flattened, attr, default_theme[name], skip)
    end
    resolve_defaults!(flattened, attr, default_theme, skip)
    return flattened
end

# kwargs, theme(scene/nothing)[:Plot/:Block]
function resolve_overwrites!(flattened, attr, kwargs, skip, remove = false, level = 1)
    for (key, val) in pairs(kwargs)
        # kwargs/overwrites may not all be attributes
        ComputePipeline.has_key_in_level(attr.nesting, level, key) || continue
        idx = attr.nesting.keytables[level][key]
        if idx > 0
            resolve_overwrites!(flattened, attr, val, skip, idx)
        elseif !isassigned(flattened, -idx) && !in(attr.merged_keys[-idx], skip)
            flattened[-idx] = val
        end
    end
    if remove
        filter!(p -> !(p[1] in keys(attr.nesting.keytables[level])), kwargs)
    end
    return
end

function resolve_defaults!(flattened, attr, theme, skip)
    for i in attr.inherit
        if !isassigned(flattened, i) && !in(attr.merged_keys[i], skip)
            flattened[i] = inherit_default(attr.defaults[i]::Makie.Inherit, theme)
        end
    end
    for (i, val) in enumerate(attr.defaults)
        if !isassigned(flattened, i) && !in(attr.merged_keys[i], skip)
            flattened[i] = val
        end
    end
    return
end

function add_remaining_block_inputs!(graph, attr, flattened)
    for (indices, type) in zip(attr.type_indices, attr.types)
        add_remaining_block_inputs!(graph, attr, indices, type, flattened)
    end
    return graph
end

function add_remaining_block_inputs!(graph, attr, indices, ::Type{T}, source) where {T}
    for i in indices
        key = attr.merged_keys[i]
        if !isconnected(graph, key)
            add_or_connect_value!(
                BlockAttributeConvert{T}(), graph, key, source[i], graph[key]
            )
        end
    end
    return
end
