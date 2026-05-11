################################################################################
### Attribute Examples
################################################################################

"""
    attribute_examples(::Union{Type{<:Block}, Type{<:Plot}})

Returns a dictionary mapping attribute names to vectors of example code.
For Plot types, this loads examples from the markdown documentation file at
`documentation/plots/{plotname}.md` under the "## Attributes" section.
For Block types, returns an empty dictionary (Block examples are not yet moved to markdown).
"""
function attribute_examples(::Type{PT}) where {PT <: AbstractPlot}
    md_path = path_to_plot_examples(PT)
    if !isfile(md_path)
        return Dict{Symbol, Vector{Example}}()
    end
    return extract_attribute_examples(md_path)
end

"""
    extract_attribute_examples(markdown_file_path::String)

Parse a markdown file and extract all attribute examples that come after the "## Attributes" header.
Each attribute starts with a "### `attribute_name`" header and includes all code blocks until the next header.
Returns a dictionary mapping attribute names (as Symbols) to vectors of `Example` objects.
"""
function extract_attribute_examples(markdown_file_path::String)
    # Parse the markdown file
    md = Markdown.parse(read(markdown_file_path, String))

    # Find the "## Attributes" header
    attr_h2_idx = findfirst(md.content) do item
        item isa Markdown.Header{2} &&
            !isempty(item.text) &&
            item.text[1] == "Attributes"
    end

    # If no attributes section exists, return empty dict
    if isnothing(attr_h2_idx)
        return Dict{Symbol, Vector{Example}}()
    end

    # Find all H3 headers after the Attributes section
    h3_indices = findall(md.content) do item
        item isa Markdown.Header{3}
    end

    # Filter to only H3 headers that come after the Attributes H2
    h3_indices = filter(idx -> idx > attr_h2_idx, h3_indices)

    if isempty(h3_indices)
        return Dict{Symbol, Vector{Example}}()
    end

    # Extract each attribute and its examples
    attributes = Dict{Symbol, Vector{Example}}()
    for i in eachindex(h3_indices)
        idx = h3_indices[i]
        next_idx = i < length(h3_indices) ? h3_indices[i + 1] : length(md.content) + 1

        # Get attribute name from H3 header
        h3 = md.content[idx]
        # Attribute names are wrapped in backticks: ### `attribute_name`
        attr_text = string(h3.text[1].code)
        # Remove backticks if present
        attr_name = strip(attr_text, '`')
        attr_sym = Symbol(attr_name)

        # Extract all code blocks between this H3 and the next header
        examples = Example[]
        for j in (idx + 1):(next_idx - 1)
            item = md.content[j]
            if item isa Markdown.Code && item.language == "@figure"
                # Extract backend if specified
                backend = :CairoMakie
                if occursin("backend=GLMakie", item.language) || occursin("backend = GLMakie", item.language)
                    backend = :GLMakie
                elseif occursin("backend=WGLMakie", item.language) || occursin("backend = WGLMakie", item.language)
                    backend = :WGLMakie
                end
                push!(examples, Example(code = item.code, backend = backend))
            end
        end

        if !isempty(examples)
            attributes[attr_sym] = examples
        end
    end

    return attributes
end

################################################################################
### Plot Examples
################################################################################

"""
    path_to_plot_examples(PlotType)

Returns the path to the markdown file containing examples for the given PlotType.
This can be extended to point to a markdown file outside the default path.
"""
function path_to_plot_examples(::Type{PT}) where {PT <: AbstractPlot}
    plfunc = plotfunc(PT)
    plfunc_str = string(plfunc)
    return joinpath(@__DIR__, "plots", "$plfunc_str.md")
end

"""
    extract_examples(PlotType)

Extracts examples from the markdown file given by `path_to_plot_examples(PlotType)`.

This can be extended to return examples directly, without an external file. It
is expected to return a `Vector{Markdown.MD}`, containing examples each starting
with a header `### Name of Example`.
"""
function extract_examples(::Type{PT}) where {PT <: AbstractPlot}
    # Path to markdown file
    md_path = path_to_plot_examples(PT)

    if !isfile(md_path)
        return Markdown.MD[]
    end

    return extract_examples(md_path)
end

