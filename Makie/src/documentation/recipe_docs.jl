"""
Core documentation system for Makie plot recipes.

This module provides the infrastructure for automatically generating comprehensive
documentation for plot types, including:
- Standardized function signatures
- User-provided documentation
- Argument documentation based on conversion traits
- Attribute documentation with defaults
- Examples for plots and attributes

See the Makie module docstring for usage examples.
"""

################################################################################
### Attribute Documentation
################################################################################

"""
    attribute_docs(::Type{<:Plot})

Returns all attribute documentation for a plot type as a `DocumentedAttributes` object.
Falls back to `documented_attributes(PlotType)`.
"""
attribute_docs(::Type{T}) where {T<:Plot} = documented_attributes(T)

"""
    attribute_docs(::Type{<:Plot}, attr::Symbol)

Returns the documentation for a specific attribute of a plot type.
Returns `nothing` if the attribute is not documented.
"""
function attribute_docs(::Type{T}, attr::Symbol) where {T<:Plot}
    attrs = documented_attributes(T)
    isnothing(attrs) && return nothing
    return get(attrs.d, attr, nothing)
end

################################################################################
### Attribute Examples
################################################################################

################################################################################
### Plot Examples
################################################################################

"""
    plot_examples(::Type{<:Plot}, max_examples::Int=1)

Returns example documentation by reading the markdown file from `documentation/plots/{plotname}.md`.
Parses the markdown structure and returns up to `max_examples` examples.

The markdown files follow this structure:
```
# plotname

## Examples

### Example Title 1
...
```@figure
code
```

### Example Title 2
...
```

Returns an empty string if the markdown file doesn't exist or has no examples.

# Arguments
- `max_examples`: Maximum number of examples to include (default: 1). Use `0` or negative number for all examples.
"""
function plot_examples(::Type{PT}, max_examples::Int=1) where {PT<:Plot}
    plfunc = plotfunc(PT)
    plfunc_str = string(plfunc)

    # Path to markdown file
    md_path = joinpath(@__DIR__, "plots", "$plfunc_str.md")

    if !isfile(md_path)
        return ""
    end

    # Read the markdown file
    content = read(md_path, String)

    # If max_examples <= 0, return everything after ## Examples
    if max_examples <= 0
        examples_pattern = r"^## Examples\s*$(.*?)(?=^## |\z)"ms
        m = match(examples_pattern, content)
        if isnothing(m)
            return ""
        end
        return "## Examples\n" * m.captures[1]
    end

    # Parse the markdown to extract examples
    # Find the Examples section
    examples_pattern = r"^## Examples\s*$(.*?)(?=^## |\z)"ms
    m = match(examples_pattern, content)

    if isnothing(m)
        return ""
    end

    examples_content = m.captures[1]

    # Split by ### headers to get individual examples
    # Match ### titles and their content until the next ### or end
    example_pattern = r"^### (.+?$)(.*?)(?=^### |\z)"ms
    examples = eachmatch(example_pattern, examples_content)

    # Collect up to max_examples
    collected = String[]
    count = 0
    for ex in examples
        if count >= max_examples
            break
        end
        title = strip(ex.captures[1])
        body = ex.captures[2]
        push!(collected, "### $title\n$body")
        count += 1
    end

    if isempty(collected)
        return ""
    end

    return "## Examples\n\n" * join(collected, "\n")
end

################################################################################
### Argument Documentation (Type-based)
################################################################################

"""
    argument_docs_items(::Type{<:Plot})

Returns an array of argument documentation strings for a plot type based on its conversion trait.
Dispatches on the conversion trait type directly.
"""
function argument_docs_items(::Type{PT}) where {PT<:Plot}
    CT = conversion_trait(PT)
    return argument_docs_items(CT)
end

# Trait-based argument documentation (returns arrays)
function argument_docs_items(::PointBased)
    return [
        "`positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` corresponding to `(x, y)` or `(x, y, z)` positions.",
        "`xs, ys[, zs]`: Positions given per dimension. Can be `Real` to define a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to define multiple. Using `ClosedInterval` requires at least one dimension to be given as an array. `zs` can also be given as a `AbstractMatrix` which will cause `xs` and `ys` to be interpreted per matrix axis.",
        "`ys`: Defaults `xs` positions to `eachindex(ys)`.",
    ]
end

function argument_docs_items(::PointBased2D)
    return [
        "`positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` corresponding to `(x, y)` positions.",
        "`xs, ys`: Positions given per dimension. Can be `Real` to define a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to define multiple. Using `ClosedInterval` requires at least one dimension to be given as an array. If omitted, `xs` defaults to `eachindex(ys)`.",
    ]
end

