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

"""
    attribute_examples(::Type{<:Plot}, ::Val{attribute})

Returns an example string demonstrating the use of a specific attribute.
Override this method for specific plot types and attributes:

```julia
attribute_examples(::Type{<:Scatter}, ::Val{:color}) = "scatter(1:10, color=:red)"
```

Returns an empty string by default.
"""
attribute_examples(::Type{<:Plot}, ::Val) = ""

"""
    attribute_examples(::Type{<:Plot})

Returns a dictionary mapping attribute names to example strings for all attributes.
"""
function attribute_examples(::Type{T}) where {T<:Plot}
    attrs = attribute_names(T)
    isnothing(attrs) && return Dict{Symbol, String}()

    return Dict{Symbol, String}(
        attr => attribute_examples(T, Val(attr))
        for attr in attrs
    )
end

################################################################################
### Plot Examples
################################################################################

"""
    plot_examples(::Type{<:Plot})

Returns example code demonstrating the use of a plot type.
Override this method for specific plot types:

```julia
plot_examples(::Type{<:Scatter}) = \"\"\"
## Examples
```julia
scatter(1:10, rand(10))
scatter(rand(100), rand(100), color=rand(100))
```
\"\"\"
```

Returns an empty string by default.
"""
plot_examples(::Type{<:Plot}) = ""

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

function argument_docs_items(::NoConversion)
    return [
        "`args...`: Plot-specific arguments. Refer to the plot type's documentation for details."
    ]
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
    arg_items = join(["- " * item for item in items], "\n")

    return Markdown.parse("""
    ## Arguments

    $arg_items

    For more detailed conversion information, see `Makie.conversion_docs($PlotType_str)`.
    """)
end

################################################################################
### Main Documentation Function
################################################################################

"""
    document_recipe(::Type{PT}, user_docstring) where {PT<:Plot}

Generates comprehensive documentation for a plot type by combining:
- Standardized function signatures
- User-provided documentation
- Argument documentation (from conversion traits)
- Attribute documentation
- Examples

This function is called automatically by the `@recipe` macro via `Docs.getdoc`.
"""
function document_recipe(::Type{PT}, user_docstring::Markdown.MD) where {PT<:Plot}
    plfunc = plotfunc(PT)
    plfunc_str = string(plfunc)
    plfunc!_str = plfunc_str * "!"
    # Get plot type name by capitalizing the function name (lines -> Lines)
    PlotType_str = uppercasefirst(plfunc_str)

    # Build function signatures section
    signatures = Markdown.parse("""
        f, ax, pl = $plfunc_str(args...; kw...) # return a new figure, axis, and plot
           ax, pl = $plfunc_str(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
               pl = $plfunc!_str(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
        SpecApi.$(PlotType_str)(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
    """)

    # Build arguments section (argument_docs now returns Markdown directly)
    arguments_section = argument_docs(PT)

    # Build attributes section
    attrs = documented_attributes(PT)
    attr_names = attribute_names(PT)
    attr_list = if isnothing(attr_names) || isempty(attr_names)
        "No attributes available."
    else
        join(["`$attr`" for attr in attr_names], ", ")
    end
    attr_section = Markdown.parse("""
    ## Attributes

    **Available attributes:** $attr_list

    Use `?$PlotType_str.attribute` to see the documentation for a specific attribute, e.g., `?$PlotType_str.color`.
    """)

    # Build examples section
    examples = plot_examples(PT)
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
    push!(combined.content, attr_section.content...)
    push!(combined.content, examples_section.content...)
    return combined
end

################################################################################
### Full Documentation Function
################################################################################

"""
    full_docs(::Type{<:Plot})

Generates comprehensive documentation for a plot type including:
- Function signatures
- User-provided documentation
- Short argument documentation with hint for full docs
- **ALL** examples from the documentation
- **Detailed** attribute documentation for each attribute

Use this for comprehensive reference. For a quick overview, use `?PlotType` instead.

# Example
```julia
full_docs(Scatter)
full_docs(Lines)
```
"""
function full_docs(::Type{PT}) where {PT<:Plot}
    plfunc = plotfunc(PT)
    plfunc_str = string(plfunc)
    plfunc!_str = plfunc_str * "!"
    PlotType_str = uppercasefirst(plfunc_str)

    # Build function signatures section
    signatures = Markdown.parse("""
        f, ax, pl = $plfunc_str(args...; kw...) # return a new figure, axis, and plot
           ax, pl = $plfunc_str(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
               pl = $plfunc!_str(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
        SpecApi.$(PlotType_str)(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
    """)

    # Build short arguments section with hint for full docs
    items = argument_docs_items(PT)
    arguments_section = if isempty(items)
        Markdown.MD()
    else
        arg_items = join(["- " * item for item in items], "\n")
        Markdown.parse("""
        ## Arguments

        $arg_items

        For detailed conversion information, see `Makie.conversion_docs($PlotType_str)`.
        """)
    end

    # Build ALL examples section
    examples_section = all_examples_docs(PT)

    # Build detailed attributes section
    attrs = documented_attributes(PT)
    attr_names = attribute_names(PT)

    attributes_section = if isnothing(attr_names) || isempty(attr_names)
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
                example = attribute_examples(PT, Val(attr))
                if !isempty(example)
                    println(io, "**Example:**")
                    println(io, "```julia")
                    println(io, example)
                    println(io, "```\n")
                end
            else
                println(io, "### `$attr`\n")
                println(io, "*No documentation available.*\n")
            end
        end

        Markdown.parse(String(take!(io)))
    end

    # Combine all sections
    combined = Markdown.MD()
    push!(combined.content, signatures.content...)
    push!(combined.content, arguments_section.content...)
    push!(combined.content, examples_section.content...)
    push!(combined.content, attributes_section.content...)
    return combined
end

"""
    all_examples_docs(::Type{<:Plot})

Returns Markdown documentation for ALL examples of a plot type.
"""
function all_examples_docs(::Type{PT}) where {PT<:Plot}
    plfunc = plotfunc(PT)
    plfunc_str = string(plfunc)

    # Filter examples for this plot function
    examples = filter(ALL_EXAMPLES) do ex
        plfunc in ex.plotfuncs
    end

    if isempty(examples)
        return Markdown.MD()
    end

    io = IOBuffer()
    println(io, "## Examples\n")

    for (i, ex) in enumerate(examples)
        # Add title if it's meaningful
        if !isempty(ex.title) && ex.title != "Example"
            println(io, "### $(ex.title)\n")
        end

        # Add description
        if !isempty(ex.description)
            println(io, ex.description)
            println(io)
        end

        # Add code
        println(io, "```julia")
        println(io, ex.body_src)
        println(io, "```\n")
    end

    # Add link to online documentation
    println(io, "See the [online documentation](https://docs.makie.org/stable/reference/plots/$plfunc_str) for rendered examples.")

    return Markdown.parse(String(take!(io)))
end

################################################################################
### REPL.fielddoc overload
################################################################################

"""
    REPL.fielddoc(::Type{T}, attr::Symbol) where {T<:Plot}

Provides attribute documentation in the REPL when using `?PlotType.attribute`.
Shows both the attribute documentation and examples if available.
"""
function REPL.fielddoc(::Type{T}, attr::Symbol) where {T<:Plot}
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
    example = attribute_examples(T, Val(attr))
    if !isempty(example)
        println(io, "### Example")
        println(io)
        println(io, "```julia")
        println(io, example)
        println(io, "```")
    end

    return Markdown.parse(String(take!(io)))
end