"""
    extract_examples(markdown_file_path::String)

Parse a markdown file and extract all examples that come after the "## Examples" header.
Each example starts with a "### Example Title" header and includes all content until the next header.
Returns a vector of `Markdown.MD` objects, each representing an example.
"""
function extract_examples(markdown_file_path::String)
    # Parse the markdown file
    markdown_file_path = normpath(markdown_file_path)
    md = Markdown.parse(read(markdown_file_path, String))
    # Verify expected structure
    if length(md.content) < 2
        error(
            "Expected markdown file to have at least 2 elements (H1 and H2 headers), got $(length(md.content)) in file: $markdown_file_path",
        )
    end
    if !(md.content[1] isa Markdown.Header{1})
        error("Expected first element to be H1 header, got $(typeof(md.content[1])) in file: $markdown_file_path")
    end
    if !(
            md.content[2] isa Markdown.Header{2} &&
                !isempty(md.content[2].text) &&
                md.content[2].text[1] == "Examples"
        )
        error("Expected second element to be H2 'Examples' header in file: $markdown_file_path")
    end
    content = md.content[3:end]
    stopidx = findfirst(content) do item
        item isa Markdown.Header{2}
    end

    examples = content[1:(isnothing(stopidx) ? end : (stopidx - 1))]
    # Find all H3 headers
    h3_indices = findall(examples) do item
        item isa Markdown.Header{3}
    end

    if isempty(h3_indices)
        error("No H3 example headers found in file: $markdown_file_path")
    end

    # Extract each example
    result = Markdown.MD[]
    for i in eachindex(h3_indices)
        idx = h3_indices[i]
        next_idx = i < length(h3_indices) ? h3_indices[i + 1] : length(examples) + 1
        content = Markdown.MD(examples[idx:(next_idx - 1)])
        push!(result, content)
    end
    return result
end

"""
    plot_examples(::Type{<:Plot}, max_examples::Number=1)

Returns example documentation by reading the markdown file from `documentation/plots/{plotname}.md`.
Parses the markdown structure and returns up to `max_examples` examples.

Returns an empty string if the markdown file doesn't exist or has no examples.

# Arguments
- `max_examples`: Maximum number of examples to include (default: 1). Use `Inf` for all examples.
"""
function plot_examples(::Type{PT}, max_examples::Number = 1, replace_header = max_examples == 1) where {PT <: Plot}
    examples = extract_examples(PT)
    isempty(examples) && return ""

    n_examples = examples[1:round(Int, min(length(examples), max_examples))]

    if replace_header && max_examples == 1
        header = n_examples[1].content[1]
        if header isa Markdown.Header
            n_examples[1].content[1] = Markdown.Header{2}(Any["Example"])
        end
    end

    return join(map(string, n_examples), "\n")
end

################################################################################
### Argument Documentation (Type-based)
################################################################################


"""
    argument_docs(::Type{<:Plot})

Returns the argument documentation for a plot type.
This is a fallback that dispatches to the conversion trait.
Plot-specific overrides are generated by the @recipe macro when the recipe
docstring contains an "## Arguments" section.
"""
function argument_docs(::Type{PT}) where {PT <: Plot}
    # This fallback is used when there's no plot-specific override
    # The @recipe macro generates overrides when "## Arguments" exists in the docstring
    CT = conversion_trait(PT)
    return argument_docs(CT)
end

"""
    argument_docs(::ConversionTrait)

Generic fallback that extracts argument documentation from the ConversionTrait's docstring.
Looks for an "## Arguments" section and returns that content as Markdown.
"""
function argument_docs(::T) where {T <: ConversionTrait}
    # Get the docstring for the trait
    return extract_arguments_section(Base.Docs.doc(T))
end

# Generic fallback for NoConversion plots
function argument_docs(::NoConversion)
    return Markdown.MD()  # Return empty markdown
end

################################################################################
### Main Documentation Function
################################################################################

