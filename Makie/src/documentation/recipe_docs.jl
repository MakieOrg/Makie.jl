################################################################################
### Attribute Documentation
################################################################################

"""
    attribute_docs(::Type{<:Plot})

Returns all attribute documentation for a plot type as a `DocumentedAttributes` object.
Falls back to `documented_attributes(PlotType)`.
"""
attribute_docs(::Type{T}) where {T <: Plot} = documented_attributes(T)

"""
    attribute_docs(::Type{<:Plot}, attr::Symbol)

Returns the documentation for a specific attribute of a plot type.
Returns `nothing` if the attribute is not documented.
"""
function attribute_docs(::Type{T}, attr::Symbol) where {T <: Plot}
    attrs = documented_attributes(T)
    isnothing(attrs) && return nothing
    return get(attrs.d, attr, nothing)
end

################################################################################
### Attribute Examples
################################################################################

"""
    extract_attributes(markdown_file_path::String)

Parse a markdown file and extract all attribute examples that come after the "## Attributes" header.
Each attribute starts with a "### `attribute_name`" header and includes all code blocks until the next header.
Returns a dictionary mapping attribute names (as Symbols) to vectors of `Example` objects.
"""
function extract_attributes(markdown_file_path::String)
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
function plot_examples(::Type{PT}, max_examples::Number = 1) where {PT <: Plot}
    plfunc = plotfunc(PT)
    plfunc_str = string(plfunc)
    # Path to markdown file
    md_path = joinpath(@__DIR__, "plots", "$plfunc_str.md")

    if !isfile(md_path)
        return ""
    end

    examples = extract_examples(md_path)
    n_examples = examples[1:round(Int, min(length(examples), max_examples))]

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


function Base.show(io::IO, attr_meta::AttributeMetadata)
    println(io, "**Default:** `$(attr_meta.default_expr)`\n")
    return if !isnothing(attr_meta.docstring)
        println(io, attr_meta.docstring)
    end
end

################################################################################
### Main Documentation Function
################################################################################

# Consider making a dedicated group for DataInspector?
const DEFAULT_ATTRIBUTE_GROUPS = let
    generic = collect(keys(Makie.mixin_generic_plot_attributes().d))
    push!(generic, :cycle)
    inspector = [:inspectable, :inspector_label, :inspector_clear, :inspector_hover]
    filter!(name -> !in(name, inspector), generic)
    colormapping = collect(keys(Makie.mixin_colormap_attributes().d))
    shading = collect(keys(Makie.mixin_shading_attributes().d))

    Pair{String, Vector{Symbol}}[
        "Generic Attributes" => sort!(generic),
        "DataInspector Attributes" => inspector,
        "3D Shading Attributes" => sort!(shading),
        "Colormapping Attributes" => sort!(colormapping)
    ]
end

"""
    default_attribute_groups()

Returns a deepcopy of the default attribute groups for further modification.
"""
default_attribute_groups() = deepcopy(DEFAULT_ATTRIBUTE_GROUPS)

"""
    attribute_groups(::Type{<:Plot})

Returns a list identifying grouped attributes for docstrings. Each element is a
`Pair` containing the name of the group and a list of the associated attributes.

This function is meant to be extended to refine attribute groups for recipes.
`default_attribute_groups()` can be used to get the default groups.

```
function Makie.attribute_names(::Type{<:MyPlot})
    groups = Makie.default_attribute_groups()
    push!(groups, "My Attributes" => [:myattrib1, :myattrib2])
end
```

If the listed attributes exist in `MyPlot` they will be printed as
"**My Attributes**: `myattrib1`, `myattrib2`". Attributes that don't exist will
be skipped. If every attribute does not exist, the group will not be printed.
"""
attribute_groups(::Type{<:AbstractPlot}) = Makie.DEFAULT_ATTRIBUTE_GROUPS

function get_attribute_docs(::Type{PT}; full = false) where {PT <: Plot}
    # Build attributes section
    attrs = documented_attributes(PT)
    attr_names = attribute_names(PT)
    # Show detailed attribute documentation
    if isnothing(attr_names) || isempty(attr_names)
        return Markdown.parse("## Attributes\n\nNo attributes available.")
    else
        io = IOBuffer()
        println(io, "## Attributes\n")
        sorted_names = sort!(collect(attr_names))
        if full
            write_full_attribute_docs!(io, PT, attrs, sorted_names)
        else
            write_attribute_groups!(io, PT, sorted_names)
            typename = string(plotsym(PT))
            info = if VERSION < v"1.12.2"
                "help($typename, :attribute)"
            else
                "?$typename.attribute"
            end
            println(io, "For more information and examples on specific attributes check `$info`.")
        end
        return Markdown.parse(String(take!(io)))
    end