function argument_docs_items(::VertexGrid)
    return [
        "`zs`: Defines z values for vertices of a grid using an `AbstractMatrix{<:Real}`.",
        "`xs, ys`: Defines the (x, y) positions of grid vertices. A `ClosedInterval{<:Real}` or `Tuple{<:Real, <:Real}` is interpreted as the outer limits of the grid, between which vertices are spaced regularly. An `AbstractVector{<:Real}` defines vertex positions directly for the respective dimension. An `AbstractMatrix{<:Real}` allows grid positions to be defined per vertex, i.e. in a non-repeating fashion. If `xs` and `ys` are omitted they default to `axes(data, dim)`.",
    ]
end

function argument_docs_items(::CellGrid)
    return [
        "`data`: Defines data values for cells of a grid using an `AbstractMatrix{<:Real}`.",
        "`xs, ys`: Defines the positions of grid cells. A `ClosedInterval{<:Real}` or `Tuple{<:Real, <:Real}` is interpreted as the outer edges of the grid, between which cells are spaced regularly. An `AbstractVector{<:Real}` defines cell positions directly for the respective dimension. This define either `size(data, dim)` cell centers or `size(data, dim) + 1` cell edges. These are allowed to be spaced irregularly. If `xs` and `ys` are omitted they default to `axes(data, dim)`.",
    ]
end

function argument_docs_items(::ImageLike)
    return [
        "`image`: An `AbstractMatrix{<:Colorant}` defining the colors of an image, or an `AbstractMatrix{<:Real}` defining colors through colormapping.",
        "`x, y`: Defines the boundary of the image rectangle. Can be a `Tuple{<:Real, <:Real}` or `ClosedInterval{<:Real}`. Defaults to `0 .. size(image, 1)` and `0 .. size(image, 2)` respectively.",
    ]
end

function argument_docs_items(::VolumeLike)
    return [
        "`volume_data`: An `AbstractArray{<:Real, 3}` defining volume data.",
        "`x, y, z`: Defines the boundary of a 3D rectangle with a `Tuple{<:Real, <:Real}` or `ClosedInterval{<:Real}`. If omitted `x`, `y` and `z` default to `0 .. size(volume)`.",
    ]
end

# Generic fallback for NoConversion plots
function argument_docs_items(::NoConversion)
    return String[]  # Return empty array so no generic message shows
end

"""
    format_argument_signature(::Type{PT}) where {PT<:Plot}

Returns a formatted string showing the argument signature with types for a plot type.
For example: "positions::AbstractVector{<:Union{Point2, Point3}}"
Returns nothing if type information is not available.
"""
function format_argument_signature(::Type{PT}) where {PT<:Plot}
    # Get argument names
    arg_names = argument_names(PT, 10)
    isempty(arg_names) && return nothing

    # Get target types - try plot-specific first, then trait-based
    arg_types = types_for_plot_arguments(PT)
    if isnothing(arg_types)
        CT = conversion_trait(PT)
        arg_types = types_for_plot_arguments(CT)
    end
    isnothing(arg_types) && return nothing

    # arg_types is a Tuple type, extract the parameter types
    type_params = arg_types.parameters

    # Match names with types
    if length(arg_names) != length(type_params)
        # Mismatch - just return nothing for now
        return nothing
    end

    # Format as "name::Type"
    parts = String[]
    for (name, typ) in zip(arg_names, type_params)
        # Simplify type representation
        type_str = string(typ)
        # Skip overly complex type signatures (more than 200 characters per argument)
        if length(type_str) > 200
            return nothing
        end
        # Clean up Union{A, B} to be more readable
        type_str = replace(type_str, r"Union\{([^}]+)\}" => s"Union{\1}")
        push!(parts, "$name::$type_str")
    end

    return join(parts, ", ")
end

"""
    argument_docs(::Type{<:Plot})

Returns formatted argument documentation as Markdown for a plot type based on its conversion trait.
"""
function argument_docs(::Type{PT}) where {PT<:Plot}
    items = argument_docs_items(PT)
    if isempty(items)
        return Markdown.MD()
    end

    PlotType_str = uppercasefirst(string(plotfunc(PT)))
    arg_items = join(["  * " * item for item in items], "\n")

    # Try to get formatted signature
    sig = format_argument_signature(PT)
    sig_section = if !isnothing(sig)
        "**Target signature:** `$sig`\n\n"
    else
        ""
    end

    return Markdown.parse("""
    ## Arguments

    $(sig_section)$arg_items

    For detailed conversion information, see `Makie.conversion_docs($PlotType_str)`.
    """)
end