# Consider making a dedicated group for DataInspector?
const DEFAULT_ATTRIBUTE_GROUPS = let
    generic = collect(keys(Makie.mixin_generic_plot_attributes().d))
    push!(generic, :cycle)
    inspector = [:inspectable, :inspector_label]
    filter!(name -> !in(name, inspector), generic)
    colormapping = collect(keys(Makie.mixin_colormap_attributes().d))
    shading = collect(keys(Makie.mixin_shading_attributes().d))

    Pair{String, Vector{Symbol}}[
        "Generic Attributes" => sort!(generic),
        "DataInspector Attributes" => inspector,
        "3D Shading Attributes" => sort!(shading),
        "Colormapping Attributes" => sort!(colormapping),
    ]
end

"""
    default_attribute_groups()

Returns a deepcopy of the default attribute groups for further modification.
"""
default_attribute_groups() = deepcopy(DEFAULT_ATTRIBUTE_GROUPS)

"""
    uncategorized_attributes(PlotType, name = "\$PlotType Attributes")

Returns all attribute names of the given `PlotType` that are not categorized
in `attribute_groups(PlotType)`. This mostly returns attributes specific to
the plot type.
"""
function uncategorized_attributes(::Type{PT}) where {PT <: AbstractPlot}
    groups = attribute_groups(PT)
    attr = meta_attributes(PT)
    keys_used = fill(false, length(attr.merged_keys))
    flag_grouped_attributes!(keys_used, attr)
    for (name, entrylist) in groups
        for entry in entrylist
            for idx in nested_indices(attr, entry)
                keys_used[idx] = true
            end
        end
    end
    return attr.merged_keys[.!keys_used]
end

"""
    attribute_groups(::Type{<:Plot})

Returns a list identifying grouped attributes for docstrings. Each element is a
`Pair` containing the name of the group and a list of the associated attributes.

This function is meant to be extended to refine attribute groups for recipes.
`default_attribute_groups()` can be used to get the default groups.

```
function Makie.attribute_groups(::Type{<:MyPlot})
    groups = Makie.default_attribute_groups()
    push!(groups, "My Attributes" => [:myattrib1, :myattrib2])
    return groups
end
```

If the listed attributes exist in `MyPlot` they will be printed as
"**My Attributes**: `myattrib1`, `myattrib2`". Attributes that don't exist will
be skipped. If every attribute does not exist, the group will not be printed.
"""
attribute_groups(::Type{<:AbstractPlot}) = Makie.DEFAULT_ATTRIBUTE_GROUPS

function get_attribute_docs(::Type{T}; full = false) where {T}
    # Build attributes section
    attrs = meta_attributes(T)
    # Show detailed attribute documentation
    if isempty(attrs)
        return Markdown.parse("## Attributes\n\nNo attributes available.")
    else
        io = IOBuffer()
        println(io, "## Attributes\n")
        write_attribute_docs!(io, T, attrs, full)
        return Markdown.parse(String(take!(io)))
    end
end

function write_attribute_docs!(io, PT, meta, full::Bool)
    groups = attribute_groups(PT)
    keys_used = fill(false, length(meta.merged_keys))
    examples = attribute_examples(PT)

    current_indices = Int[]

    for (groupname, entries) in groups
        if any(entry -> has_nested_key(meta, entry), entries)
            print(io, full ? "### $groupname\n\n" : "**$groupname**: ")
            has_prev = false
            for entry in entries
                has_nested_key(meta, entry) || continue
                if full
                    # This currently skips over nested levels and just collects indices
                    # for leaf nodes. To treat intermediate keys we would need to
                    # map any idx > 0 found in nested_indices (after keys get resolved)
                    # to `meta.nested_docstring` and any idx < 0 like we do here.
                    nested_indices!(current_indices, meta, entry)
                    sort!(current_indices, by = i -> meta.merged_keys[i])
                    for idx in current_indices
                        keys_used[idx] && continue
                        write_full_single_attribute_docs!(io, meta, examples, idx)
                        keys_used[idx] = true
                    end
                    empty!(current_indices)
                else
                    has_prev && print(io, ", ")
                    write_short_nested_attribute_docs!(io, meta, entry, keys_used)
                    has_prev = true
                end
            end
            full || print(io, "\n\n")
        end
    end

    leftover_indices = eachindex(meta.merged_keys)[.!keys_used]
    sort(leftover_indices, by = i -> meta.merged_keys[i])

    # Print the rest as plot specific attributes
    if !isempty(leftover_indices)
        # TODO: short
        kind = PT <: Plot ? "Plot" : "Block"
        print(io, full ? "### $kind Attributes\n\n" : "**$kind Attributes**: ")
        has_prev = false
        for idx in leftover_indices
            if full
                write_full_single_attribute_docs!(io, meta, examples, idx)
            else
                has_prev && print(io, ", ")
                print(io, '`', meta.merged_keys[idx], '`')
                has_prev = true
            end
        end
        full || print(io, "\n\n")
    end

    if !full
        typename = string(plotsym(PT))
        info = if VERSION < v"1.12.2"
            "help($typename, :attribute)"
        else
            "?$typename.attribute"
        end
        println(
            io,
            "For more information and examples on specific attributes check `$info`.",
            " For nested attributes check `help($typename, :outer, :inner)`."
        )
    end

    return io
