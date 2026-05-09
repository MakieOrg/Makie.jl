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

    # indexed by leaf indices
    merged_keys::Vector{Symbol}
    defaults::Vector{Any}
    default_expr::Vector{String}
    leaf_docstring::Vector{Union{Nothing, String}}

    # indexed by positive indices in nesting, i.e. non leaf node indices
    nested_docstrings::Vector{Union{Nothing, String}}

    # 1 per leaf node, indexes into types
    type_index::Vector{Int}

    # synchronized, type_indices contains leaf node indices
    types::Vector{Type}
    type_indices::Vector{Vector{Int}}

    # leaf node indices of every inherited attribute
    inherit::Vector{Int}
end

function Base.getindex(attr::MetaAttributes, key::Symbol)
    idx = attr.nesting.keytables[1][key]
    if idx < 0
        return attr.defaults[-idx]
    else
        error("Nonfinal key $key")
    end
end
Base.haskey(attr::MetaAttributes, key::Symbol) = haskey(attr.nesting.keytables[1], key)


function MetaAttributes()
    return MetaAttributes(
        NestedSearchTree(),
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
            push!(attr.nested_docstrings, meta.docstring)
            convert_attributes!(attr, meta.default_value::DocumentedAttributes, next_level, trace)
        else
            leaf_idx = length(attr.merged_keys) + 1
            add_key!(attr.nesting, level, (key,), -leaf_idx)
            name = ComputePipeline.merged_key(trace)

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
        exclude = tuple(), level = 1
    )
    for (key, val) in pairs(kwdict)
        # kwargs may not all be attributes
        ComputePipeline.has_key_in_level(attr.nesting, level, key) || continue

        idx = attr.nesting.keytables[level][key]
        if idx > 0
            add_from_kwargs!(get_callback, graph, attr, val, exclude, idx)
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
    if haskey(theme(nothing), name)
        resolve_overwrites!(flattened, attr, theme(name), skip)
    end
    resolve_defaults!(flattened, attr, default_theme, skip)
    return flattened
end

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

function add_remaining_block_inputs!(graph, attr, BT, scene, kwargs)
    name = nameof(BT)
    flattened = resolve_defaults(attr, scene, name, kwargs, tuple(), true)
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