################################################################################
### Main Documentation Function
################################################################################

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
function document_recipe(::Type{PT}, user_docstring::Markdown.MD; max_examples::Int=1, full_attributes::Bool=false) where {PT<:Plot}
    plfunc = plotfunc(PT)
    plfunc_str = string(plfunc)
    plfunc!_str = plfunc_str * "!"
    # Get plot type name by capitalizing the function name (lines -> Lines)
    PlotType_str = uppercasefirst(plfunc_str)

    # Build function signatures section
    signatures = Markdown.parse("""
        # return a new figure, axis, and plot
        f, ax, pl = $plfunc_str(args...; kw...)
        # creates an axis in a subfigure grid position
           ax, pl = $plfunc_str(f[row, col], args...; kw...)
        # Creates a plot in the given axis or scene.
               pl = $plfunc!_str(ax::Union{Scene, AbstractAxis}, args...; kw...)
        # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
        SpecApi.$(PlotType_str)(args...; kw...)
    """)

    # Build arguments section (argument_docs now returns Markdown directly)
    arguments_section = argument_docs(PT)

    # Build attributes section
    attrs = documented_attributes(PT)
    attr_names = attribute_names(PT)

    attributes_section = if full_attributes
        # Show detailed attribute documentation
        if isnothing(attr_names) || isempty(attr_names)
            Markdown.parse("## Attributes\n\nNo attributes available.")
        else
            io = IOBuffer()
            println(io, "## Attributes\n")

            for attr in attr_names
                attr_meta = get(attrs.d, attr, nothing)
                if !isnothing(attr_meta)
                    println(io, "### `$attr`\n")
                    println(io, "**Default:** `$(attr_meta.default_expr)`\n")
                    if !isnothing(attr_meta.docstring)
                        println(io, attr_meta.docstring)
                        println(io)
                    end

                    # Add example if available
                    examples_dict = try
                        attribute_examples(PT)
                    catch
                        nothing
                    end

                    if examples_dict isa Dict && haskey(examples_dict, attr)
                        examples = examples_dict[attr]
                        if examples isa Vector && !isempty(examples)
                            println(io, "**Example:**\n")
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
                            println(io)
                        end
                    end
                else
                    println(io, "### `$attr`\n")
                    println(io, "*No documentation available.*\n")
                end
            end

            Markdown.parse(String(take!(io)))
        end
    else
        # Show summary attribute list
        attr_list = if isnothing(attr_names) || isempty(attr_names)
            "No attributes available."
        else
            join(["`$attr`" for attr in attr_names], ", ")
        end
        Markdown.parse("""
        ## Attributes

        **Available attributes:** $attr_list

        Use `?$PlotType_str.attribute` to see the documentation for a specific attribute, e.g., `?$PlotType_str.color`.
        """)
    end

    # Build examples section
    examples = plot_examples(PT, max_examples)
    # Add link to online documentation
    if !isempty(examples)
        online_docs_link = "\n\nSee the [online documentation](https://docs.makie.org/stable/reference/plots/$plfunc_str) for more examples."
        examples = examples * online_docs_link
    end
    examples_section = Markdown.parse(examples)

    # Combine all sections into a single Markdown document
    combined = Markdown.MD()
    push!(combined.content, signatures.content...)
    push!(combined.content, user_docstring.content...)
    push!(combined.content, arguments_section.content...)
    push!(combined.content, attributes_section.content...)
    push!(combined.content, examples_section.content...)
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
function full_docs(::Type{PT}; replace_figure=true) where {PT<:Plot}
    # Get the user docstring for this plot type
    user_docstring = try
        # Try to get the docstring from Docs
        binding = Docs.Binding(Makie, Symbol(uppercasefirst(string(plotfunc(PT)))))
        docs = Docs.meta(Makie)[binding]
        if haskey(docs.docs, Union{})
            docs.docs[Union{}].text[1]
        else
            Markdown.MD()
        end
    catch
        Markdown.MD()
    end

    # Call document_recipe with full documentation settings
    docs = document_recipe(PT, user_docstring; max_examples=0, full_attributes=true)

    # Replace @figure with julia if requested for REPL display
    if replace_figure
        docs_str = sprint(io -> Markdown.plain(io, docs))
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
function generate_plot_docs(output_dir::String; plot_types=nothing)
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
        docs = full_docs(PT; replace_figure=false, use_figure_for_attributes=true)

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


function field_docs(::Type{T}, attr::Symbol) where {T<:Plot}
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

"""
    REPL.fielddoc(::Type{T}, attr::Symbol) where {T<:Plot}

Provides attribute documentation in the REPL when using `?PlotType.attribute`.
Shows both the attribute documentation and examples if available.
"""
function REPL.fielddoc(::Type{T}, attr::Symbol) where {T<:Plot}
    return field_docs(T, attr)
end