end

function write_full_attribute_docs!(io, PT, attrs, sorted_names)
    for attr in sorted_names
        examples = attribute_examples(PT, attr)
        write_full_single_attribute_docs!(io, attrs, examples, attr)
    end
    return
end

function write_full_single_attribute_docs!(io, attrs, examples, attribute)
    attr_meta = get(attrs.d, attribute, nothing)
    println(io, "### `$attribute`\n")
    if !isnothing(attr_meta)
        println(io, attr_meta)
        # Add example if available
        if !isempty(examples)
            println(io, "**Example:**\n")
            for (i, ex) in enumerate(examples)
                show(io, ex)
                if i < length(examples)
                    println(io)
                end
            end
            println(io)
        end
    else
        println(io, "*No documentation available.*\n")
    end
    return
end

function write_attribute_groups!(io, PT, sorted_names)
    # Print groups first (assume attributes of each group are sorted)
    for (groupname, attribute_names) in attribute_groups(PT)
        if any(name -> name in sorted_names, attribute_names)
            print(io, "**", groupname, "**: ")
            has_prev = false
            for name in attribute_names
                idx = findfirst(==(name), sorted_names)
                if !isnothing(idx)
                    has_prev && print(io, ", ")
                    print(io, '`', name, '`')
                    has_prev = true
                    deleteat!(sorted_names, idx)
                end
            end
            println(io, "\n")
        end
    end

    # Print the rest as plot specific attributes
    if !isempty(sorted_names)
        str = mapreduce(name -> "`$name`", (a, b) -> "$a, $b", sorted_names)
        println(io, "**Plot Attributes**: ", str, "\n")
    end
    return
end

function get_attribute_docs(io::IO, ::Type{PT}, attribute; full = false) where {PT <: Plot}
    attrs = documented_attributes(PT)
    if full
        examples = attribute_examples(PT, attribute)
        write_full_single_attribute_docs!(io, attrs, examples, attribute)
    else
        write_short_attribute_docs!(io, attrs, attribute)
    end
    return
end

function write_short_attribute_docs!(io::IO, attrs, attribute)
    attr_meta = get(attrs.d, attribute, nothing)
    println(io, "- **`$attribute`**", isnothing(attr_meta) ? "" : " = `$(attr_meta.default_expr)`")
    return nothing
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
    plfunc = plotfunc(PT)
    plfunc_str = string(plfunc)
    plfunc!_str = plfunc_str * "!"
    # Get plot type name by capitalizing the function name (lines -> Lines)
    PlotType_str = uppercasefirst(plfunc_str)

    # Build function signatures section
    signatures = Markdown.parse(
        """
        ```julia
        # return a new figure, axis, and plot
        f, ax, pl = $plfunc_str(args...; kw...)
        # creates an axis in a subfigure grid position
            ax, pl = $plfunc_str(f[row, col], args...; kw...)
        # Creates a plot in the given axis or scene.
                pl = $plfunc!_str(ax::Union{Scene, AbstractAxis}, args...; kw...)
        # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
        SpecApi.$(PlotType_str)(args...; kw...)
        ```
        """
    )

    # Build arguments section (argument_docs now returns Markdown directly)
    arguments_section = argument_docs_md(PT)

    attributes_section = get_attribute_docs(PT; full = full_attributes)

    # Build examples section
    examples = plot_examples(PT, max_examples)
    # Add link to online documentation
    if max_examples == 1
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
        md_files = filter(f -> endswith(f, ".md") && f != "overview.md", readdir(plots_dir))
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


function field_docs(::Type{T}, attr::Symbol) where {T <: Plot}
    attr_meta = attribute_docs(T, attr)

    if isnothing(attr_meta)
        return Markdown.parse("No documentation available for attribute `$attr` of plot type `$T`.")
    end

    # Build documentation string
    io = IOBuffer()

    # Attribute name and default
    println(io, "**`$attr`** = `$(attr_meta.default_expr)`")
    println(io)

    # Docstring
    if !isnothing(attr_meta.docstring)
        println(io, attr_meta.docstring)
        println(io)
    end

    # Example
    examples_dict = try
        attribute_examples(T)
    catch
        nothing
    end

    if examples_dict isa Dict && haskey(examples_dict, attr)
        examples = examples_dict[attr]
        if examples isa Vector && !isempty(examples)
            println(io, "### Example\n")
            for (i, ex) in enumerate(examples)
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

    return Markdown.parse(String(take!(io)))
end

# This does not work for paramtric types pre 1.12.2 (i.e. not for Plots)
function REPL.fielddoc(::Type{T}, attr::Symbol) where {T <: Plot}
    return field_docs(T, attr)
end