end

function write_full_single_attribute_docs!(io, attrs, all_examples, idx::Int)
    merged_name = attrs.merged_keys[idx]
    docstring = attrs.leaf_docstring[idx]
    default_expr = attrs.default_expr[idx]

    println(io, "#### `$merged_name`\n")
    println(io, "**Default:** `$default_expr`\n")
    if !isnothing(docstring)
        println(io, docstring)
    end

    # Add example if available
    if haskey(all_examples, merged_name)
        examples = all_examples[merged_name]
        println(io, "**Example:**\n")
        for (i, ex) in enumerate(examples)
            show(io, ex)
            if i < length(examples)
                println(io)
            end
        end
        println(io)
    end

    return
end

function write_short_nested_attribute_docs!(io, meta, entry, keys_used)
    # TODO: Maybe should add checks to skip repeated pre-leaf attributes?
    # I.e. not just check leaf nodes with keys_used, but also intermediate ones
    layer = unchecked_nested_key_to_index(meta, entry)
    if layer > 0 # nested
        print(io, '`', ComputePipeline.merged_key(entry), '.', '`')
        write_short_nested_attribute_docs!(io, meta, layer, keys_used)
    else # leaf node
        print(io, '`', ComputePipeline.merged_key(entry), '`')
        keys_used[-layer] = true
    end
end

function write_short_nested_attribute_docs!(io, meta, layer::Int, keys_used)
    keytable = meta.nesting.keytables[layer]
    keys_sorted = sort(keys(keytable))
    print(io, '(')
    has_prev = false
    for key in keys_sorted
        idx = keytable[key]
        has_prev && print(io, ", ")
        print(io, '`', key, '`')
        if idx > 0 # nested
            print(io, '.')
            write_short_nested_attribute_docs!(io, meta, idx, keys_used)
        else # leaf
            keys_used[-idx] = true
        end
        has_prev = true
    end
    print(io, ')')
    return
end

"""
    get_call_signature_docs(PlotType)

Returns the call signature section of a docstring for the given `PlotType`.
"""
function get_call_signature_docs(::Type{PT}) where {PT <: AbstractPlot}
    plfunc = plotfunc(PT)
    plfunc_str = string(plfunc)
    plfunc!_str = plfunc_str * "!"
    # Get plot type name by capitalizing the function name (lines -> Lines)
    PlotType_str = uppercasefirst(plfunc_str)

    # Build function signatures section
    return Markdown.parse(
        """
        ```julia
        # return a new figure, axis, and plot
        f, ax, pl = $plfunc_str(args...; kw...)
        # creates an axis in a subfigure grid position
           ax, pl = $plfunc_str(f[row, col], args...; kw...)
        # Creates a plot in the given axis or scene.
               pl = $plfunc!_str(ax::Union{Scene, AbstractAxis}, args...; kw...)
        # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
             spec = SpecApi.$(PlotType_str)(args...; kw...)
        ```
        """
    )
end

"""
    document_recipe(::Type{PT}, user_docstring; max_examples=1, full_attributes=false) where {PT<:Plot}

Generates comprehensive documentation for a plot type by combining:
- Standardized function signatures
- User-provided documentation
- Argument documentation (from conversion traits)
- Attribute documentation
- Examples

This function is called automatically by the `@recipe` macro via `Docs.getdoc`.

# Arguments
- `max_examples`: Maximum number of examples to show (default: 1). Use `0` or negative for all examples.
- `full_attributes`: If `true`, shows detailed documentation for each attribute. If `false` (default), shows a summary.
"""
function document_recipe(::Type{PT}, user_docstring::Markdown.MD; max_examples = 1, full_attributes::Bool = false) where {PT <: Plot}
    # Build function signatures section
    signatures = get_call_signature_docs(PT)

    # Build arguments section (argument_docs now returns Markdown directly)
    arguments_section = argument_docs_md(PT)

    attributes_section = get_attribute_docs(PT; full = full_attributes)

    # Build examples section
    examples = plot_examples(PT, max_examples)
    # Add link to online documentation
    if max_examples == 1
        plfunc_str = string(plotfunc(PT))
        online_docs_link = "\n\nSee the [online documentation](https://docs.makie.org/stable/reference/plots/$plfunc_str) for more examples."
        examples = examples * online_docs_link
    end
    examples_section = Markdown.parse(examples)
    # Combine all sections into a single Markdown document
    user_docs = extract_before_arguments_section(user_docstring)
    combined = Markdown.MD()
    append!(combined.content, signatures.content)
    append!(combined.content, user_docs.content)
    append!(combined.content, arguments_section.content)
    append!(combined.content, examples_section.content)
    append!(combined.content, attributes_section.content)
    return combined
end

################################################################################
### Full Documentation Function
################################################################################

"""
    full_docs(::Type{<:Plot}; replace_figure=true)

Generates comprehensive documentation for a plot type including:
- Function signatures
- User-provided documentation
- Argument documentation
- **ALL** examples from the documentation
- **Detailed** attribute documentation for each attribute

This is a convenience function that calls `document_recipe` with appropriate settings for full documentation.

If `replace_figure=true` (default), replaces `@figure` code blocks with `julia` for REPL display.
If `replace_figure=false`, preserves `@figure` blocks for Documenter processing.

Use this for comprehensive reference. For a quick overview, use `?PlotType` instead.

# Example
```julia
full_docs(Scatter)
full_docs(Lines)
full_docs(Lines; replace_figure=false)  # For makedocs
```
"""
function full_docs(::Type{PT}; replace_figure = true) where {PT <: Plot}
    # Get the user docstring for this plot type
    # Call document_recipe with full documentation settings
    docs = Docs.getdoc(PT; max_examples = Inf, full_attributes = true)
    # Replace @figure with julia if requested for REPL display
    if replace_figure
        docs_str = string(docs)
        docs_str = replace(docs_str, r"```@figure([^\n]*)" => s"```julia\1")
        return Markdown.parse(docs_str)
    end
    return docs
end


################################################################################
### Documentation Generation for makedocs
################################################################################

"""
    generate_plot_docs(output_dir::String; plot_types=nothing)

Generate markdown documentation files for all plot types using `full_docs()`.
These files are meant to be used by Documenter.jl in the docs build process.

# Arguments
- `output_dir`: Directory where markdown files should be written (e.g., "docs/src/reference/plots")
- `plot_types`: Optional vector of plot types to generate docs for. If `nothing`, generates for all known plot types.

# Example
```julia
# In docs/make.jl before makedocs():
Makie.generate_plot_docs("docs/src/reference/plots")
```
"""
function generate_plot_docs(output_dir::String; plot_types = nothing)
    mkpath(output_dir)

    # If plot_types is not specified, discover from markdown files
    if isnothing(plot_types)
        # Get all markdown files in the plots directory
        plots_dir = joinpath(@__DIR__, "plots")
        md_files = filter(f -> endswith(f, ".md"), readdir(plots_dir))
        plot_names = [splitext(f)[1] for f in md_files]
    else
        # Use provided plot types
        plot_names = [string(plotfunc(PT)) for PT in plot_types]
    end

    for plfunc_str in plot_names
        output_file = joinpath(output_dir, "$plfunc_str.md")
        println("Generating documentation for $plfunc_str...")

        # Look up the plot type from the function name
        plfunc_sym = Symbol(plfunc_str)

        # Check if the function exists in Makie
        if !isdefined(Makie, plfunc_sym)
            @warn "Skipping $plfunc_str: function not found in Makie"
            continue
        end

        plfunc = getproperty(Makie, plfunc_sym)
        PT = Makie.Plot{plfunc}

        # Generate full documentation (preserve @figure blocks for Documenter)
        docs = full_docs(PT; replace_figure = false)
        # Convert to string and write to file
        open(output_file, "w") do io
            # Write a title
            println(io, "# $plfunc_str")
            println(io)
            # Write the full docs content as markdown
            # Use Markdown.plain to convert to string
            print(io, Markdown.plain(docs))
        end
    end
    return plot_names
end

################################################################################
### REPL.fielddoc overload
################################################################################


function field_docs(::Type{T}, names::Symbol...) where {T <: Union{Plot, Block}}
    return field_docs(T, meta_attributes(T), names...)
end

function field_docs(::Type{T}, meta::MetaAttributes, names::Symbol...) where {T <: Union{Plot, Block}}
    idx = unchecked_nested_key_to_index(meta, names)

    if idx > 0 # more nesting
        merged_key = ComputePipeline.merged_key(names...)
        no_doc = "No documentation available for attribute `$merged_key` of plot type `$T`."
        docstring = something(meta.nested_docstring[idx], no_doc)
        default_expr = "@attributes begin ... end"
        # Probably won't have examples for intermediate nesting levels?
        # E.g. if a plot has `plot.scatter.markersize`, we probably won't have
        # attribute examples for plot.scatter?
    else # leaf attribute
        merged_key = meta.merged_keys[-idx]
        no_doc = "No documentation available for attribute `$merged_key` of plot type `$T`."
        docstring = something(meta.leaf_docstring[-idx], no_doc)
        default_expr = meta.default_expr[-idx]
    end

    # Build documentation string
    io = IOBuffer()

    # Attribute name and default
    println(io, "**`$merged_key`** = `$default_expr`")
    println(io)

    # Docstring
    println(io, docstring)
    println(io)

    # Example
    examples_dict = try
        attribute_examples(T)
    catch
        nothing
    end
    if examples_dict isa Dict && haskey(examples_dict, merged_key)
        examples = examples_dict[merged_key]
        if examples isa Vector && !isempty(examples)
            for (i, ex) in enumerate(examples)
                println(io, "### Example $I\n")
                if ex isa Example
                    if !isnothing(ex.caption) && !isempty(ex.caption)
                        println(io, "**$(ex.caption)**\n")
                    end
                    println(io, "```julia")
                    println(io, ex.code)
                    println(io, "```")
                    if i < length(examples)
                        println(io)
                    end
                end
            end
        end
    end

    if idx > 0 # there is further nesting
        println(io, "\n Nested Attribute `$merged_key` contains:")
        write_nested_attributes_docs!(io, meta, idx)
        for k in keys(meta.nesting.keytables[idx])
            write_nested_attributes_docs!(io, meta, idx, 0)
        end

        sym = plotsym(T)
        println(io, "See `help($sym, :$attr, :inner[, ...])` for detailed documentation on nested attributes.")
    end

    return Markdown.parse(String(take!(io)))
end

function write_nested_attributes_docs!(io, attr, layer, tab = 0)
    for (key, idx) in attr.nesting.keytables[layer]
        if idx > 0 # more nesting
            print(io, "  "^tab, "- `.$key")
            docstring = attr.nested_docstring[-idx]
            write_nested_attributes_docs!(io, attr, idx, tab+1)
        else # leaf attribute
            print(io, "  "^tab, "- `.$key = $(attr.default_expr[-idx])`")
            docstring = attr.leaf_docstring[-idx]
        end
        if !isnothing(docstring)
            print(io, ": ", docstring)
        end
        println(io)
    end
    return
end

# overrides `?Axis.xticks`, `?Scatter.color` and similar lookups in the REPL
# This does not work for paramtric types pre 1.12.2 (i.e. not for Plots)
function REPL.fielddoc(::Type{T}, attr::Symbol) where {T <: Union{Plot, Block}}
    if !is_attribute(T, attr)
        return Markdown.parse("`$attr` is not an attribute of type `$T`. Type `?$T` in the REPL to see the list of available attributes.")
    end
    return field_docs(T, attr)
end

# autocomplete for `Scatter.attr...`
function Base.propertynames(::Type{T}) where {T <: AbstractPlot}
    return collect(root_keys(meta_attributes(T)))
end
